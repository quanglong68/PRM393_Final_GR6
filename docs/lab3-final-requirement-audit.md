# PRM Lab 3 — Final Requirement Audit

**Date:** 2026-11-02
**Repository:** `prm323-lab2-gr6`
**Framework:** Flutter / Dart
**Project:** FPTU Second Brain (`com.example.prm323_lab3`)

---

## Executive Summary

The audit was refreshed against current source on 2026-11-02. Core data integrity, Firebase initialization, PDF export, analytics wiring, FCM plumbing, and test coverage are implemented in code. Runtime Firebase, device, Console, Storage, and submission evidence remain external verification work.

### Audit Highlights

| Category | Count |
|---|---|
| **DONE IN CODE** (static/tests verified) | Updated rows below; runtime not implied |
| **EXTERNAL / DEVICE BLOCKERS** | Firebase config, rules, device, Storage, evidence |
| **RESOLVED IN CODE** | S-01 through S-09 except external runtime proof |
| **FEATURE STATUS** | F-01 through F-09 code-complete; F-10 partial |
| **NOT TESTED / UNVERIFIABLE** | 17 items (runtime/config-dependent) |

---

## 1. Requirement Matrix

### 1.1 Blocking Items (must resolve before progress)

| ID | Requirement | Status | Evidence / Notes |
|---|---|---|---|
| **B-01** | Dependency resolution / build | `DONE IN CODE` | `pubspec.yaml:24` uses `sdk: ^3.13.0`; current `flutter analyze` and `flutter test` pass. |
| **B-02** | Real Firebase project binding | `NEEDS DEVICE/FIREBASE VERIFICATION` | `lib/firebase_options.dart` contains project `prm323-lab2-gr6`; prior manual setup evidence records valid `google-services.json` and debug APK build. Current file is gitignored/out-of-band and must be rechecked before runtime claims. |
| **B-03** | Release `INTERNET` permission | `DONE IN CODE` | `android/app/src/main/AndroidManifest.xml:2-4` declares `INTERNET` and `POST_NOTIFICATIONS`. Release runtime still needs device verification. |
| **B-04** | Silent mock fallback hides config failure | `DONE IN CODE` | `lib/main.dart:114-117,239-280` routes failed initialization to `FirebaseConfigErrorApp`; production composition no longer creates test mocks. |
| **B-05** | Signed-in identity plumbing | `DONE IN CODE` | `TasksViewModel`, `NotesViewModel`, `RoadmapViewModel`, `NotificationsViewModel`, and `SyncVaultScreen` use `AuthService.currentUserId`; null UID rejects user-owned writes. |

### 1.2 Critical Security Risks

| ID | Requirement | Status | Evidence / Notes |
|---|---|---|---|
| **S-01** | Identity hard-coded, not derived from auth (critical) | `RESOLVED IN CODE` | User-owned ViewModels and Sync Vault now derive UID from `AuthService.currentUserId`; unauthenticated writes fail closed. Runtime rules verification remains external. |
| **S-02** | Deletes are no-ops that look like success (critical) | `RESOLVED IN CODE` | `FirebaseFirestoreService.deleteTask` and `deleteNote` call Firestore `delete()`; ViewModels restore optimistic state and surface failure. |
| **S-03** | Write failures swallowed while UI reports success (critical) | `RESOLVED IN CODE` | Task/note writes return `false`, revert optimistic state, set `lastError`, and screens show error SnackBars instead of success. |
| **S-04** | Firebase failure masked at startup (high) | `RESOLVED IN CODE` | Initialization errors route to blocking `FirebaseConfigErrorApp`; Storage service does not fabricate upload URLs. |
| **S-05** | Release build has no network permission (high) | `RESOLVED IN CODE` | Main Android manifest declares `INTERNET`; Android 13+ notification permission also declared. |
| **S-06** | Analytics duplicates and lies about volume (medium-high) | `RESOLVED IN CODE` | `isEligibleForCourse` and `findCourseById` are pure; explicit actions log events once, with debounce for search. |
| **S-07** | Analytics type checks make instrumentation fragile (medium) | `RESOLVED IN CODE` | Event call sites use `AnalyticsService` interface; regression tests verify interface doubles receive events. |
| **S-08** | Remote Config instance mismatch (medium) | `RESOLVED IN CODE` | `main()` creates one Crashlytics and one Remote Config instance, awaits initialization, and injects those same instances. |
| **S-09** | Storage rules deny nested note attachments (medium) | `RESOLVED IN CODE` | `firebase/storage.rules:27` uses recursive `{allPaths=**}` for note attachments and reports. |
| **S-10** | Email-domain claim not enforced (medium, compliance) | `RESOLVED IN CODE` | `GoogleSignIn(hostedDomain: 'fpt.edu.vn')` filters picker; post-sign-in check rejects non-`@fpt.edu.vn` and signs out. Runtime verify on device. |
| **S-11** | Test suite cannot catch defects (medium) | `IMPROVED IN CODE` | Current tests cover UID propagation, rollback, delete persistence calls, analytics wiring, PDF export, and FCM token/notification flows. Live Firebase Rules and device delivery still need external verification. |
| **S-12** | Repository name mismatch with rubric (low) | `CONFIRMED` | Rubric §9 requires repo named `PRM393_Lab03_<StudentID>`. Current repo is `prm323-lab2-gr6`. **Rubric does NOT require changing applicationId** — only repo name and deliverable file names (`report/Lab03_<StudentID>.pdf`, `slides/Lab03_<StudentID>_slides.pdf`). Rename repo on GitHub khi nộp. |

### 1.3 Feature Gaps

| ID | Requirement | Status | Notes |
|---|---|---|---|
| **F-01** | PDF export + Storage upload | `DONE IN CODE` | `ReportPdfService`, `ReportExportService`, consent dialog, progress, metadata, and `export_report` are implemented. Runtime Storage remains blocked/unverified externally. |
| **F-02** | FCM + Notification Center | `DONE IN CODE` | Permission, token storage/refresh, foreground/background/terminated handling, deterministic notification persistence, tap routing, and owner-scoped rules are implemented. Device delivery remains unverified. |
| **F-03** | Storage actually used | `DONE IN CODE` | Notes attachment and report export call `StorageService.uploadFile`; Cloud Storage provisioning remains external. |
| **F-04** | Real attachments | `DONE IN CODE` | `NoteEditorScreen` uses `file_picker`, reads bytes, validates type/size, uploads through `NotesViewModel`, and stores only returned URLs. |
| **F-05** | Advisor error branch + retry | `DONE IN CODE` | `AdvisorViewModel` tracks last question, error state, retry action, and does not claim a reply on failure. |
| **F-06** | Share-consent dialog | `DONE IN CODE` | PDF export shows explicit consent before upload and describes data scope and Storage path. |
| **F-07** | Task edit | `DONE IN CODE` | `TasksScreen` opens an add/edit sheet and `TasksViewModel.editTask` persists with rollback on failure. |
| **F-08** | Analytics wiring | `DONE IN CODE` | Login user ID, navigator observers, interface event helpers, explicit action triggers, and regression tests are present. DebugView remains device evidence. |
| **F-09** | Crashlytics custom key + user id | `DONE IN CODE` | `AuthViewModel._onLogin` sets Crashlytics user ID and `auth_method` custom key. Dashboard delivery remains unverified. |
| **F-10** | `docs/analytics-plan.md`, `docs/test-plan.md`, `docs/code-review.md`, `firebase/remote-config-defaults.json`, `lib/utils/` | `PARTIAL` | `docs/analytics-plan.md`, `docs/test-plan.md`, and `firebase/remote-config-defaults.json` exist. `docs/code-review.md` and `lib/utils/` remain absent because no genuine external review output or utility requirement was created. |

### 1.4 Verified Implementations (PASS / IMPLEMENTED)

The following are verified as working:

- **47** checklist items marked `[x]` in the takeover audit
- **MVVM boundary**: zero `firebase_*` imports under `lib/screens/` or `lib/widgets/`
- **`AsyncViewState<T>` + `BaseViewModel<T>`**: four-state model, rendered by three screens
- **Theme tokens and reusable widgets**: `AppButton`, `AppCard`, `CustomAppBar`, etc.
- **`FirebaseAuthService`**: correct Google credential exchange, cancel-safe, mapped exceptions
- **`FirebaseFirestoreService`** read/write paths: `users/{uid}/…` subcollection layout, `FieldValue.serverTimestamp()`, `Source.serverAndCache`, merge-on-save
- **Security rules**: owner-scoped with default-deny tail; no `if true` anywhere
- **`FirebaseStorageService`**: complete, size-capped download, typed metadata
- **`FirebaseAnalyticsService`** event facade and `_sanitizeParameters` PII guard
- **`CrashlyticsService.initialize`** global handlers
- **`RemoteConfigService`** defaults + settings
- **`MockAuthService`/`MockFirestoreService`/`MockAnalyticsService****: confined to `test/`
- **Docs**: `docs/architecture.md`, `docs/design-traceability.md`, plus design/ux/ai/handoff/assets folders (43 files)
- **54 tests** pass (T03-M11 + analytics + PDF + FCM + SyncReload + NoteModel)
- **`flutter analyze`**: 0 issues across all modifications

---

## 2. Priority Implementation Roadmap

Based on the audit, the following milestones must be resolved in order:

### Phase 2 — Prerequisites (must resolve first)

| Milestone | Task | Dependencies | Why first |
|---|---|---|---|
| **M-01** | Restore resolvable build | B-01 | `dart pub get` must exit 0; `flutter analyze` must report 0 errors; `flutter test` must pass all existing cases. Nothing can be verified, reviewed, or tested until this passes. |
| **M-02** | Bind real Firebase project | B-02, M-01 | Everything in the rubric is unverifiable without a real project configured. `Firebase.initializeApp()` must succeed; `Firebase.apps.isNotEmpty` must be true. |
| **M-03** | Fail loud on init failure | B-04, M-02 | Remove silent mock fallback. When Firebase is unconfigured, show a blocking error screen — never silently fall back to mocks. |
| **M-04** | Release INTERNET + POST_NOTIFICATIONS permission | B-03, M-02 | One-line manifest changes; needed by every network feature and by FCM. Without this, release APK has no network. |
| **M-05** | Derive uid from auth, fail closed when null | B-05, M-04 | Fix S-01. Replace all 6 `user_p02` literals with `AuthService.currentUserId`. Null uid → signed-out state, no writes. |

### Phase 3 — Feature Completion

| Milestone | Task | Dependencies | Acceptance Criteria |
|---|---|---|---|
| **M-06** | Make deletes persist; surface write errors; roll back optimistic updates | M-05, M-01 | Delete removes row from Firestore and local cache; forced write failure shows error and rolls back; `AsyncViewState.error` reached from writes. |
| **M-07** | Wire analytics: `setUserId` on login, `logLoginSuccess`, `navigatorObservers`, move events out of `build`/getters, call interface not concrete class, add `search_course` | M-05 | DebugView shows each of the 8 events with expected parameters; each event fires once per user action; no event fires from `build`. |
| **M-08** | Crashlytics: `setUserIdentifier` + ≥1 `setCustomKey` on login; verify release collection | M-07 | Crashlytics dashboard shows User ID + custom key; non-fatal and forced crash both appear. |
| **M-09** | Remote Config: single instance, externalize defaults, enforce `maintenance_mode` + `min_app_version` | M-07 | Before/after Console changes without rebuild; `remote-config-defaults.json` committed. |
| **M-10** | PDF export: generation from live data → consent → `reports/{uid}/study_report_<ts>.pdf` upload with progress → download URL → Firestore metadata → `export_report` event | M-06, M-07, M-09 | PDF contains displayed data; upload lands at `reports/{uid}/study_report_<ts>.pdf`; progress shown; URL displayed and openable; Firestore metadata doc exists; `export_report` event logged. |
| **M-11** | FCM + Notification Center: token storage, foreground/background/terminated handlers, `notifications` collection + rules, tap routing | M-04, M-05 | Six screenshots (3 states × banner + center) + Firestore `notifications` doc. Notification received in foreground, background, and terminated; tapping opens target screen. |
| **M-12** | Harden storage rules: recursive `notes/` path, PDF-only for `reports/` | M-10 | Uploading `notes/{uid}/a/b.pdf` succeeds; uploading non-PDF `.exe` to `reports/` is denied; anonymous read denied. |
| **M-13** | ARTEMIS: e2e test harness + test plan + 10–14 cases + 3 runs each + traces + exploratory session notes | M-06 through M-12 | `evidence/artemis/` traces, `docs/test-plan.md`. Pass rate table; average duration; flaky investigation notes. |
| **M-14** | AI Code Review: open PR, run reviewer, `docs/code-review.md` with 5 findings, ≥2 categories, each Accepted/Modified/Rejected with reason; 3 independent `fix(CR-0x)` commits | M-13 | Review output; `git log --oneline` with 3 fix commits. |
| **M-15** | Evidence matrix + README Lab 3 + corrected checklist ticks + report/slides/video | M-14 | `evidence/README.md` matrix; PDFs (8–12 pp. report, 12–15 pp. slides); video link in README. Checklist ticks match code reality (correct the 11 incorrect `[x]` ticks from §2.6). |

---

## 3. T03-M11E Fix Verification Status

The T03-M11E legacy task document compatibility fix is **verified and complete**:

| Check | Result |
|---|---|
| `flutter analyze` | ✅ No issues |
| `flutter test test/viewmodels/tasks_notes_test.dart` | ✅ All 14 tests pass |
| `getTasks` `result['id']` = Firestore doc ID (both formats) | ✅ Confirmed |
| `updateTask` on new-format doc | ✅ Succeeds (path matches) |
| `updateTask` on legacy-format doc | ✅ Succeeds (merge into existing doc) |
| `docs/t03-m11e-legacy-task-compatibility.md` | ✅ Created with full documentation |
| No Firestore Rules changes | ✅ Untouched |
| No document deletions/migrations | ✅ Local changes only |
| No git staging/commit/push | ✅ Local changes only |

**Files modified:**
- `lib/services/firebase_firestore_service.dart:108-111` — `getTasks`: `..addAll(data)` → `..addAll(data..remove('id'))` to prevent `data['id']` from overwriting canonical `id`
- `docs/t03-m11e-legacy-task-compatibility.md` — Full backward-compatibility documentation

---

## 4. Current verification state and next steps

### Local code evidence

- `flutter pub get` — PASS.
- `flutter analyze` — PASS, 0 issues.
- `flutter test` — PASS, **54 tests** (thêm NoteModel Timestamp + SyncReloadService).
- `flutter build apk --debug` — PASS.
- UID propagation, rollback, PDF export, analytics, FCM token/notification wiring, and truthful three-store reload outcomes — covered by source and hermetic tests.
- Firestore and Storage rules are owner-scoped/default-deny in local files.
- `NoteModel.fromMap` handles Firestore `Timestamp`, `DateTime`, and legacy `String` for `updatedAt`.

### Runtime evidence (emulator, 2026-11-02)

- **Google Sign-In**: PASS — authentication thành công, điều hướng HomeScreen.
- **Roadmap Firestore read**: PASS — courses hiển thị từ `courses` collection; `passedCourses` hoạt động.
- **Manual sync (SyncReloadService)**: PASS — reload 3 store thành công sau sửa NoteModel Timestamp.
- **Task CRUD**: PASS — tạo, toggle `isCompleted`, xóa — đều ghi/cập nhật/xóa trên Firestore.
- **Note CRUD**: PASS — tạo, đọc — ghi đúng `users/{uid}/notes/{noteId}`.
- **Delete**: PASS — hai bản ghi test đã xóa thành công.

### External verification still required

1. FCM delivery: foreground, background, terminated — chưa xác minh. Tap routing chưa test.
2. Analytics DebugView: chưa kiểm tra event delivery trên Console.
3. Crashlytics: chưa test non-fatal hoặc kiểm tra dashboard.
4. Remote Config: `firebase/remote-config-defaults.json` tồn tại; chưa test Console before/after.
5. Storage bucket: chưa xác minh provisioning. Spark plan có thể chặn.
6. Firestore Rules deployment: đã deploy trước đó (71-line, documented in t03-m7). Cần recheck trên Console.
7. PDF export runtime: cần Storage bucket hoạt động.
8. Offline/reconnect behavior: chưa test.

### Blockers

- **Storage**: Spark plan có thể chặn bucket provisioning. Không nâng billing nếu chưa có quyết định nhóm.
- **S-10**: Email `@fpt.edu.vn` enforcement: UI label nói nhưng không gate. Client/rules đều không check domain.
- **S-12**: Application ID `com.example.prm323_lab3` chưa khớp rubric `PRM393_Lab03_<StudentID>`.
- **AI review**: `docs/code-review.md` cần review output thật và Git history. Không bịa.
- **Evidence**: ARTEMIS traces, screenshots, report PDF, slide PDF, demo video cần bằng chứng thật.

No Git staging, commit, push, pull, reset, deployment, or cloud data mutation was performed by this pass.