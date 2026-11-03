# Test Plan — PRM393 Lab 3 (ARTEMIS + runtime verification)

> **Living document** theo guide v5 §6.2 — cập nhật mỗi khi có feature mới hoặc
> kết quả verify mới. Nguồn case: 3 flow trong `ux/user-flow.md` (§2.1 happy path,
> §2.2 error branch, §2.3 recovery) + yêu cầu Firebase/FCM/PDF guide §1–§5.
> Evidence naming: `TC-` (test case), `FLW-` (flow screenshots), `SCR-` (screen).
>
> **Nguyên tắc (guide tr.23):** kiểm tra **giá trị quan sát được**, không chỉ dựa
> vào trạng thái SUCCESS; **không** gắn nhãn runtime PASS từ source hoặc hermetic
> test đơn thuần.
>
> **Trạng thái hiện tại:** unit/widget Flutter **54/54** pass. Runtime device batch
> 02/11 (`docs/lab3-completion-progress.md`) xác minh sign-in, Roadmap read sau
> seed, Task CRUD, Note CRUD, delete — **TC-V1/V3/V4 đóng một phần**. ARTEMIS E2E
> (`e2e_test/`) chưa chạy — cần uv + API key + device (E1).

## 0. Phân lớp kiểm thử

| Lớp | Công cụ | Trạng thái |
|---|---|---|
| Unit/ViewModel/Widget/Model | `flutter test` (hermetic fakes) | ✅ 54/54 pass — 03/11 |
| Static | `flutter analyze` | ✅ 0 issues |
| Debug APK build | `flutter build apk --debug` + `google-services.json` ngoài repo | ✅ 02/11 (không commit JSON — `.gitignore` đã loại) |
| Runtime CRUD trên emulator | app debug + Firebase Console + `adb logcat` | ⏳ một phần 02/11; còn FCM/Analytics/Crash/RC/Offline/Storage |
| E2E ARTEMIS | Python ≥3.12 + uv + adb + API key `.env` | ❌ chưa setup (E1) |
| Exploratory 15–30′ + AI summary | ARTEMIS Pro/exploratory | ❌ chờ E3 |

## 1. Ma trận TC ↔ Flow (guide §6.2)

### Flow 1 — Tra cứu Slot & Đầu điểm (G1, M1: ≤8s, ≤3 chạm)

| ID | Loại | Bước rút gọn | Kết vọng | Unit đã phủ | On-device |
|---|---|---|---|---|---|
| TC-F1-01 | happy | Home → tab Lộ trình → chạm môn PRM323 → tab Lịch slot | ≤3 chạm, slot list từ Firestore `courses` | `roadmap_viewmodel_test.dart` | ✅ read pass 02/11 sau seed; thiếu ảnh FLW-01 |
| TC-F1-02 | happy | Ô tìm kiếm nhập `PRM` | list lọc còn môn khớp | `roadmap_viewmodel_test.dart` | ⏳ |
| TC-F1-03 | error | Firestore lỗi/không đăng nhập | empty state hoặc lỗi thật, **không** mock fallback | — | ✅ empty-state-when-no-UID 02/11 |
| TC-F1-04 | branch | Chi tiết môn → "Hỏi trợ lý AI về môn này" | vào Advisor kèm mã môn | `advisor_viewmodel_test.dart` | ⏳ |

### Flow 2 — Quản lý Deadline & Undo (G2, M3: undo 8s + phục hồi sync)

| ID | Loại | Bước rút gọn | Kết vọng | Unit đã phủ | On-device |
|---|---|---|---|---|---|
| TC-F2-01 | happy | Tab Việc cần làm → chạm checkbox | gạch ngang, Snackbar HOÀN TÁC 8s, Firestore doc update | `tasks_notes_test.dart` (toggle) | ✅ toggle cập nhật đúng 02/11; thiếu ảnh |
| TC-F2-02 | recovery | Chạm nhầm → HOÀN TÁC trong 8s | task về vị trí + trạng thái cũ | `tasks_notes_test.dart` | ⏳ |
| TC-F2-03 | happy | Sửa task (title/course/due) → Lưu | `updateTask` pass trên doc **legacy lẫn new** | `tasks_notes_test.dart` (edit revert) | ⏳ — close-out nợ M11E (tạo+sửa task **có sẵn** trên Console) |
| TC-F2-04 | error | Tắt mạng → sửa task | local revert + `lastError` Việt, không mất dữ liệu | `tasks_notes_test.dart` | ⏳ TC-V2 |
| TC-F2-05 | happy | Tạo task mới → doc ID = `task_<ts>` cả path lẫn field `id` | không còn `not-found` khi update | `tasks_notes_test.dart` (add) | ✅ tạo task ghi đúng path 02/11 |

### Flow 3 — Quick Capture Ghi chú & Vault Sync (G4, M2 ≤15s, M3)

| ID | Loại | Bước rút gọn | Kết vọng | Unit đã phủ | On-device |
|---|---|---|---|---|---|
| TC-F3-01 | happy | Tab Ghi chú → tạo note → Lưu | note lên `users/{uid}/notes/{noteId}`, ≤15s; `updatedAt` parse được Firestore Timestamp | `tasks_notes_test.dart`, `note_model_test.dart`, `widget_test.dart` | ✅ 02/11; thiếu ảnh FLW-03 |
| TC-F3-02 | error | Lưu note khi tắt mạng | error snackbar, không claim đã lưu | `widget_test.dart` | ⏳ |
| TC-F3-03 | happy | Upload attachment PDF/ảnh | path `notes/{uid}/{allPaths=**}` pass rules | — | ⏳ (blocked nếu Spark chưa có bucket) |

### Cross-cutting Firebase (guide §1–§5)

| ID | Loại | Bước | Kết vọng | Unit đã phủ | On-device |
|---|---|---|---|---|---|
| TC-X-01 | auth | Google Sign-In với **@fpt.edu.vn** | vào Home; account ngoài domain bị chặn + sign-out (S-10 mới) | `analytics_wiring_test.dart` + auth tests | ✅ sign-in pass 02/11 (trước gate domain — chạy lại với gate) |
| TC-X-02 | isolation | Account B đọc path user A | permission-denied | rules audit (M7) | **BLOCKED** — cần account 2 |
| TC-X-03 | analytics | ≥7 events, DebugView ≥2 params/event | 1 lần/action | `analytics_wiring_test.dart` | ⏳ DebugView evidence |
| TC-X-04 | remote config | `maintenance_mode`/`min_app_version` | enforce đúng, Console before/after | — | ⏳ |
| TC-X-05 | crashlytics | test crash debug build | crash lên dashboard | — | ⏳ |
| TC-X-06 | fcm | Push foreground/background/terminated + tap | Notification Center nhận, tap route đúng | `notifications_test.dart` (deterministic IDs) | ⏳ 6 ảnh |
| TC-X-07 | pdf | Consent → export → upload `reports/{uid}/` | progress, metadata doc, event `export_report` | `report_export_service_test.dart` | ⏳ (Storage bucket blocker) |

### TC-V — Đóng nợ audit M10 (cập nhật theo verify 02/11)

| ID | Nợ M10 | Trạng thái mới | Còn thiếu gì |
|---|---|---|---|
| TC-V1 | Task UPDATE | 🟡 một phần (create+toggle ✅) | **UPDATE task có sẵn + verify Console + log** (nợ M11E thật sự), 3 runs + ảnh `TC-V1-*` |
| TC-V2 | Offline persistence | ❌ NOT TESTED | toggle wifi `adb shell svc wifi disable/enable` quanh CRUD |
| TC-V3 | Note CRUD | 🟡 một phần (create/delete ✅, sync reload ✅) | attachment nested + ảnh Console khớp |
| TC-V4 | Seed catalog | ✅ DONE 02/11 | Roadmap đọc `courses` + `passedCourses` hiển thị |
| TC-V5 | Debug log capture | ❌ | `adb logcat -s flutter` cả phiên → `evidence/firebase/` |
| TC-V6 | Cross-account isolation | ❌ BLOCKED | cần Google account thứ 2 |

### TC-S — Nhánh lỗi từng dịch vụ Firebase (rubric §25: "mỗi dịch vụ có ca kiểm thử lỗi")

| ID | Dịch vụ | Ca lỗi | Kết vọng |
|---|---|---|---|
| TC-S-01 | Auth | sign-in tài khoản ngoài `@fpt.edu.vn` | báo lỗi `invalid-domain`, không vào Home, đã sign-out |
| TC-S-02 | Firestore | tắt mạng khi add/update | error surface + revert, không mock im lặng |
| TC-S-03 | Storage | upload file vượt size / sai type ở `reports/` | deny, thông báo thật |
| TC-S-04 | Analytics | event khi chưa init xong | không crash, sự kiện bị bỏ có log |
| TC-S-05 | Crashlytics | recordError non-fatal | lên dashboard trong ~10′ |
| TC-S-06 | Remote Config | init fail | fallback defaults json, app vẫn chạy |
| TC-S-07 | FCM | token refresh khi chưa đăng nhập | không ghi orphan path, log rõ |

## 2. Quy trình chạy (E3, guide tr.23)

1. Mỗi TC **≥3 lần** trên cùng device; bảng pass rate + avg duration ở §3; **nhật ký thực thi** lưu `evidence/artemis/logs/`.
2. TC flaky (<3/3): điều tra, fix hoặc gắn known-issue — không bỏ qua.
3. Bao phủ bắt buộc: 3 flow Lab 2 ✅ (F1/F2/F3), **một nhánh lỗi** ✅ (TC-S), **một tương tác Android gốc** ✅ (TC-N native: notification system UI / toggle wifi qua adb — ARTEMIS chạy qua ADB).
4. Evidence: `evidence/artemis/TC-<id>_<run>.png`, `evidence/firebase/TC-V*_*`, `FLW-01..03`.
5. Exploratory **15–30′** sau khi TC-V khép → AI summary `evidence/artemis/exploratory-summary.md`.

## 3. Kết quả (cập nhật sau mỗi batch)

| Batch | Ngày | TC | Run 1 | Run 2 | Run 3 | Avg duration | Ghi chú |
|---|---|---|---|---|---|---|---|
| B0 (flutter test) | 2026-11-03 | unit/widget toàn bộ | 54/54 ✅ | — | — | ~2s/case | hermetic — không được suy ra runtime PASS |
| B1 (manual device) | 2026-11-02 | sign-in, F1-01 read, F2-01/05, F3-01, delete | ✅ 1 lần | ⏳ | ⏳ | — | nguồn `docs/lab3-completion-progress.md`; cần nâng lên 3 runs + ảnh |
| B2 (TC-V còn lại + ARTEMIS) | — | V1,V2,V3,V5,V6 + TC-S + FLW-* | ⏳ | ⏳ | ⏳ | | cần E1 (uv + API key) + device + account 2 |

## 4. Nợ đã trả từ khi lập plan này

- Debug capture blocks M11C đã gỡ khỏi `tasks_viewmodel.dart` / `firebase_firestore_service.dart` (02/11).
- `docs/t03-m8-...md` đã gắn audit banner tham chiếu M10 (02/11).
- Seed catalog `courses` + `passedCourses` trên user doc — DONE trên Console 02/11 (TC-V4).
- `NoteModel` parse Firestore `Timestamp` — fix runtime note-sync 02/11 (`261e6dc`).
- Conflict markers stash/merge trong file này — dọn 03/11, gộp phiên bản "Automated checks / Manual matrix" của nhóm vào §0/§1.
