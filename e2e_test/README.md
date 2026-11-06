# ARTEMIS E2E — cập nhật 04/11/2026

SDK được pin tại commit `351ca8422f7b5b54e80a9c1ce03a222e02415b6b`; host đang cài ở `C:/Users/duong/tools/artemis`.
Có 26 ca: 25 regression × 3 lượt và 1 exploratory = 76 mục thu thập. Collection không phải kết quả chạy thiết bị.

## Chạy trên Windows

Tại thư mục repository, sau khi ARTEMIS host có quota và emulator sẵn sàng:

```powershell
& e2e_test/.venv/Scripts/python.exe -m pytest e2e_test --collect-only -q
& e2e_test/.venv/Scripts/python.exe -m pytest e2e_test -m "e2e and not exploratory" --runs 3 -v
& e2e_test/.venv/Scripts/python.exe -m pytest e2e_test -m exploratory --runs 1 -v
```

Nếu SDK báo không kết nối được cổng `8000`, mở một terminal riêng tại thư mục cài ARTEMIS và chạy `& .venv/Scripts/artemis.exe ui --no-open`. Chờ server nghe trên `127.0.0.1:8000` rồi chạy lại một ca trước khi chạy batch.

Máy hiện đã có venv riêng và pytest/pytest-asyncio/pytest-timeout/artemis-client. Để tái tạo môi trường dùng `uv sync` trong `e2e_test` với dependency đã pin.

Key mô hình nằm trong `.env` của **host ARTEMIS**, không cần chép key sang repository. Sau đổi key, nạp lại host/MCP. `.env` của harness chỉ cần địa chỉ host, serial và tài khoản thử riêng.

Các ca đổi tài khoản/tạo dữ liệu yêu cầu `TEST_ACCOUNT_EMAIL` thuộc `@fpt.edu.vn` và `E2E_ALLOW_AUTH_CHANGES=1`. Nếu chưa có tài khoản thử riêng, chúng SKIP; không đăng xuất tài khoản cá nhân đang lưu. Ca tạo dữ liệu chỉ sửa fixture E2E có tên duy nhất của chính nó.

## Bằng chứng và tính đúng

- Mỗi lượt lưu `admitted.json`, `result.json`, screenshot riêng dưới `evidence/artemis/runs/`; không ghi đè lượt trước.
- Assertion đọc `TaskResult.output` hoặc dữ liệu có cấu trúc trong hành động cuối của đúng trace. Ca tìm môn đối chiếu thêm ô tìm kiếm và mã môn từ hierarchy Android. Trạng thái SUCCESS đơn lẻ không đủ.
- SDK timeout 390 giây, poll 5 giây, pytest timeout 480 giây. Exploratory có timeout riêng và phải quan sát ít nhất 15 phút.
- Ca offline luôn khôi phục trạng thái mạng ban đầu bằng fixture `finally` của pytest, kể cả task lỗi.
- `results-*.json/md` có số lượt chạy, đạt/trượt/bỏ qua, thời gian trung bình. Bỏ qua hoặc hỏng hạ tầng không phải PASS.
- Quota 429 thì chẩn đoán, xử lý quota rồi mới chạy lại; không lặp toàn bộ bộ test để tạo hàng loạt lỗi giống nhau.
- Còn thiếu scrcpy tùy chọn: hiện chưa có video replay. Không khẳng định đủ evidence video.

Ngày 04/11: các trace trước bị quota; ca SDK sau restart còn gặp 429/503. Chưa đạt tiêu chí >=10 ca ×3 và exploratory.


## Chẩn đoán bổ sung tối 04/11

- Host trả `TaskResult.output=None` kể cả Flash completed. Adapter chỉ nhận JSON từ hành động **cuối cùng** `report_task_status` với status completed của đúng session qua API steps; không suy đoán từ stdout. Lưu `terminal-report.json`; kiểm tra text từ UIAutomator độc lập (`native-final-text.txt`) và screenshot trước assertion.
- Khởi động riêng từng ca, chờ UI Home/sign-in thực tối đa 60 giây; không tap cửa sổ chưa sẵn sàng. Encoding ADB là UTF-8; pytest timeout 480 giây gồm startup và SDK390 giây.
- 7 parser/adapter unit tests đạt; 76 mục collect. **Chưa có E2E PASS**: một run SDK completed nhưng harness phát hiện output bị thiếu, các run khác gặp quota/ANR. Không đổi kết quả cũ thành PASS sau khi sửa adapter.
- Gemini 2.5 Flash có thể generate nhưng key/project vẫn bị hạn mức 20 request/ngày/model. Cần quota phù hợp cho >=10 ca ×3 và exploratory; thay key trong cùng project free-tier không bảo đảm tăng quota. Không tự bật billing.
- Host ARTEMIS đã đổi default và history chunk model sang gemini-2.5-flash, có backup cấu hình trước đổi trong TEMP; chi tiết tại docs/implementation-verification-2026-11-04.md. Không chép key vào harness.

## Ngày 05/11/2026

TC_11 có 1 PASS trên Pixel 7 emulator. Dữ liệu được xác minh bằng terminal report cùng hierarchy độc lập. Xem [kết quả](../evidence/artemis/results-20261105T103204181722Z.md). Khi chấm, kết nối Android thật, kiểm tra `adb devices -l`, đặt `DEVICE_SERIAL` theo serial máy thật và chạy lại. Batch đủ 3 lượt mỗi ca và exploratory vẫn cần thu.

Lượt chạy ca tìm môn sau đó đã phát hiện hai dạng trường quan sát trong hành động cuối và một lỗi nhập query của agent. Đã cập nhật parser và thêm đối chiếu query với hierarchy. Gemini trả HTTP 429 khi chạy lại. [Trace và kết quả từng lần thử](../evidence/artemis/2026-11-05-search-run.md).
