# AI gợi ý kế hoạch học tập

Firebase AI Logic dùng Gemini Developer API. Client truyền số kỳ từ lựa chọn 1–12. Tên, email, ảnh, điểm, lịch và văn bản người dùng nhập không nằm trong prompt. Model trả JSON gồm `goal` và `actions`. Dart kiểm tra kiểu, độ dài và số lượng trước khi hiển thị nhãn AI. Bấm **Dùng** sẽ điền bản nháp vào ô sửa; thao tác **Gửi để duyệt** vẫn riêng.

Remote Config có `study_plan_ai_enabled` mặc định tắt, `study_plan_ai_model` mặc định `gemini-3.5-flash-lite` và `study_plan_ai_prompt`. Analytics chỉ ghi tên sự kiện. Khi kết nối, quota hoặc định dạng lỗi, form nhập thủ công vẫn dùng được.

Cần hoàn tất provision AI Logic, đăng ký App Check cho app và thiết bị demo rồi bật cờ ở môi trường kiểm tra. Chạy ba input kỳ khác nhau và lưu output thật đã kiểm tra, thêm một lần mất mạng hoặc lỗi quota. Dùng cùng APK để quay thay đổi cờ. Không dùng output minh họa làm evidence.

## Bật cloud để chạy demo

Lượt CLI từ tài khoản đang đăng nhập bị từ chối quyền `serviceusage.services.enable` cho `firebasevertexai.googleapis.com`. Chủ project mở [Google Cloud API Library](https://console.cloud.google.com/apis/library/firebasevertexai.googleapis.com?project=prm323-lab2-gr6) để bật Firebase AI Logic API và hoàn tất Gemini Developer API trong Firebase Console. Đăng ký App Check cho Android và web trước khi bật enforcement để tránh chặn client hiện có. Token debug chỉ đăng ký riêng trong Console, không đưa vào mã nguồn hoặc slide.

## Hỏi AI từ tài liệu trên Android

Mở một ghi chú đã lưu, chọn **Hỏi AI**, nhập câu hỏi và gửi. AI dùng nội dung ghi chú hoặc tệp đính kèm PDF, Markdown hay TXT tối đa 5 MB. Nếu ghi chú có cả văn bản và tệp hỗ trợ, màn hình cho chọn nguồn. Bản có `REPORT_MEDIA_URL` gửi yêu cầu qua Media API với `GEMINI_API_KEY` ở máy chủ. Bản mặc định gửi qua Firebase AI Logic và cần App Check đã đăng ký.

Trong tab **Ghi chú**, chọn **Nhập syllabus FLM**, truy cập danh mục của trường, mở syllabus của môn rồi bấm **Nhập thành ghi chú**. Kiểm tra mã môn và lưu. Để tạo ghi chú từ tệp, chọn **Tải tệp lên** trong cùng tab, kiểm tra tiêu đề và lưu. Markdown và TXT UTF-8 dung lượng phù hợp được điền vào nội dung nếu ghi chú còn trống. [Cấu hình Media API](../admin-web/README.md#lưu-báo-cáo-và-tệp-đính-kèm-trên-cloudinary-free).
