> **Bổ sung 05/11/2026.** [Web admin đọc Crashlytics](firebase/crashlytics/admin-web-live-2026-11-05.json), [FCM server validate_only](firebase/fcm/server-http-v1-validation-2026-11-05.json), [APK và consent Cloudinary](app/admin-media-2026-11-05/verification.json), [ARTEMIS TC_11 trên emulator](artemis/results-20261105T103204181722Z.md). Kiểm thử máy thật và upload Cloudinary thật còn chờ môi trường.

> Ngày 05/11/2026, người dùng chọn giữ Spark. Báo cáo PDF dùng luồng tạo trên thiết bị và menu chia sẻ Android. Tiêu chí upload Storage và metadata cloud còn thiếu.

# Evidence — PRM393 Lab 3

## Bằng chứng đã xác minh

- [Tạo và chia sẻ PDF cục bộ](app/local-pdf-2026-11-04/verification.json)
- [Remote Config 31 → 30 trên cùng APK](firebase/remote-config/same-apk-2026-11-04.json)
- [FCM mở đúng môn học khi khởi động từ notification](firebase/fcm/deep-link-persistence-2026-11-04.json)
- [Crashlytics test crash](firebase/crashlytics/dashboard-native-crash-2026-11-04.png) và [non-fatal](firebase/crashlytics/dashboard-nonfatal-2026-11-04.png)
- [Analytics DebugView cho event tạo PDF](firebase/analytics/debugview-export-parameters-2026-11-04.png). Đối chiếu các event còn lại theo tracking plan.


Cấu trúc theo checklist §10.1. Naming guide v5: `SCR-` (màn hình), `FLW-` (flow),
`TC-` (test case), kèm ngày `YYYY-MM-DD` trong tên file hoặc caption.
**Không** đưa `google-services.json`, API key, project number, email thật vào
screenshot/log (guide §9.3) — che trước khi lưu.

| Thư mục | Nội dung | Nguồn |
|---|---|---|
| `app/` | SCR- ảnh 11 màn hình thật trên device | checklist §6.1 |
| `firebase/auth/` | Sign-in success, Auth user Console, domain-gate reject | TC-01, TC-S-01 |
| `firebase/firestore/` | rules deployed, docs users/{uid}/…, seed catalog | TC-V1..V4 |
| `firebase/storage/` | reports/{uid}/ PDF object + download URL, attachment | TC-10, TC-F3-03 |
| `firebase/analytics/` | DebugView ≥7 events × ≥2 params | TC-14, TC-X-03 |
| `firebase/crashlytics/` | non-fatal + test crash, User ID + custom key | TC-X-05 |
| `firebase/remote-config/` | before/after Console, giá trị Demo Area | TC-11, TC-X-04 |
| `firebase/fcm/` | 3 trạng thái × (banner + center) = 6 ảnh + notifications doc | TC-13, TC-X-06 |
| `artemis/` | `TC-*_<run>.png`, `logs/*.log` (pass rate + trace ID), `exploratory-summary.md`, `FLW-01..03` | Phase E |
| `code-review/` | PR URL, output reviewer, ảnh findings CR-01..n + fix commits | Phase F |
| `figma/` | ảnh Figma screens + dialog đã cập nhật | checklist §1.2 |
| `report/` | `report/Lab03_<StudentID>.pdf`, `slides/Lab03_<StudentID>_slides.pdf` (bản cuối đặt trong repo) | Phase G |
| `video/` | link + thumbnail video 5–10′ | Phase G |

Trạng thái 03/11: **chưa có ảnh** — chờ batch thiết bị (docs/test-plan.md §3 B2)
và ARTEMIS sau E1. Scripts `e2e_test/conftest.py::evidence_shot` tự sinh `TC-*.png`
vào `artemis/` khi harness chạy.
