> **PRM393 Final đang tích hợp.** [Đối chiếu yêu cầu](docs/gap-review.md) · [Hợp đồng Firestore cho web](docs/data-model.md) · [Luồng duyệt](docs/cross-role-flow.md) · [AI](docs/ai-feature.md) · [Kiểm thử](docs/test-report.md) · [Nội dung 14 slide](docs/final-slide-content.md).
>
> Build Android mặc định dùng PDF cục bộ và Firebase AI Logic. Bản demo Lab 3 với Media API dùng thêm `--dart-define=LAB3_LEGACY_MEDIA=true` và `--dart-define=REPORT_MEDIA_URL=http://127.0.0.1:8788`. Không dùng tài khoản cá nhân hoặc token trong tài liệu bàn giao.

> **Demo ngày 05/11/2026.** Firebase Spark phục vụ đăng nhập và Firestore. Cloudinary Free đã được xác minh cho PDF báo cáo và tệp đính kèm trên giả lập. Khi chấm, kết nối điện thoại thật. Dev xem Firebase Console, admin xem web riêng. [Cách chạy web admin, FCM server và Media API](admin-web/README.md) · [Giải thích nguyên lý](docs/lab3-oral-defense.md) · [Minh chứng Cloudinary](evidence/app/cloudinary-2026-11-05/verification.json).

> Cập nhật tiếp hạng mục 1–2–3 ngày 04/11/2026: xem [báo cáo xác minh mới](docs/implementation-verification-2026-11-04.md). Đã thêm nhập dữ liệu học tập riêng, Advisor/Strategy theo dữ liệu, tab môn và route FCM. Cloud evidence/E2E vẫn có blocker thực; checklist cũ không chứng minh hoàn tất.

> Cập nhật kiểm tra 04/11/2026: 100/100 Flutter tests pass, analyzer 0 issue. Chi tiết sửa lỗi và giới hạn xác minh: [docs/fix-verification-2026-11-04.md](docs/fix-verification-2026-11-04.md). Các kết quả emulator/Firebase cũ bên dưới là snapshot, không thay thế evidence mới.

# FPTU Second Brain — PRM393 Lab 3 (Cloud-Enabled Mobile App)

Ứng dụng Android Flutter (PRM323 Lab 2 → Lab 3): tra cứu chương trình/đề cương,
quản lý deadline, ghi chú + attachment, tư vấn học vụ, **đồng bộ Firestore
offline-first**, Google Sign-In, FCM + Notification Center, Analytics/Crashlytics/
Remote Config, và **xuất PDF báo cáo học tập** với xác nhận trước khi upload.
Kiến trúc fail-loud: Firebase lỗi là báo lỗi thật, không fallback mock im lặng.

## Build · Run · Test

```bash
flutter pub get
flutter analyze          # 0 issues
flutter test             # 124 unit/widget tests passed
flutter build apk --debug
```

| Hạng mục Lab 3 | Vị trí |
| --- | --- |
| Task map + plan A–G | [docs/lab3-task-map-v5.md](docs/lab3-task-map-v5.md) |
| Kiến trúc | [docs/architecture.md](docs/architecture.md) |
| Test plan (ma trận TC ↔ flow, living doc) | [docs/test-plan.md](docs/test-plan.md) |
| Báo cáo runtime T03-M1…M11E | [docs/](docs/) |
| Security rules + seed + RC defaults | [firebase/](firebase/) |
| AI code log (policy) | [ai/ai-code-log.md](ai/ai-code-log.md) |
| Evidence matrix | [evidence/README.md](evidence/README.md) — matrix và yêu cầu bằng chứng; chưa có bộ ảnh/trace hoàn chỉnh |
| Report/slides PDFs | [report/Lab03_STUDENT_ID.pdf](report/Lab03_STUDENT_ID.pdf) (10 trang), [slides/Lab03_STUDENT_ID_slides.pdf](slides/Lab03_STUDENT_ID_slides.pdf) (15 slide); kịch bản video tại [docs/lab3-video-script.md](docs/lab3-video-script.md) |

Tạo lại báo cáo với thông tin trang bìa bằng `dart run tool/generate_report_pdf.dart MSSV "Họ và tên"`. Thay `MSSV` bằng mã sinh viên. PDF được ghi trong `report/`.

ARTEMIS có 26 kịch bản trong harness. TC_11 Remote Config đã pass 3/3 lượt trên Pixel 7 giả lập. Checklist yêu cầu tối thiểu 10 ca, mỗi ca chạy 3 lần, và một phiên exploratory. [Hướng dẫn chạy](e2e_test/README.md) · [Kết quả ngày 07/11](evidence/artemis/2026-11-07-regression.md).

### Evidence matrix (local emulator, 2026-11-02)

| Area | Evidence | Status |
|------|----------|--------|
| Sign-In | Emulator log: Google Sign-In successful, navigation to HomeScreen | ✅ Verified |
| Roadmap/Firestore | Courses displayed from `courses` collection; `passedCourses` prerequisite checks work | ✅ Verified |
| Task CRUD | Create → Firestore `users/{uid}/tasks/{taskId}`; Toggle `isCompleted` update; Delete removes test records | ✅ Verified |
| Note CRUD | Create → Firestore `users/{uid}/notes/{noteId}`; Read verified | ✅ Verified |
| Delete | 2 test records deleted successfully; optimistic restore on failure | ✅ Verified |
| Manual sync | SyncReloadService reloads all 3 stores after NoteModel Timestamp fix | ✅ Verified |
| NoteModel Timestamp | `_formatUpdatedAt` handles Firestore `Timestamp`, `DateTime`, legacy `String` | ✅ Verified |
| NotificationModel Timestamp | `fromMap`/`fromPush` handle `Timestamp`, `DateTime`, ISO string; regression test added after a live crash | ✅ Verified |
| Notification banner/route | Foreground push persists `route`, shows in-app banner, Notification Center tap navigates | ✅ Verified (hermetic) |
| Maintenance mode | Remote Config `maintenance_mode=true` renders `MaintenanceScreen` instead of the shell | ✅ Verified (hermetic) |
| Version gate | Remote Config `min_app_version` above the build blocks with `VersionBlockedScreen` before sign-in; equal/newer passes; malformed value fails open | ✅ Verified (hermetic) |
| Tests | 89 tests pass (unit/widget hermetic + Timestamp parsing + SyncReloadService + version gate + Advisor levels/consent) | ✅ Verified |
| Build | `flutter analyze`: 0 issues; `flutter test`: 89/89 pass; `flutter build apk --debug`: PASS | ✅ Verified |

### Xác minh runtime và giới hạn

- Trên giả lập đã xác minh FCM ở ba trạng thái, Crashlytics fatal/non-fatal qua web admin và Remote Config 31 → 30 trên cùng APK. [Mục lục minh chứng](evidence/README.md).
- PDF báo cáo và tệp đính kèm đã upload/tải lại qua Cloudinary. Firestore đã đọc lại metadata của cả hai. Bản demo USB cần Media API chạy trên máy tính và `adb reverse`.
- DebugView đã nhận tám loại event trong lượt 07/11. Cần thu các event còn thiếu, batch ARTEMIS và lượt kiểm tra trên điện thoại thật. Nhánh từ chối tài khoản ngoài `@fpt.edu.vn` cần tài khoản kiểm thử riêng.

### Hướng dẫn chạy (emulator)

```bash
# Cài dependency
flutter pub get

# Phân tích code
flutter analyze

# Chạy test
flutter test

# Build APK debug (cần google-services.json out-of-band)
flutter build apk --debug

# Chạy trên emulator
flutter emulator --create --avd <avd-name>
flutter run -d <emulator-id>
```

### Giới hạn

- Kết quả runtime đã ghi nhận trên emulator với Firebase project `prm323-lab2-gr6`; `google-services.json` là file out-of-band/gitignored. APK debug build đã pass trong checkout này, nhưng clone mới cần tự cung cấp config hợp lệ.
- Khi chấm trên Android thật, kiểm tra Play Services, thông báo, kết nối với Media API và Google Sign-In bằng tài khoản demo.
- Repo hiện `prm323-lab2-gr6` chưa khớp mẫu tên repo ở checklist §2.1 (`PRM393_Lab03_<StudentID>`). Đổi tên repo trên GitHub khi nộp bài; checklist không yêu cầu đổi `applicationId`.
- `@fpt.edu.vn` enforcement: code đã lọc account và hậu kiểm email; runtime rejection với tài khoản khác domain chưa kiểm chứng.

### AI tools sử dụng

- Claude Code ( Anthropic ) để trợ lý phát triển, review code, và tạo documentation này.
- firebase_analytics, firebase_core, firebase_auth, firebase_crashlytics, firebase_messaging, firebase_remote_config, cloud_firestore, firebase_storage packages.
- Provider state management, `AsyncViewState<T>` pattern, `NoteModel.fromMap` với Timestamp parsing.

---

## Hồ sơ thiết kế gốc (PRM323 Lab 2)

Bộ hồ sơ thiết kế UX/UI cho ứng dụng Android hỗ trợ sinh viên FPTU tra cứu chương trình/đề cương offline, quản lý deadline, ghi chú Obsidian Vault và tư vấn học vụ. Catalog học tập được thiết kế theo hướng đồng bộ lên cloud từ nguồn FLM được phép; sinh viên chọn ngành để tải về máy. Kết nối FAP là tùy chọn cho dữ liệu cá nhân. Prototype thiết kế dùng dữ liệu mẫu.

## Tài liệu bàn giao

| Hạng mục | Nội dung |
| --- | --- |
| Figma | [PRM323 Lab 2 — FPTU Second Brain](https://www.figma.com/design/0gpT8zQmaDiCmcklbFuTSq/PRM323_Lab2_FPTU_Second_Brain) |
| Personas | [ux/persona.md](ux/persona.md) — mục lục, phạm vi, coverage và research backlog; ba hồ sơ riêng trong [ux/personas/](ux/personas/): P01, P02 (Primary), P03 |
| User flow | [ux/user-flow.md](ux/user-flow.md) — 3 flow Lab 2 ban đầu và nhánh AI Flow 1A |
| Academic workflows | [ux/academic-workflows.md](ux/academic-workflows.md) — Workflow 4–6, tư vấn 2.1, chiến lược 2.2, phạm vi FLM/FAP và quyền riêng tư |
| Design brief/system | [design/DESIGN.md](design/DESIGN.md) |
| Screen specification | [design/screen-spec.md](design/screen-spec.md) |
| Design decisions & accessibility | [design/design-decisions.md](design/design-decisions.md) |
| AI design log | [ai/ai-design-log.md](ai/ai-design-log.md) — Google Stitch và UX critique bằng Claude |
| Flutter handoff | [handoff/flutter-handoff.md](handoff/flutter-handoff.md) |
| Stitch evidence | [assets/stitch](assets/stitch/) — ảnh ban đầu và ba vòng lặp |
| Final UI exports | [assets/figma](assets/figma/) — export của 8 màn hình cốt lõi cùng dialog/biến thể lỗi, 360 × 800; các frame mở rộng xem trực tiếp trên Figma và trong screen spec |

## Các trang Figma

1. 01 User Flow
2. 02 Wireframe
3. 03 Final UI
4. 04 Design System
5. 05 Components
6. 06 Prototype

Prototype có 6 điểm bắt đầu: Flow 1–3 giữ nguyên các tác vụ Lab 2; Workflow 4 (thiết lập/catalog/lộ trình), Workflow 5 (tư vấn học vụ 2.1) và Workflow 6 (chiến lược học tập 2.2) mở rộng cho P01/P03. Hỏi AI giữ vai trò nhánh Flow 1A từ chi tiết môn. Các trang `03 Final UI` và `06 Prototype` dùng dữ liệu minh họa, không khẳng định đã kết nối FLM/FAP thật.

## Phạm vi

Android mobile-first, Material Design 3, light theme, Inter, khung Figma chính 360 × 800 dp; responsive tại 412 dp được mô tả trong `design/design-decisions.md`. Catalog ngành/đề cương được phân biệt với dữ liệu cá nhân: dữ liệu bảng điểm/lịch lưu cục bộ mặc định; AI chỉ nhận các trường đã nêu trong consent cho lần đó. Hỏi AI cần mạng.
