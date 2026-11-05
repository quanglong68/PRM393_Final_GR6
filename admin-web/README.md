# Lab 3 Admin và máy chủ gửi FCM

Dashboard dành cho admin chạy trên máy chấm. Dev vẫn có thể xem Firebase Console. Dashboard lấy báo cáo `topIssues` từ Crashlytics REST API qua Node, sau đó hiển thị số sự kiện và số người bị ảnh hưởng. Mật khẩu web và OAuth của server là hai lớp riêng.

## Web admin

1. Dùng Node 22 trở lên. Trong thư mục này chạy `npm ci` và sao chép `.env.example` sang `.env`. Đặt `ADMIN_PASSWORD` riêng, ít nhất 24 ký tự.
2. Dùng Application Default Credentials (ADC) của tài khoản có quyền đọc báo cáo Crashlytics trên đúng project. Trên máy demo có gcloud, chạy `gcloud auth application-default login` và chọn tài khoản được cấp quyền. Kiểm tra quyền `firebasecrash.reports.get` cùng quyền đọc Crashlytics trong IAM. Có thể dùng `FIREBASE_ACCESS_TOKEN` ngắn hạn trong môi trường tiến trình cho buổi thử.
3. Chạy `npm start`, mở http://127.0.0.1:8787. Đăng nhập user `admin` với mật khẩu vừa đặt. Bấm **Tải lại báo cáo** sau khi mở lại app đã crash và Firebase xử lý.
4. Server chỉ lắng nghe loopback. Nếu cần nhiều admin từ xa, triển khai qua HTTPS với xác thực và phân quyền riêng thay cho Basic Auth local.

Xem [Crashlytics REST API](https://firebase.google.com/docs/reference/crashlytics/rest/v1alpha/projects.apps.reports/get) và [quyền IAM Crashlytics](https://docs.cloud.google.com/iam/docs/roles-permissions/firebasecrash).

## Gửi FCM từ server

Dùng môi trường server có quyền đọc registration trong Firestore và gửi FCM HTTP v1 trên project. Mở app bằng tài khoản demo trên thiết bị đích để registration được cập nhật. Dùng UID của tài khoản demo, không dùng email.

```powershell
npm run send:fcm -- DEMO_UID PRM323
npm run send:fcm -- DEMO_UID PRM323 --send
```

Lệnh đầu kiểm tra request với FCM qua `validate_only`. Lệnh thứ hai gửi thật. Script chọn registration cập nhật gần nhất trong `users/{uid}/tokens`, từ chối token cũ quá 24 giờ và không in token. Payload gồm nội dung ngắn cùng `route=/course-detail` và `courseId`. Chỉ chọn tài khoản demo có một thiết bị đang dùng, vì lệnh chọn bản ghi mới nhất. Server chỉ gửi mã môn và thông báo chung, tránh đưa dữ liệu cá nhân vào thông báo hệ thống.

## Cloudinary cho PDF trên Spark

Cloudinary dùng tài sản `raw` với chế độ `authenticated`. Điền ba biến `CLOUDINARY_*` vào `.env` trên server. Chạy `npm run start:media`. Media API là tiến trình riêng, không cần mật khẩu admin. Nó kiểm tra Firebase ID token, so UID với đường dẫn và chỉ nhận PDF tối đa 10 MB.

Khi chấm qua USB, chạy từ thư mục gốc sau khi kết nối điện thoại thật:

```powershell
adb devices -l
adb -s ANDROID_SERIAL reverse tcp:8788 tcp:8788
flutter run -d ANDROID_SERIAL --dart-define=REPORT_MEDIA_URL=http://127.0.0.1:8788
```

Mở Sync Vault, chọn **Xuất & Tải PDF lên Cloudinary**, xác nhận và đợi upload. Firestore lưu metadata sau khi server xác nhận tài sản. **Tải lại PDF từ cloud** tải qua Media API dưới phiên đăng nhập hiện tại, rồi mở chooser chia sẻ. Link metadata là URL API cần xác thực. Server giữ URL ký Cloudinary và proxy nội dung cho đúng chủ tài khoản. App vẫn hỗ trợ tạo PDF tại máy. Nhánh Cloudinary chỉ phục vụ PDF báo cáo, ghi chú vẫn dùng adapter Storage hiện tại.

Trên bản phát hành, dùng URL HTTPS cho Media API và đặt dịch vụ sau reverse proxy HTTPS. Bản debug cho phép HTTP chỉ tới loopback để chạy USB. Không chép `.env`, token hoặc Cloudinary key vào APK hay Git. Kiểm tra product environment Cloudinary đã cho phép delivery PDF trước khi chấm. [Tài liệu Cloudinary về asset riêng và tải có chữ ký](https://cloudinary.com/documentation/control_access_to_media).

`npm test` kiểm tra xác thực web và hợp đồng PDF qua HTTP local, gồm các nhánh sai chủ tài khoản và giới hạn kích thước.
