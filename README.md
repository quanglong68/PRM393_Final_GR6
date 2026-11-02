# FPTU Second Brain — PRM393 Lab 3 (Cloud-Enabled Mobile App)

Ứng dụng Android Flutter (PRM323 Lab 2 → Lab 3): tra cứu chương trình/đề cương,
quản lý deadline, ghi chú + attachment, tư vấn học vụ, **đồng bộ Firestore
offline-first**, Google Sign-In, FCM + Notification Center, Analytics/Crashlytics/
Remote Config, và **xuất PDF báo cáo học tập** (kèm consent) lên Cloud Storage.
Kiến trúc fail-loud: Firebase lỗi là báo lỗi thật, không fallback mock im lặng.

## Build · Run · Test

```bash
flutter pub get
flutter analyze          # 0 issues
flutter test             # 51/51 (unit/widget, hermetic mocks)
flutter build apk --release
```

| Hạng mục Lab 3 | Vị trí |
| --- | --- |
| Task map + plan A–G | [docs/lab3-task-map-v5.md](docs/lab3-task-map-v5.md) |
| Kiến trúc | [docs/architecture.md](docs/architecture.md) |
| Test plan (ma trận TC ↔ flow, living doc) | [docs/test-plan.md](docs/test-plan.md) |
| Báo cáo runtime T03-M1…M11E | [docs/](docs/) |
| Security rules + seed + RC defaults | [firebase/](firebase/) |
| AI code log (policy) | [ai/ai-code-log.md](ai/ai-code-log.md) |
| Evidence (Firebase/ARTEMIS/review/report) | [evidence/](evidence/) — chưa chụp, theo plan |

ARTEMIS (E2E on-device): Python ≥3.12, `uv sync`, `adb devices`, API key đặt
trong `.env` (không commit) — harness `e2e_test/` dựng ở Phase E.

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
