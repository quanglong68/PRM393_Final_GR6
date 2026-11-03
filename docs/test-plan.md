<<<<<<< Updated upstream
# Test Plan — PRM393 Lab 3 (ARTEMIS + runtime verification)

> **Living document** theo guide v5 §6.2 — cập nhật mỗi khi có feature mới hoặc
> kết quả verify mới. Nguồn case: 3 flow trong `ux/user-flow.md` (§2.1 happy path,
> §2.2 error branch, §2.3 recovery) + yêu cầu Firebase/FCM/PDF guide §1–§5.
> Evidence naming: `TC-` (test case), `FLW-` (flow screenshots), `SCR-` (screen).
>
> **Trạng thái hiện tại:** unit/widget test Flutter = 51/51 pass (`flutter test`).
> ARTEMIS (on-device, Python) **chưa chạy** — cần E1 setup (user).
> Runtime verification bị M10 downgrade → nhóm **TC-V** bên dưới.

## 0. Phân lớp kiểm thử

| Lớp | Công cụ | Trạng thái |
|---|---|---|
| Unit/ViewModel/Widget | `flutter test` (hermetic mocks) | ✅ 51/51 pass — 02/11 |
| Runtime CRUD trên emulator | app debug + Firebase Console + `adb logcat` | ⏳ cần device (TC-V1..V5) |
| E2E ARTEMIS | Python ≥3.12 + `uv` + adb + API key `.env` | ❌ chưa setup (E1) |
| Exploratory 15′ + AI summary | ARTEMIS exploratory mode | ❌ chờ E3 xong |

## 1. Ma trận TC ↔ Flow (guide §6.2)

### Flow 1 — Tra cứu Slot & Đầu điểm (G1, M1: ≤8s, ≤3 chạm)

| ID | Loại | Bước rút gọn | Kết vọng | Unit đã phủ | On-device |
|---|---|---|---|---|---|
| TC-F1-01 | happy | Home → tab Lộ trình → chạm môn PRM323 → tab Lịch slot | ≤3 chạm, slot list từ Firestore `courses` | `roadmap_viewmodel_test.dart` | FLW-01 |
| TC-F1-02 | happy | Ô tìm kiếm nhập `PRM` | list lọc còn môn khớp | `roadmap_viewmodel_test.dart` | TC-F1-02 |
| TC-F1-03 | error | Catalog `courses`/`curriculums` chưa seed / Firestore lỗi | màn hình báo lỗi thật, **không** fallback mock (fail-loud) | — | TC-V4 |
| TC-F1-04 | branch | Chi tiết môn → "Hỏi trợ lý AI về môn này" | vào Advisor kèm mã môn | `advisor_viewmodel_test.dart` | TC-F1-04 |

### Flow 2 — Quản lý Deadline & Undo (G2, M3: undo 8s + phục hồi sync)

| ID | Loại | Bước rút gọn | Kết vọng | Unit đã phủ | On-device |
|---|---|---|---|---|---|
| TC-F2-01 | happy | Tab Việc cần làm → chạm checkbox | gạch ngang, Snackbar HOÀN TÁC 8s, Firestore doc update | `tasks_notes_test.dart` (toggle) | FLW-02, TC-V1 |
| TC-F2-02 | recovery | Chạm nhầm → HOÀN TÁC trong 8s | task về vị trí + trạng thái cũ | `tasks_notes_test.dart` | TC-F2-02 |
| TC-F2-03 | happy | Chạm nội dung task → sửa title/course/due → Lưu | `updateTask` thành công trên doc **legacy lẫn new format** | `tasks_notes_test.dart` (editTask revert) | TC-V1 (M11E close-out) |
| TC-F2-04 | error | Tắt mạng → sửa task | local revert + `lastError` tiếng Việt, không mất dữ liệu | `tasks_notes_test.dart` | TC-V2 |
| TC-F2-05 | happy | Tạo task mới (addTask) → verify doc ID = `task_<ts>` cả path lẫn field `id` | không còn `not-found` khi update | `tasks_notes_test.dart` (add) | TC-V1 |

### Flow 3 — Quick Capture Ghi chú & Vault Sync (G4, M2 ≤15s, M3)

| ID | Loại | Bước rút gọn | Kết vọng | Unit đã phủ | On-device |
|---|---|---|---|---|---|
| TC-F3-01 | happy | Tab Ghi chú → tạo note → "Lưu vào Vault" | note lên `notes/{uid}/…`, ≤15s | `tasks_notes_test.dart`, `widget_test.dart` (save snackbar fail/pass) | FLW-03, TC-V3 |
| TC-F3-02 | error | Lưu note khi tắt mạng | error snackbar, không claim đã lưu | `widget_test.dart` | TC-V2 |
| TC-F3-03 | happy | Upload attachment PDF/ảnh | path `notes/{uid}/{allPaths=**}` pass rules recursive | — | TC-V3 |

### Cross-cutting Firebase (guide §1–§5)

| ID | Loại | Bước | Kết vọng | Unit đã phủ | On-device |
|---|---|---|---|---|---|
| TC-X-01 | auth | Google Sign-In APK release | vào Home, `setUserId` + `logLoginSuccess` fire | `analytics_wiring_test.dart` | TC-V5 |
| TC-X-02 | isolation | Account B đọc path user A | permission-denied | rules audit (M7) | **BLOCKED** — cần account 2 (M10) |
| TC-X-03 | analytics | Chạy 7+ events, DebugView thấy ≥2 params/event | events gọi 1 lần/action | `analytics_wiring_test.dart` | DebugView evidence |
| TC-X-04 | remote config | `maintenance_mode`/`min_app_version` from defaults json | enforce đúng, Console before/after | — | evidence RC |
| TC-X-05 | crashlytics | Gây test crash debug build | crash xuất hiện Crashlytics | — | evidence |
| TC-X-06 | fcm | Push foreground/background/terminated + tap | Notification Center nhận, tap route đúng màn | `notifications_test.dart` | FCM 3 trạng thái |
| TC-X-07 | pdf | Consent dialog → export → upload `reports/{uid}/` | progress visible, doc metadata, event `export_report` | `report_export_service_test.dart` | evidence PDF |

### TC-V — Nhóm đóng nợ verify của audit T03-M10 (ưu tiên cao nhất)

| ID | Trả nợ claim nào của M10 | Cách làm | Done khi |
|---|---|---|---|
| TC-V1 | Task UPDATE PASS (M8→M11E) | Device có `adb logcat`: tạo task → sửa → verify doc trên Console + log sạch không exception | 3/3 run pass, console screenshot `TC-V1-*` |
| TC-V2 | Network toggle / offline persistence (NOT TESTED) | `adb shell svc wifi disable/enable` quanh CRUD | cycle offline→online sync lại đúng |
| TC-V3 | Note CRUD trên emulator (NOT TESTED) | thêm/xóa/sửa note + attachment | docs Console khớp |
| TC-V4 | Seed catalog (A3 tồn đọng) | seed `courses`/`curriculums` rồi Roadmap đọc | danh sách môn thật hiển thị |
| TC-V5 | Flutter debug log evidence (NOT TESTED) | capture `adb logcat -s flutter` cả phiên | file log lưu `evidence/firebase/` |
| TC-V6 | Cross-account UID isolation (BLOCKED) | **cần user chuẩn bị Google account thứ 2** | sign-in B, thử đọc path A → denied |

## 2. Quy trình chạy (E3, guide §6.3)

1. Mỗi TC chạy **3 lần** trên cùng device; bảng `pass rate · avg duration` ghi bên dưới §3.
2. TC flaky (<3/3): điều tra root cause, fix hoặc gắn nhãn known-issue — không bỏ qua.
3. Evidence: `evidence/artemis/TC-<id>_<run>.png`, `evidence/firebase/TC-V*_*`, screenshot 3 flows `evidence/artemis/FLW-0{1,2,3}.png`.
4. Exploratory 15′ sau khi TC-V khép → AI summary vào `evidence/artemis/exploratory-summary.md`.

## 3. Kết quả (cập nhật sau mỗi batch)

| Batch | Ngày | TC | Run 1 | Run 2 | Run 3 | Avg duration | Ghi chú |
|---|---|---|---|---|---|---|---|
| B0 (flutter test) | 2026-11-02 | toàn bộ unit/widget | 51/51 ✅ | — | — | ~2s/case | hermetic, không evidence bắt buộc |
| B1 (TC-V, cần user) | — | V1..V6 | ⏳ | ⏳ | ⏳ | | chờ device + Console + account 2 |

## 4. Nợ đã trả từ khi lập plan này

- Debug capture blocks M11C đã gỡ khỏi `tasks_viewmodel.dart` / `firebase_firestore_service.dart` (02/11) — code sẵn sàng freeze trước Phase F.
- `docs/t03-m8-...md` đã gắn audit banner tham chiếu M10 (02/11).
=======
# Lab 3 Test Plan

## Automated checks

| Check | Command | Current evidence |
|---|---|---|
| Dependencies | `flutter pub get` | Run after each dependency/config change |
| Static analysis | `flutter analyze` | Must report zero issues |
| Unit/widget regression | `flutter test` | Hermetic fakes cover ViewModels, analytics, export, FCM wiring |
| Debug APK | `flutter build apk --debug` | Requires user-provided `android/app/google-services.json` |

## Automated coverage

- Authenticated UID reaches task, note, roadmap, notification, token, and report paths.
- Unauthenticated task/note writes fail closed.
- Task/note delete success and failure rollback.
- Notification foreground persistence, tap routing, cold-start routing, token registration.
- Duplicate foreground notifications use deterministic IDs.
- Analytics events route through `AnalyticsService` and avoid rebuild side effects.
- PDF export uploads PDF bytes, saves metadata, reports progress, and records failure.

## Manual/device matrix

| Area | Action | Evidence required | Status |
|---|---|---|---|
| Google Sign-In | Sign in with registered Android app and SHA-1 | Screenshot + Firebase Auth user | Needs device/Console |
| Firestore CRUD | Create, read, update, delete task and note | UI screenshot + Firestore document | Needs device/Firebase |
| FCM | Foreground, background tap, terminated tap | Six screenshots + notification document | Needs device/FCM |
| Analytics | Trigger each event once | DebugView screenshots | Needs device/Console |
| Crashlytics | Non-fatal test and release crash | Crashlytics dashboard evidence | Needs device/Console |
| Remote Config | Change parameter in Console, refresh app | Before/after screenshots | Needs Console |
| Storage | Upload attachment/report | Storage object + download URL | Blocked if Spark lacks bucket |
| Offline | Disable network, edit, reconnect | Before/offline/after screenshots | Needs device |

Do not label runtime PASS from source or hermetic tests alone.
>>>>>>> Stashed changes
