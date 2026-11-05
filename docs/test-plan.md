# PRM393 Lab 3 — Test Plan and Evidence Status

Updated: 2026-11-03. This document separates Flutter automated tests, emulator observations, and tests still not run. A planned case is not evidence of a pass.

## Automated Flutter checks

| Check | Last observed result | Notes |
|---|---|---|
| `flutter analyze` | PASS, 0 issues (2026-11-04) | Source/static analysis only |
| `flutter test` | PASS, 89 tests (2026-11-04) | Hermetic unit/widget tests; not ARTEMIS E2E runs |
| `flutter build apk --debug` | PASS (2026-11-04) | Built build\app\outputs\flutter-apk\app-debug.apk |

Automated coverage includes UID propagation, task/note write rollback and persistence calls, NoteModel Firestore Timestamp parsing, manual sync outcomes, analytics wiring, report export service, and FCM token/notification logic. These tests do not prove Firebase Console delivery or deployed Rules behavior.

## Runtime observations on emulator (2026-11-02)

| Area | Observed result | Limit |
|---|---|---|
| Google Sign-In | Signed in and reached HomeScreen | Non-`@fpt.edu.vn` rejection branch not tested |
| Firebase/Firestore | Read catalog and user data from project `prm323-lab2-gr6` | `google-services.json` is out-of-band and gitignored |
| Roadmap | Courses and `passedCourses` prerequisite state loaded | Emulator observation only |
| Task | Created test task; toggle updated Firestore `isCompleted` | Test document was later deleted from Console; app delete path not separately runtime-verified |
| Note | Created and read a note; Timestamp parsing worked after reload | Test document was later deleted from Console; app delete path not separately runtime-verified |
| Manual sync | Roadmap, Tasks, Notes reloaded successfully after Timestamp fix | Read failure behavior is covered by hermetic regression tests |

## ARTEMIS E2E cases — planned, not run

The rubric requires at least 10 ARTEMIS cases, each run three times. The harness exists at `e2e_test/` (26 cases collect cleanly after two import defects were fixed), but **no case has been executed**: the ARTEMIS host and `emulator-5554` are ready, while the Gemini free-tier daily quota is exhausted (HTTP 429, resets in ~14 h). See `evidence/artemis/RUN_LOG_2026-11-04.md`. The table below stays a test plan; run columns remain blank until captured from ARTEMIS on a device.

| ID | Scenario | Expected result | Runs |
|---|---|---|---|
| TC-01 | Valid Google Sign-In | Authenticated user reaches Home | Not run |
| TC-02 | Sign in with non-FPT Google account | Sign-in is rejected and session is cleared | Not run |
| TC-03 | Load Roadmap catalog | Firestore courses appear; prerequisites reflect `passedCourses` | Not run |
| TC-04 | Search courses | Results match entered course code/name | Not run |
| TC-05 | Manual sync success | Roadmap, Tasks, Notes reload; success shown only after all stores finish | Not run |
| TC-06 | Manual sync read failure | Error identifies failing store; no success claim/event | Not run |
| TC-07 | Create and toggle Task | Task persists; `isCompleted` survives reload | Not run |
| TC-08 | Edit and delete Task | Firestore changes match UI; failures surface and roll back | Not run |
| TC-09 | Create, edit, and delete Note | Firestore document matches UI after reload | Not run |
| TC-10 | Offline edit then reconnect | Error/rollback is truthful; successful changes sync after reconnect | Not run |
| TC-11 | FCM foreground/background/terminated | Notification is persisted once; tap routes to intended screen | Not run |
| TC-12 | Attachment and report upload | Consent, progress, Storage object, URL and metadata are correct | Not run; requires Storage bucket |
| TC-13 | Analytics, Crashlytics, Remote Config | Required event/dashboard/config evidence is visible in Firebase Console | Not run |

For each case, record three independent runs, duration, result, device/emulator version, and trace/screenshot under `evidence/artemis/`. Do not fill a run as PASS from source code or Flutter unit tests.

## Firebase/Console checks still pending

| Area | Required evidence | Status |
|---|---|---|
| Firestore Rules | Current deployed Rules view in Console | Recheck needed |
| FCM | Foreground, background, terminated delivery and tap routing | Not verified |
| Analytics | DebugView events and expected parameters/counts | Not verified |
| Crashlytics | Non-fatal test visible in dashboard | Not verified |
| Remote Config | Before/after value change observed in app | Not verified |
| Storage/PDF | Bucket availability, attachment and report upload | Not verified |
| Offline/reconnect | Device observations and stored traces | Not verified |

Do not deploy Rules, modify Remote Config, upgrade billing, or upload personal files as part of this plan without explicit authorization. Check whether Storage is provisioned before treating Spark as a blocker.
