# Kiểm thử và review Final

## Lệnh tái hiện

```powershell
flutter analyze
flutter test
npm.cmd --prefix firebase/tests ci
npx.cmd --yes firebase-tools@latest emulators:exec --only firestore --project demo-second-brain-final "npm --prefix firebase/tests test"
```

Firestore Emulator dùng project demo, tách khỏi project thật. Test kiểm tra role, cách ly dữ liệu, duyệt một lần, schema, thông báo, quản lý môn và listener. Ma trận cho các collection cũ, ARTEMIS Final, web checklist, ba lượt deploy và thiết bị thật vẫn cần hoàn thiện.

## Review code mới

| Finding | Quyết định |
| --- | --- |
| Client có thể sửa trường chủ sở hữu hoặc duyệt lại nếu chỉ kiểm tra vai trò | Giới hạn diff vào bốn trường quyết định và yêu cầu bản ghi gốc pending. Có ca kiểm thử. |
| Hồ sơ cũ từng cho phép owner ghi trường tùy ý, gồm role | Giữ bước rà role trước deploy. Production chưa được đổi quyền. |
| JSON từ AI có thể đúng cú pháp nhưng sai kiểu hoặc có mục rỗng | Validate model Dart trước khi render, giữ form thủ công nếu thất bại. Có unit test. |
| Dữ liệu cá nhân có thể đi vào prompt nếu lấy cả form | Chỉ gửi số kỳ từ danh sách. Không đưa nội dung nhập, hồ sơ hay câu hỏi tự do vào payload. |

Đây là review AI của thay đổi mobile/backend hiện tại. Review lại sau khi ghép web.

## Kết quả chạy ngày 08/11/2026

- `flutter analyze`: 0 vấn đề.
- `flutter test`: 126 pass, gồm 2 unit test mới kiểm tra chuyển đổi và từ chối JSON AI không hợp lệ.
- Firestore Emulator Standard: 5 nhóm pass, 0 fail. Nhóm cuối xác nhận listener nhận từ chối kèm lý do sau thao tác của Staff. Đây là kiểm thử SDK và Rules cục bộ.
- `flutter build apk --debug`: thành công. Cài cập nhật trên Pixel 7 API 35 và kiểm tra thấy MainActivity hiển thị Trang chủ.
- AI Logic production chưa xác minh. CLI thử bật Gemini Developer API nhưng thiếu quyền bật `firebasevertexai.googleapis.com`. Chờ chủ project bật dịch vụ, đăng ký App Check và chạy ba mẫu thật.
- Rules mới được xác minh trên Emulator. Chưa deploy lên project thật.
