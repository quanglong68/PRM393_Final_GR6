# Chạy lại ARTEMIS với Gemini Flash-Lite ngày 07/11/2026

Pixel 7 giả lập chạy APK debug sau ba sửa lỗi review. Probe trực tiếp của cấu hình cũ Gemini 2.5 Flash trả HTTP 429 với giới hạn ngày. Gemini 3.5 Flash-Lite trả HTTP 200 với cùng key ARTEMIS. Đã sao lưu cấu hình host rồi đổi model và khởi động lại daemon.

| Ca | Kết quả pytest | Trace |
|---|---|---|
| TC_X_06 trước khi đổi model | Đã hủy sau khi probe báo hết quota ngày | `4b96783a-2149-4f30-8599-4df234236700` |
| TC_02 lượt 1 | PASS | `0a957032-8b86-44b6-8180-e0c7470c37c4` |
| TC_02 lượt 2 | PASS | `98e2693b-ce0f-40c2-9670-dc9d89a9cf5d` |
| TC_02 lượt 3 | FAIL. ARTEMIS timeout khi mở lại app | `28226745-46d9-4bee-9074-ba7ad1e6951b` |
| TC_02 chạy lại sau khi khởi động lại giả lập | PASS | `aa8ce04c-2bfd-4b2a-8668-e9db2bc84dd6` |
| TC_X_06 sau khi khởi động lại giả lập | PASS | `0d0f6a8d-a927-4049-bab8-ad97dd8dfc93` |

TC_02 hiện hướng dẫn agent quan sát màn hình mà harness đã mở. Kết quả fail ban đầu vẫn được giữ. TC_X_06 kiểm tra giao diện Trung tâm thông báo và dữ liệu hiển thị. Ca này không gửi push mới.
