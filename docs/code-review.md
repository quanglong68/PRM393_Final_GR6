# AI-assisted code review — PRM393 Lab 3

Ngày: 04/11/2026. Công cụ: OpenAI Codex, review source local trên working tree của `main` (baseline `2337e00`) theo yêu cầu tiếp nhận và sửa lỗi.

**Trạng thái rubric: PARTIAL.** Bảng dưới là output của review thực tế và các sửa đã có trong working tree. Chưa review trên PR, chưa có external reviewer output, chưa tạo commit. Cột commit được để trống có chủ ý theo yêu cầu không tự commit/push của người dùng; không coi các sửa local là ba commit đạt rubric.

File:dòng trỏ tới vị trí **sau sửa**, không giả làm permalink của diff/PR chưa tồn tại.

| ID | Tool | File:dòng | Kind / severity | Finding | Decision / lý do | Sửa và xác minh | Fix commit |
|---|---|---|---|---|---|---|---|
| CR-01 | Codex | `lib/services/firebase_firestore_service.dart:94` | Bug / High | getTasks chỉ trả document đầu, cắt mất task sau reload | Accepted — vi phạm dữ liệu thật và file phản ánh dữ liệu theo đề §3 | Map mọi doc, canonical ID; adapter regression 3 docs và device cold restart đủ 3 tasks | Chưa tạo |
| CR-02 | Codex | `lib/viewmodels/tasks_viewmodel.dart:84` | Privacy / High | Response cũ có thể khôi phục private rows sau logout; catch ghi có thể rollback account cũ | Accepted — sign-out phải xóa local user data, đề §6 | Request version + UID + dispose guards cho các stores; delayed-read/delete regression tests | Chưa tạo |
| CR-03 | Codex | `lib/screens/tasks_screen.dart:230` | Functional / High | Toggle không hiện error/Undo, trái flow Lab 2 | Accepted — đề §3 yêu cầu flow alternative/recovery khớp thiết kế | Restore captured completion, error Snackbar, Undo 8 giây; widget test ở giây thứ 7 và device smoke | Chưa tạo |
| CR-04 | Codex | `lib/screens/sync_vault_screen.dart:268` | Data integrity / High | loadData bắt lỗi vào state nên Future.wait vẫn success; export có thể dùng stale data | Accepted — generated file phải phản ánh dữ liệu hợp lệ, đề §3 | Tái sử dụng SyncReloadService, chặn state error/identity switch; widget test xác nhận không consent/upload | Chưa tạo |
| CR-05 | Codex | `lib/services/remote_config_service.dart:103` | State management / Medium | Plain service không báo thay đổi; refresh luôn báo thành công | Accepted — RC phải đổi hành vi không rebuild, đề §6 | ChangeNotifier + provider/gate subscription; giữ lastFetchError; widget test maintenance bật/tắt trên app đang chạy | Chưa tạo |
| CR-06 | Codex | `lib/services/firebase_auth_service.dart:77` | Error handling / Medium | Cancel chỉ log; invalid-domain AuthException bị catch chung che message | Accepted — Authentication phải có feedback cancel/error, đề §6 | Cancel có AuthException, rethrow domain message; chưa thử account picker/domain runtime | Chưa tạo |
| CR-07 | Codex | `lib/services/crashlytics_service.dart:20` | Observability / Medium | Thiếu test crash; non-fatal demo tự nhận dashboard success; chưa có real handled path | Accepted — đề §6 đòi test crash và non-fatal thật | Test crash có confirm, explicit debug collection, report-export failure record; dashboard chưa xác minh | Chưa tạo |
| CR-08 | Codex | `lib/screens/tasks_screen.dart:220` | Bug / Medium | Hai FAB trong IndexedStack trùng default Hero tag, navigation phát sinh assertion | Accepted — route phải mở được, đề §3 | Tag riêng tasks/notes; export widget test phát hiện rồi pass, device mở Sync Vault không duplicate-Hero | Chưa tạo |
| CR-09 | Codex | `lib/services/analytics_service.dart:26` | Tracking gap / Medium | Thiếu logout trong event plan/code; identity telemetry chưa clear | Accepted — plan phải cover logout, đề §6 | logLogout + clear IDs, cập nhật plan; unit test đúng một event, chưa DebugView | Chưa tạo |

## Quy trình hoàn tất review còn lại

1. Người dùng cho phép các thao tác Git tương ứng, chuẩn bị PR reviewable chứa diff liên quan.
2. Chạy reviewer trên PR và lưu nguyên output thực tế vào `evidence/code-review/`.
3. Đối chiếu findings với diff được review; cập nhật locators theo PR thực.
4. Thực hiện ít nhất ba fix độc lập có ID trong commit và liên kết commit; không tạo lịch sử giả cho các thay đổi đã làm.
5. Nếu reviewer bổ sung findings, ghi Accepted/Modified/Rejected với lý do trước khi xử lý.

Disclosure của đợt Codex này nằm trong `ai/ai-code-log.md`. Validation tổng hợp và các giới hạn nằm trong `docs/fix-verification-2026-11-04.md`.

## Review local ngày 07/11/2026

Codex review baseline `b69dc71` sau khi tích hợp Gemini và Cloudinary. Ba thay đổi đầu có tập file riêng để đưa vào ba commit. Bảng ghi kết quả review local. PR và hash commit sẽ được điền sau khi có trên Git.

| ID | Loại | Phát hiện | Quyết định | Kiểm thử |
|---|---|---|---|---|
| CR-10 | UX | Thử lại thêm trùng câu hỏi. Gửi trong lúc đang chờ có thể xóa nội dung vừa gõ. Vị trí baseline `lib/viewmodels/advisor_viewmodel.dart:214`. | Accepted. Dùng lại câu hỏi cũ và chặn gửi khi đang chờ. | Flutter kiểm tra một câu hỏi qua hai lần gọi và câu trả lời thay lỗi cũ. |
| CR-11 | Độ tin cậy | Analytics ném lỗi sau khi PDF và metadata đã lưu làm app báo xuất thất bại. Vị trí baseline `lib/services/report_export_service.dart:177`. | Accepted. Tách lỗi telemetry khỏi kết quả nghiệp vụ và giữ lỗi gốc khi export thất bại. | Flutter mô phỏng Analytics không sẵn sàng sau khi lưu. |
| CR-12 | Kiểm tra đầu vào | Đuôi `.constructor` khớp thuộc tính kế thừa của bảng MIME. Vị trí baseline `admin-web/media-server.mjs:117`. | Accepted. Chỉ chấp nhận các mục được khai báo trong danh sách định dạng. | Test HTTP xác nhận GET với đuôi `.constructor` trả 415. |
| CR-13 | Tính nhất quán | Asset PDF có thể còn trên cloud nếu đã upload nhưng lần ghi metadata thất bại. Vị trí baseline `lib/services/report_export_service.dart:164`. | Deferred. Cần xác định trạng thái ghi Firestore trước khi thu hồi asset và thiết kế retry theo một ID cố định. | Đã có test lỗi ghi metadata. Chưa có quy trình tự phục hồi. |
| CR-14 | Vận hành | Endpoint cố vấn chưa giới hạn số câu hỏi theo UID. Vị trí baseline `admin-web/media-server.mjs:92`. | Deferred. Bản demo chạy loopback. Cần giới hạn quota khi đưa API ra môi trường chia sẻ. | Kiểm tra HTTP hiện có cho quyền truy cập và kích thước input. |

| Commit dự kiến | Tệp |
|---|---|
| `fix(CR-10): preserve advisor input and retry the existing question` | `lib/screens/advisor_screen.dart`, `lib/viewmodels/advisor_viewmodel.dart`, `test/viewmodels/advisor_viewmodel_test.dart` |
| `fix(CR-11): isolate report exports from analytics errors` | `lib/services/report_export_service.dart`, `test/services/report_export_service_test.dart` |
| `fix(CR-12): reject inherited attachment format names` | `admin-web/media-server.mjs`, `admin-web/server.test.mjs` |
