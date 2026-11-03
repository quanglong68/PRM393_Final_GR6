# PRM Lab 3 Completion Progress

**Updated:** 2026-11-02 (revision 2)
**Checkout:** `main` — no Git operations performed.

## Completed in code

- Firebase initialization fails loud with `FirebaseConfigErrorApp`; no silent mock composition.
- Authenticated UID drives user-owned reads/writes; unauthenticated writes fail closed.
- Task/note create, update, delete failures revert optimistic state and surface errors.
- PDF report generation, consent dialog, Storage upload path, Firestore metadata, progress, and analytics are wired.
- Analytics uses interface calls; rebuild-time course/prerequisite lookups are pure.
- FCM permission/token registration, token refresh persistence, foreground handling, background persistence, terminated tap routing, and Notification Center are wired.
- Notification persistence uses deterministic IDs when FCM supplies `notificationId` or `messageId`, preventing duplicate foreground rows.
- Demo Area manual sync reloads Roadmap, Tasks, and Notes from Firestore through `SyncReloadService`; success and `sync_triggered` only occur when all three stores leave reload without `ViewState.error`.
- Roadmap catalog diagnosis and safe idempotent seed procedure are documented in `docs/firestore-catalog-seed.md`; no Firebase writes were executed.
- Storage rules cover recursive note paths and PDF-only reports.
- `NoteModel.fromMap` handles Firestore `Timestamp`, `DateTime`, and legacy `String` values for `updatedAt` field.

## Verified on emulator / device (2026-11-02)

- **Google Sign-In**: thành công, điều hướng đến HomeScreen.
- **Roadmap Firestore read**: hiển thị courses từ collection `courses`; `passedCourses` hoạt động.
- **Manual sync**: `SyncReloadService` reload cả 3 store thành công sau khi sửa `NoteModel` để parse `Timestamp`.
- **Task CRUD**: tạo task → ghi Firestore `users/{uid}/tasks/{taskId}`; toggle `isCompleted` cập nhật đúng.
- **Note CRUD**: tạo note → ghi Firestore `users/{uid}/notes/{noteId}`.
- **Delete CRUD**: hai bản ghi test đã xóa thành công.

## Files changed this pass

- `lib/models/note_model.dart` — `_formatUpdatedAt` xử lý Firestore `Timestamp`
- `lib/services/firestore_service.dart`
- `lib/services/firebase_firestore_service.dart`
- `lib/services/firebase_messaging_service.dart`
- `lib/viewmodels/notifications_viewmodel.dart`
- `lib/viewmodels/auth_viewmodel.dart`
- `lib/screens/sync_vault_screen.dart`
- `lib/services/sync_reload_service.dart`
- `test/models/note_model_test.dart` — NoteModel Timestamp parsing tests
- `test/helpers/fake_firestore_service.dart`
- `test/helpers/mock_firestore_service.dart`
- `test/viewmodels/notifications_test.dart`
- `test/services/sync_reload_service_test.dart`
- `docs/firestore-catalog-seed.md`
- `docs/analytics-plan.md`
- `docs/test-plan.md`
- `docs/lab3-completion-progress.md`
- `docs/lab3-final-requirement-audit.md`

## Checks run

- `flutter analyze` — PASS, no issues.
- `flutter test` — PASS, **54 tests** (thêm 2: NoteModel Timestamp + SyncReloadService).
- `flutter pub get` — PASS on 2026-11-02.
- `flutter build apk --debug` — PASS on 2026-11-02 with out-of-band `android/app/google-services.json`.

## Needs verification (chưa xác minh)

- FCM delivery foreground/background/terminated và tap routing trên thiết bị.
- Analytics DebugView event delivery và exact counts.
- Crashlytics dashboard collection (non-fatal test).
- Remote Config Console before/after behavior.
- Runtime PDF/Storage upload và Storage bucket availability (Spark plan blocker).
- Offline/reconnect behavior.
- Firestore Rules deployment status — cần kiểm tra trên Console.

## External blockers

- Storage bucket: Spark plan có thể chặn provisioning. Không nâng billing nếu chưa có quyết định nhóm.
- `android/app/google-services.json` phải cung cấp ngoài repo; không commit/print.
- S-10: Email `@fpt.edu.vn` enforcement chưa có — UI label claim nhưng không gate.

## Submission gaps

- Evidence screenshots, ARTEMIS traces, AI review output, report PDF, slide PDF, và demo video cần bằng chứng thật. Không bịa.
- `docs/code-review.md` chưa có — cần review thật và commit fix.
- S-12: Rubric yêu cầu **tên repo** `PRM393_Lab03_<StudentID>`, KHÔNG yêu cầu đổi applicationId. Rename repo trên GitHub khi nộp.
