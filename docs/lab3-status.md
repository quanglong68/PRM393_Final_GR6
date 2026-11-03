# PRM393 Lab 3 — Trạng thái task (đã xong / còn nợ)

> **Cập nhật:** 2026-11-03 (rev 3) · baseline HEAD `3b10599` + working tree 03/11.
> Rev 2 đã được commit (`3b10599`). Rev 3 thêm: harness đổi tên theo checklist §8.3 và
> nâng **16 → 26 cases**, mapping TC-01..14 ↔ file::test (`docs/test-plan.md` §1b), cây
> `evidence/` đủ §10.1 + README, `.gitignore` Python block, README 3 mục mới,
> `LAB3_CHECKLIST.md` re-tick theo thực tế, draft G2/G3 (`docs/lab3-report-outline.md`,
> `docs/lab3-slides-outline.md`, `docs/lab3-video-script.md`).
> Code mới pull (`261e6dc`) thêm: FPT-domain gate (S-10), NoteModel parse Timestamp,
> SyncReloadService, **seed catalog đã xác minh trên device** — xem
> `docs/lab3-completion-progress.md` + `docs/lab3-final-requirement-audit.md`.
> Nguồn chéo: `docs/lab3-task-map-v5.md` (plan A–G) · `docs/test-plan.md` (TC-*) ·
> git log · `docs/t03-m*` · `flutter analyze` (0 issues) / `flutter test` (**54/54**).
> File này là snapshot; cập nhật lại mỗi khi xong một mục.

---

## ✅ ĐÃ XONG

### Phase A — Mở khoá + Persistence runtime
| Mục | Bằng chứng | Commit / file |
|---|---|---|
| Firebase project, SHA-1, `google-services.json`, Google Sign-In (M1) | device verify | `d977c00`, `107a69f` |
| Rules owner-based + `storage.rules` path recursive `notes/{uid}/{allPaths=**}` (A2) | audit M7 code-confirmed | `firebase/firestore.rules`, `firebase/storage.rules` |
| Rules + Storage deploy (M2 — từng BLOCKED) | audit M10 xác nhận deployed rules khớp repo (71 dòng) | console `prm323-lab2-gr6` |
| Fix canonical task ID legacy + new format (M11D/E) | commit + docs | `decae72`, `docs/t03-m11d/e` |
| Root-cause update-task failure | phân tích M11B | `docs/t03-m11b` |

### Phase B — Hardening
| Mục | Bằng chứng | Commit / file |
|---|---|---|
| `INTERNET` + `POST_NOTIFICATIONS` manifest (B1/T05) | grep manifest | `android/app/src/main/AndroidManifest.xml` |
| Bỏ mọi mock fallback — fail-loud (`FirebaseConfigErrorApp` chặn màn hình) (B2/T04) | audit M10 code-confirmed | `2116eaa` |
| Xóa no-op ternary, thống nhất 1 instance Crashlytics/RC (B3, S-08) | diff commit | `2116eaa` |

### Phase C — Instrumentation (code)
| Mục | Bằng chứng | Commit / file |
|---|---|---|
| Analytics `setUserId`/`logLoginSuccess`/navigatorObservers, events 1 lần/action, `search_course` (C1/T08, S-07) | test suite pass | `2116eaa`, `e0c772d`, `test/services/analytics_wiring_test.dart` |
| Crashlytics `setUserIdentifier` + `setCustomKey` (C2/T09) | diff | `2116eaa`, `lib/services/crashlytics_service.dart` |
| Remote Config defaults + enforce `maintenance_mode`/`min_app_version` (C2/T10) | file có sẵn | `firebase/remote-config-defaults.json` |
| PII filter trong analytics | audit | `lib/services/firebase_analytics_service.dart` |

### Phase D — Features lớn
| Mục | Bằng chứng | Commit / file |
|---|---|---|
| PDF export: picker → generate data thật → **consent dialog** → upload progress `reports/{uid}/` → metadata → event `export_report` (D1/T11) | `sync_vault_screen.dart:134` consent + test pass | `2116eaa`, `lib/services/report_export_service.dart`, `test/services/report_export_service_test.dart` |
| FCM: token store + handlers 3 trạng thái + tap routing + Notification Center + rules `notifications` (D2/T12) | test pass | `d1ca8c1`, `lib/services/firebase_messaging_service.dart`, `lib/screens/notifications_screen.dart`, `test/viewmodels/notifications_test.dart` |
| Advisor retry + task edit UI + attachment upload thật (D3/F-05/F-07) | diff | `89405be` |
| Drop persona data / domain label khỏi UI (data minimization) | diff | `5be1db4`, `89405be` |

### Test + nền tảng tài liệu
| Mục | Bằng chứng |
|---|---|
| Unit/widget/model suite xanh **54/54** | `flutter test` 03/11 trên `261e6dc` |
| **Runtime device 02/11**: sign-in, Roadmap read sau seed, Task create/toggle, Note create/delete, manual sync | `docs/lab3-completion-progress.md` (commit `261e6dc`) |
| FPT-domain gate S-10 (`hostedDomain` + check server-side, sign-out if ngoại domain) | `261e6dc` `firebase_auth_service.dart` |
| **ARTEMIS harness 26 cases** (rev 3: đổi tên file theo checklist §8.3 + thêm TC-05/13/14) — code-side xong (E2): 3 flows + TC-V1/V5 + error branch × dịch vụ + native ADB + exploratory. CHƯA chạy (chờ E1) | `e2e_test/` 03/11, mapping §1b test-plan |
| `docs/firestore-catalog-seed.md` · `docs/analytics-plan.md` · `docs/lab3-final-requirement-audit.md` | `261e6dc` |
| Repair test sau merge (FakeFirestoreService, imports, contracts) | `d41eb74`, `90554bb`, `docs/pre-push-repair.md` VERDICT READY |
| Gỡ debug capture blocks M11C (nợ trước code freeze) | commit `dae9ad9` |
| `docs/test-plan.md` living doc — dọn conflict markers stash, cập nhật verify 02/11, thêm nhóm TC-S | 03/11 |
| `ai/ai-code-log.md` — policy, 12 phiên (F4) | commit `dae9ad9` + rev 3 |
| `evidence/` cây đủ §10.1 (app/ firebase×7/ artemis/logs/ code-review/ figma/ report/ video/) + README naming | `evidence/` 03/11 (rev 3) |
| Draft G2/G3: outline report 8–12tr, slides 12–15tr, kịch bản video 7′30″ (chỗ chờ evidence đánh dấu ⏳, không bịa) | `docs/lab3-{report,slides}-outline.md`, `docs/lab3-video-script.md` 03/11 |
| `LAB3_CHECKLIST.md` re-tick theo thực tế + §14/§15 (DEC-01..05, BUG-01/02) | `LAB3_REPORTS/` 03/11 |
| README draft Lab 3: build/run/test + bảng link tài liệu (G4 một phần) | commit `dae9ad9` |
| Audit banner T03-M8 ↔ M10 (M10 recommend #5) | commit `dae9ad9` |

---

## ❌ CÒN NỢ

### N-1 · Runtime verify TC-V (đóng nợ audit M10 — **làm trước tiên**)
| ID | Nợ gì | Ai |
|---|---|---|
| ~~N-1.1~~ | ~~Seed catalog~~ ✅ DONE 02/11 (Roadmap đọc `courses` + `passedCourses` — `lab3-completion-progress.md`) | — |
| N-1.2 | TC-V1: **UPDATE task có sẵn** + verify Console + log sạch — phần còn lại của nợ M11E (create/toggle mới pass) | Bạn + em |
| N-1.3 | TC-V2: offline persistence cycle (toggle wifi) — M10 NOT TESTED | Bạn (hoặc ARTEMIS TC-F3-02 sau E1) |
| N-1.4 | TC-V3: Note **attachment nested path** — create/delete note đã pass 02/11 | Bạn |
| N-1.5 | TC-V5: capture `adb logcat` — M10 NOT TESTED | Bạn/em (hoặc ARTEMIS TC-V5 sau E1) |
| N-1.6 | TC-V6: cross-account UID isolation — **cần Google account 2**; account phụ nên @fpt.edu.vn để test S-10 | Bạn |
| N-1.7 | Re-run T03-M8 full pass với ADB + nâng verify 02/11 lên **3 runs + ảnh** (guide tr.23) | sau N-1.2..5 |

### N-2 · Evidence batch Firebase (chụp 1 lần khi app chạy — guide §4.4/§9.2)
DebugView ≥7 events × ≥2 params · Crashlytics test crash · RC before/after ·
FCM 3 trạng thái + tap · PDF consent→progress→metadata · `evidence/firebase/` naming `SCR-/TC-`.

### N-3 · Phase E — ARTEMIS
| ID | Nợ gì |
|---|---|
| E1 | **Setup (Bạn)**: cài `uv`, clone+`./start.sh` google/artemis host, điền `e2e_test/.env` (GEMINI_API_KEY…), `uv sync`, emulator chạy — xem `e2e_test/README.md` |
| ~~E2~~ | ✅ Harness 16 cases đã dựng (`e2e_test/` 03/11) — API client có thể phải chỉnh theo README repo artemis bản bạn cài |
| E3 | 3 runs/test, bảng pass rate + avg duration vào `test-plan.md` §3, điều tra flaky |
| E4 | Exploratory 15–30′ + AI summary → `evidence/artemis/exploratory-summary.md` |
| — | Chụp `FLW-01..03` (3 flows) trên device → `evidence/artemis/` |
| — | **Storage bucket**: verify provisioning trên Console; nếu Spark chặn → quyết định nhóm (blocker PDF upload + attachment, rubric tr.25) |

### N-4 · Phase F — AI Code Review (cần code freeze + TC-V sạch)
| ID | Nợ gì |
|---|---|
| F1 | Push branch → mở PR → bật CodeRabbit/Copilot — **Bạn** (quyền repo) |
| F2 | `docs/code-review.md`: ≥5 findings `file:line` + severity + decisions + bảng decisions |
| F3 | 3 commit `fix(CR-01..03)` độc lập, **không squash** |
| — | Điền decision phiên S-10 vào `ai/ai-code-log.md` khi bạn review diff |

### N-5 · Phase G — Đóng gói & nộp
| ID | Nợ gì |
|---|---|
| G2 | Report PDF 8–12 tr — **outline xong** `docs/lab3-report-outline.md`; chờ ⏳ evidence để viết bản đầy đủ |
| G3 | Slides 12–15 tr — **outline xong** `docs/lab3-slides-outline.md`; **kịch bản video 7′30″ xong** `docs/lab3-video-script.md`; bản final chờ evidence + quay |
| G4 | README: bổ link video + mô tả evidence khi có (draft + 3 mục mới 03/11) |
| G5 | Checklist tự đánh giá 12 dòng guide §10 + re-tick `LAB3_CHECKLIST.md` — ✅ **rev re-tick 03/11** (theo thực tế, ⏳ đánh dấu rõ) |
| G6 | Cắt `google-services.json`/project number khỏi mọi screenshot (§9.3) + **quyết định rename repo** `PRM393_Lab03_<StudentID>` (S-12) |

### N-0 · Việc hành chính luôn treo
- **Commit** working tree hiện tại: 4 file sửa (`README.md`, `docs/t03-m8…`, 2 file lib) + 4 untracked (`ai/ai-code-log.md`, `docs/test-plan.md`, `docs/lab3-task-map-v5.md`, `evidence/`) — bạn tự commit theo rule repo.

---

## Tổng quan tiến độ

```
A ██████████ 98%  (seed ✅ 02/11; còn UPDATE-task + offline verify)
B ██████████ 100%
C ████████░░ 80%  (code xong, còn evidence DebugView/Crash/RC)
D ██████████ 95%  (code xong, còn verify FCM/PDF/attachment trên device)
E ██████░░░░ 60%  (plan + harness 26 cases xong; còn E1 setup → chạy 3 runs + exploratory)
F ░░░░░░░░░░ 0%   (chờ code freeze; docs/code-review.md chưa có — rubric F-10)
G ████░░░░░░ 40%  (evidence tree §10.1, README, checklist re-tick, outline report/slides + script video; còn bản final + rename)
```
**≈ 70% tổng plan** (rev 3). Blocker lớn nhất bây giờ là **E1 setup + Console/device
thuộc bạn**; sau E1 thì ARTEMIS tự chạy phần lớn N-1. Quyền repo (PR/rename) cũng thuộc bạn.
