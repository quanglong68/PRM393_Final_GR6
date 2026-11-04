# PRM393 Lab 3 — Project Report Draft

> **Draft only.** Replace the Student ID field, attach genuine runtime evidence, and export to `Lab03_<StudentID>.pdf` only after the missing checks below are completed. Do not submit this draft as final.

**Student ID:** `[NEEDS STUDENT ID]`  
**Project:** FPTU Second Brain  
**Repository:** `prm323-lab2-gr6` (rubric requires renaming to `PRM393_Lab03_<StudentID>` at submission)  
**Android application ID:** `com.example.prm323_lab3`  
**Technology:** Flutter/Dart, Firebase  
**Report date:** 2026-11-03

## 1. Project overview

FPTU Second Brain is a Flutter study-planning app. It provides Google sign-in, a course roadmap, task and note management, study advice, notifications, Firebase telemetry/configuration, and PDF report export. User-owned Firestore data is scoped below `users/{uid}`. The code uses an MVVM structure with services injected into ViewModels.

The app is derived from a Lab 2 design project. The current implementation and test evidence are documented in [the final requirement audit](../docs/lab3-final-requirement-audit.md), [completion progress](../docs/lab3-completion-progress.md), and [architecture overview](../docs/architecture.md).

## 2. Architecture

The app separates screens, ViewModels, services, models, and theme/widgets. `AsyncViewState<T>` represents loading, empty, error, and data states. Authentication supplies the Firebase UID to user-owned ViewModels; unauthenticated writes fail closed. Production startup displays a configuration error state if Firebase initialization fails rather than silently using test doubles.

The Firestore catalog is read from `courses`. Personal tasks and notes use `users/{uid}/tasks` and `users/{uid}/notes`. Cloud Storage services support note attachments and report uploads in code; runtime upload evidence is still pending. Firebase Messaging handlers, token persistence, notification storage, Analytics, Crashlytics, and Remote Config are implemented in source, with Console/device verification still needed for several services.

**Evidence to add:** architecture diagram and one sequence diagram for sign-in → authenticated Firestore read.

## 3. Implemented study flows

### 3.1 Course roadmap

The Roadmap reads course documents from Firestore, filters/searches courses, and checks prerequisites against the signed-in user's `passedCourses`. On the emulator, courses loaded and prerequisite status changed after the profile data was refreshed.

### 3.2 Tasks and notes

Tasks support create/edit/complete/delete paths in code with authenticated ownership and optimistic rollback on write failure. Runtime testing created a Task and confirmed its completion state in Firestore. Notes support create/read/update/delete paths in code. Runtime testing created and read a Note; a Firestore Timestamp parsing defect was found and fixed in `NoteModel.fromMap`. A manual sync subsequently reloaded Roadmap, Tasks, and Notes successfully. The two disposable test documents were deleted from Firebase Console after testing.

### 3.3 Authentication and Firebase controls

Google Sign-In succeeded on the emulator and reached HomeScreen. Source now filters the Google account picker to `fpt.edu.vn` and rejects a signed-in account whose email does not match that domain. The rejection branch has not yet been exercised on a device.

## 4. Verification results

Last recorded local checks, on 2026-11-02:

| Check | Result | Scope |
|---|---|---|
| `flutter analyze` | PASS, 0 issues | Static analysis |
| `flutter test` | PASS, 54 tests | Unit/widget tests with hermetic fakes; not ARTEMIS E2E |
| `flutter build apk --debug` | PASS | Used the ignored, out-of-band `google-services.json` |
| Google Sign-In | PASS on emulator | Reached HomeScreen |
| Roadmap / Firestore | PASS on emulator | Catalog and `passedCourses` observed |
| Task create/toggle | PASS on emulator | Firestore record and `isCompleted` observed |
| Note create/read | PASS on emulator | Firestore record observed; Timestamp reload fixed |
| Manual sync | PASS on emulator | All three stores reloaded successfully |

**Evidence placeholders:** attach screenshots/logs for each runtime row with device/emulator model and capture date. Do not substitute source code or unit tests for runtime evidence.

## 5. Security and privacy

Firestore rules in the repository scope user-owned collections to the authenticated UID and end in default deny. This local file does not prove which Rules version is currently deployed; recheck Firebase Console and attach evidence. The ignored Android Firebase config must remain out of Git and must not appear in screenshots.

Google Sign-In's `hostedDomain` value is a picker filter; the code also checks the returned email after credential exchange. Runtime rejection of a non-FPT account remains unverified. PDF export includes a consent step before upload; Storage bucket availability and real upload behavior remain unverified.

## 6. Test strategy

Flutter unit/widget tests cover ViewModel behavior, UID propagation, rollback, NoteModel timestamp conversion, Analytics wiring, PDF export service behavior, FCM token/notification logic, and sync reload outcomes. The complete output is 54 tests passing as last recorded.

The Lab 3 checklist separately requires at least 10 ARTEMIS E2E cases, three runs each, plus traces and an exploratory session. The repository currently contains a manual test plan but no ARTEMIS harness or run traces. Those results must be generated on a configured device and recorded truthfully.

## 7. Unverified runtime items

- FCM delivery in foreground, background, and terminated states, including tap routing.
- Analytics DebugView events and exact counts.
- Crashlytics non-fatal event visible in the dashboard.
- Remote Config before/after behavior after a Console value change.
- Storage bucket availability, note attachment upload, PDF upload, URL, and metadata.
- Current Firestore Rules deployment state.
- Offline/reconnect behavior.
- Runtime rejection of a non-`@fpt.edu.vn` account.

Do not upgrade billing, deploy Rules, change Remote Config, or mutate cloud data without the team's approval. Check the current Storage bucket before calling Spark a blocker.

## 8. Submission deliverables still needed

- Student ID and final public repository rename to `PRM393_Lab03_<StudentID>` at submission.
- At least 10 ARTEMIS cases × 3 real runs, traces, pass-rate/duration table, and exploratory notes.
- Genuine AI review output with at least five findings and three separately committed fixes, as specified by the checklist. This draft does not invent findings or commits.
- Evidence screenshots for Firebase Console/device checks.
- Final 8–12 page report PDF, 12–15 page slide PDF, and 5–10 minute demo video.

