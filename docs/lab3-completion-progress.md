# PRM Lab 3 Completion Progress

**Updated:** 2026-11-04 (defect fixes pass)
**Checkout:** `main` — no Git operations performed.

## Fixes applied 2026-11-04

| File | Defect | Fix |
|---|---|---|
| `lib/models/notification_model.dart` | `receivedAt` cast to `String?` while Firestore stores `FieldValue.serverTimestamp()` → `type 'Timestamp' is not a subtype of type 'String?'` crashed the whole Notification Center on any persisted doc | `_formatReceivedAt` accepts `Timestamp` / `DateTime` / ISO string / legacy text; `route` carried on the model and through `toMap`/`copyWith`/`fromPush` |
| `lib/viewmodels/notifications_viewmodel.dart` | Foreground push dropped `route`, so a Notification Center tap could not navigate | `route` persisted with the doc; `banner` + `dismissBanner()` expose the foreground push to the shell |
| `lib/widgets/app_components.dart` | No in-app banner for a foreground push (T12 wants 3 states × banner + center) | `ForegroundPushBanner` widget |
| `lib/main.dart` | `maintenance_mode` only printed in Demo Area — never enforced | `AuthGate` renders `MaintenanceScreen` when the flag is on; "Thử lại" re-fetches and leaves the screen when maintenance ends |
| `lib/main.dart` | Shell had no banner surface | `AppShell` stacks the banner over `IndexedStack`; tap routes to the push's destination |
| `lib/screens/notifications_screen.dart` | Center cards marked read but never navigated | Card tap navigates to `item.route` when present |
| `e2e_test/conftest.py` | `require_artemis(func)` invoked a `pytest.mark.skipif` MarkDecorator as a function → `TypeError` on import of every test module | alias `require_artemis = skip_without_adb` |
| `e2e_test/test_exploratory.py` | used `pytest.mark.e2e` without `import pytest` → collection error | import added |
| `lib/services/remote_config_service.dart` | `min_app_version` displayed in Demo Area only — never enforced (M-09 gap) | `kAppVersion`, `compareVersions`, `isOutdatedVersion` (fails open on malformed input), `isVersionBelowMinimum` getter, `overrides` map for hermetic tests; in-code default `vault_sync_interval_mins` aligned to the committed JSON (was 15 vs 30) |
| `lib/main.dart` | No version gate at all | `AuthGate` is stateful: `min_app_version` block → `VersionBlockedScreen`, checked before sign-in and before `maintenance_mode`; "Thử lại" re-fetches via `fetchAndActivate()` with a spinner and a SnackBar when still blocked. `MaintenanceScreen` shares the same `onRecheck`, removing the duplicated fetch logic |

Regression coverage: `test/models/notification_model_test.dart` (7 cases: Timestamp / DateTime / ISO / legacy / missing, route in `toMap`/`copyWith`/`fromPush`) and one banner+route case in `test/viewmodels/notifications_test.dart`.

Version-gate coverage: `test/services/version_gate_test.dart` (16 cases) — below / equal / above minimum for `compareVersions`, `isOutdatedVersion`, `RemoteConfigService.isVersionBelowMinimum`; fail-open on empty and malformed `min_app_version`; in-code defaults asserted against the committed `firebase/remote-config-defaults.json`; `kAppVersion` asserted against `pubspec.yaml`; and widget tests that an outdated build is blocked before sign-in, an equal/newer build reaches the shell, sign-in still renders when nothing blocks, `maintenance_mode` still gates, and the version block wins over maintenance.

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
- Google Sign-In applies `hostedDomain: 'fpt.edu.vn'` and checks the signed-in email after credential exchange; non-domain accounts are signed out and rejected (runtime rejection path not yet tested).

## Verified on emulator / device (2026-11-02)

- **Google Sign-In**: thành công, điều hướng đến HomeScreen.
- **Roadmap Firestore read**: hiển thị courses từ collection `courses`; `passedCourses` hoạt động.
- **Manual sync**: `SyncReloadService` reload cả 3 store thành công sau khi sửa `NoteModel` để parse `Timestamp`.
- **Task CRUD**: tạo task → ghi Firestore `users/{uid}/tasks/{taskId}`; toggle `isCompleted` cập nhật đúng.
- **Note CRUD**: tạo note → ghi Firestore `users/{uid}/notes/{noteId}`.
- **Delete CRUD**: hai bản ghi test đã xóa thành công.
- **Firebase project binding**: emulator sign-in and Firestore reads/writes used project `prm323-lab2-gr6`; `google-services.json` was present out-of-band and remains gitignored.

## Files changed in implementation pass

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
- `docs/test-plan.md` — replaced stale merge-conflicted content with one consistent plan; ARTEMIS rows are explicitly planned/not run.
- `README.md` — corrected Firebase, S-10, test-count, and ARTEMIS statements; linked draft deliverables.
- `report/Lab03_DRAFT.md` — factual report source draft with evidence placeholders.
- `slides/Lab03_DRAFT.md` — 14-slide outline with runtime items marked pending.

## Checks run

- `flutter analyze` — PASS, no issues.
- `flutter test` — PASS, **84 tests** (2026-11-04; thêm NotificationModel Timestamp/route, banner, maintenance + min_app_version gate).
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

## External/runtime verification still pending

- FCM foreground/background/terminated delivery and tap routing.
- Analytics DebugView event delivery and exact counts.
- Crashlytics non-fatal event visible in dashboard.
- Remote Config before/after behavior from Console.
- Storage bucket provisioning, note attachment upload, and PDF upload/runtime. Verify the current bucket first; do not assume Spark blocks it and do not upgrade billing without team approval.
- Firestore Rules deployment status recheck in Console; local rules do not prove deployed state.
- Offline/reconnect behavior.
- Runtime rejection of a Google account outside `@fpt.edu.vn`.

The ignored `android/app/google-services.json` is required to build a fresh checkout, but it was available out-of-band for the verified emulator build/sign-in. Never print or commit it.

## Submission gaps

- `evidence/README.md` exists, but evidence screenshots, ARTEMIS harness/traces (minimum 10 cases × 3 runs), and exploratory notes are not present yet. The 68 Flutter tests are not ARTEMIS runs.
- Draft sources now exist at `report/Lab03_DRAFT.md` and `slides/Lab03_DRAFT.md`. Final report PDF (8–12 pages), slide PDF (12–15 pages), and 5–10 minute demo video are not present; Student ID and missing runtime evidence are needed for final versions.
- Genuine AI code review deliverable is missing: checklist requires at least five findings and three separate fix commits. Do not fabricate review results; Git/PR work remains with the user.
- Rubric naming requirement is repo `PRM393_Lab03_<StudentID>` at submission; it does not require changing `applicationId` `com.example.prm323_lab3`.
