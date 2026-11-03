# AI Code Log — PRM393 Lab 3

> Policy guide v5 §Policy: mọi phiên dùng AI tool để sinh/sửa code phải được ghi
> lại với **tool · model · mục đích prompt · kết quả · decision** (đồng ý/sửa/từ chối).
> Tài liệu này tách với `ai-design-log.md` (Lab 2 — thiết kế UX bằng Google Stitch).
>
> Các mục 2026-10-29 → 2026-11-01 được **tái dựng từ git history và các report
> `docs/t03-*.md`** (log chỉ bắt đầu ghi trực tiếp từ phiên 2026-11-02). Độ chính
> xác từng prompt đơn lẻ không tuyệt đối; mức tool/model lấy từ metadata phiên.

## 1. Format mỗi mục

| Trường | Nội dung |
|---|---|
| Ngày · Phiên | ID phiên làm việc |
| Tool · Model | AI tool và model đã dùng |
| Prompt (mục đích) | Yêu cầu giao cho AI, tóm tắt |
| Output | Code/tài liệu AI sinh ra (file, commit) |
| Human decision | Accepted / Modified / Rejected + ghi chú review |

## 2. Log các phiên Lab 3

| # | Ngày · Phiên | Tool · Model | Prompt (mục đích) | Output | Human decision |
|---|---|---|---|---|---|
| 1 | 2026-10-29 · S-01 | Claude Code | Bám sát Lab 3 PDF: audit repo Lab 2, lập roadmap T01–T16, phát hiện mock fallback/thiếu Firebase wiring | `docs/lab3-takeover-audit.md` (commit `d977c00`→`107a69f` vùng) | **Accepted** — roadmap làm nền cho task map v5 |
| 2 | 2026-10-29 · S-02 | Claude Code | T01: dựng lại build Flutter + tích hợp `google-services.json`, Google Sign-In thật | `lib/services/firebase_auth_service.dart`, `lib/screens/sign_in_screen.dart`; commit `d977c00`, `107a69f` | **Accepted** sau verify `flutter analyze`/`test` |
| 3 | 2026-10-30 · S-03 | Claude Code | T02–T03: harden persistence (Source.serverAndCache), rules owner-based, tài liệu hoá M1–M3 | `firebase/firestore.rules`, `firebase/storage.rules`, docs `t03-m1…m3` | **Accepted**; rules deploy phải chạy tay (M2) |
| 4 | 2026-10-31 · S-04 | Claude Code | Đối chiếu guide v5 ↔ roadmap, sinh task map tối ưu 7 phase A–G | `docs/lab3-task-map-v5.md` (đã commit `dae9ad9`) | **Accepted** — plan hiện hành |
| 5 | 2026-11-01 · S-05 | Claude Code | T04–T11: bỏ mock fallback (fail-loud), wire analytics/crashlytics/RC, PDF export pipeline, remote-config defaults | commits `2116eaa`, `27b39a5`; `lib/services/report_export_service.dart`, `firebase/remote-config-defaults.json` | **Accepted** — 19 file, review theo module |
| 6 | 2026-11-01 · S-06 | Claude Code | T12: FCM device tokens + Notification Center + handlers 3 trạng thái + rules `notifications` | commit `d1ca8c1`, `lib/services/firebase_messaging_service.dart`, `lib/screens/notifications_screen.dart` | **Accepted** |
| 7 | 2026-11-01 · S-07 | Claude Code | T03-M8 runtime verify trên emulator → lỗi update task; điều tra root cause (M11B/C) | docs `t03-m8`, `t03-m11b/c`; debug capture blocks (tạm thời) | **Accepted** phân tích; capture blocks là nợ kỹ thuật → gỡ ở S-10 |
| 8 | 2026-11-01 · S-08 | Claude Code | M11D/M11E: root cause legacy doc-ID (map spread ghi đè `id`), fix canonical ID + `legacyId` | commit `decae72`; `firebase_firestore_service.dart:108-111`; docs m11d/e | **Accepted** — 14/14 test suite task pass |
| 9 | 2026-11-02 · S-09 | Claude Code | Quét tồn đọng sau pull: đối chiếu task map v5 ↔ git log ↔ docs, lập danh sách việc còn | Báo cáo trong phiên chat; không sinh file | **Accepted** |
| 10 | 2026-11-02 · S-10 | Claude Code · claude-dev2 | "Làm tiếp phần không cần thiết bị; báo cáo phần cần user": gỡ debug block M11C, audit banner M8, tạo ai-code-log, test-plan, evidence skeleton, README draft | `lib/viewmodels/tasks_viewmodel.dart`, `lib/services/firebase_firestore_service.dart`, `docs/t03-m8…`, `ai/ai-code-log.md`, `docs/test-plan.md`, `evidence/`, `README.md` | **Accepted** — user commit toàn bộ qua `dae9ad9` (02/11) |
| 11 | 2026-11-03 · S-11 | Claude Code · claude-dev2 | Tiếp sau pull `261e6dc`: dựng ARTEMIS harness (`e2e_test/` 16 cases + conftest ADB/logcat/screencap), dọn conflict markers stash trong test-plan và gộp bản của nhóm, thêm nhóm TC-S, cập nhật lab3-status theo verify 02/11 | `e2e_test/*` (mới), `docs/test-plan.md`, `docs/lab3-status.md`, `ai/ai-code-log.md` | **Accepted** — user commit qua `8a75d15` + `3b10599` (03/11) |
| 12 | 2026-11-03 · S-12 | Claude Code · claude-dev2 | "Tiếp tục các task đi" (không cần device): đổi tên file harness theo checklist §8.3 + nâng 16→26 cases (TC-05/13/14, mapping §1b); cây evidence §10.1 + README; `.gitignore` khối Python + negation `.env.example`; README mục Cấu hình Firebase/AI tools/Known issues; re-tick `LAB3_CHECKLIST.md` theo thực tế (G5); draft outline report/slides + kịch bản video (G2/G3, mọi chỗ runtime đánh dấu ⏳ không bịa) | `e2e_test/*` (rename+append), `docs/test-plan.md` §1b, `evidence/**`, `.gitignore`, `README.md`, `LAB3_REPORTS/LAB3_CHECKLIST.md`, `docs/lab3-report-outline.md`, `docs/lab3-slides-outline.md`, `docs/lab3-video-script.md`, `docs/lab3-status.md` rev 3 | **Đang ghi — decision khi user review** |
| 13 | 2026-11-03 · S-13 | Claude Code · claude-dev2 | "Còn task nào tiếp tục đi" — xóa 4 nợ checklist tự động được: Semantics/tooltip cho interactive widgets; logout rebuild-list guard uid-change trong Tasks/Notes/Roadmap VM (+2 test); events 12–13 strategy wire qua AdvisorViewModel (+3 test, analytics-plan 13 dòng); phát hiện firebase_analytics 13.0.1 BỎ enableDebugMode() → revert code, chuyển adb setprop vào README; notes reserved `curriculums`; tự đánh giá rubric 13 dòng `docs/lab3-self-assessment.md`. Suite 54→**59/59**, analyze 0 | `lib/{widgets,services,viewmodels,screens}/…`, `test/viewmodels/tasks_notes_test.dart`, `test/services/analytics_wiring_test.dart`, `docs/analytics-plan.md`, `docs/firestore-catalog-seed.md`, `docs/lab3-self-assessment.md`, README, checklist §6.4/6.5/7.1 + DEC-06/07/BUG-03 | **Đang ghi — decision khi user review** |

## 3. Nguyên tắc áp dụng từ nay

1. Mỗi phiên AI sửa code Lab 3 thêm 1 dòng vào bảng §2 (tool · model · output · decision).
2. AI không tự commit/push (quy tắc repo); output luôn qua `flutter analyze` + `flutter test` trước khi ghi **Accepted**.
3. Prompt chứa dữ liệu cá nhân/email thật phải được ghi là *masked* — không lưu credential vào log.
4. Khi mở PR (Phase F), các fix commit `fix(CR-0x)` do AI đề xuất phải ghi cả decision Accepted/Modified/Rejected tương ứng (`docs/code-review.md` là nguồn chéo).
