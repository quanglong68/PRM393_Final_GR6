# Kiểm thử và review Final

## Lệnh tái hiện

```powershell
flutter analyze
flutter test
npm.cmd --prefix firebase/tests ci
npx.cmd --yes firebase-tools@13.35.1 emulators:exec --only firestore --project demo-second-brain-final "npm --prefix firebase/tests test"
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

## Kết quả chạy ngày 09/11/2026 (tái cấu trúc quản trị chương trình)

- `flutter analyze`: 0 vấn đề.
- `flutter test` (models + viewmodels + screens): 87 pass; `test/services` + widget/regression gốc: 56 pass. Tổng 143 pass, 0 fail.
- `flutter build apk --debug`: thành công, tạo lại `build/app/outputs/flutter-apk/app-debug.apk`.
- `node --test admin-web/flm-parser.test.mjs`: 6/6 pass (curriculum 5 cột, metadata đề cương, bảng đánh giá 13 cột, merge nhiều file, JSON/Markdown cũ).
- Merge thử 5 file HTML FLM thật trong `Downloads` (1 chương trình + 4 đề cương): nhận đúng `BIT_SE_K19B`, 49 môn, 4 môn có đề cương; 49/49 mã môn và mã ngành hợp lệ theo regex của Rules.
- `node --check admin-web/app.js`: hợp lệ cú pháp.
- Kiểm tra SPA trên trình duyệt (`python -m http.server` + in-app browser): sign-in screen render, empty state không còn dữ liệu mẫu; luồng **Thêm chuyên ngành → thủ công → thêm môn → áp dụng** tạo đúng dòng môn và tổng tín chỉ trên form.
- Import thật trên trình duyệt: kéo 5 file HTML FLM (1 chương trình + 4 đề cương) vào dropzone, bấm **Phân tích tệp** → form tự điền `BIT_SE_K19B`, 49 dòng môn, “4 có đề cương / 45 chỉ thông tin chung”, 11 cảnh báo.
- FIRESTORE RULES: `firebase/tests` chạy 14/14 pass trên Firestore Emulator (role bootstrap, chống tự nâng quyền, composite course ID, `*` code, `experience_notes` submit/duyệt/công khai, curriculum/audit). Lệnh: `npx firebase-tools@13.35.1 emulators:exec --only firestore --project demo-second-brain-final "npm --prefix firebase/tests test"`.
- Đã bỏ toàn bộ seed/template khỏi `admin-web/`; dữ liệu ngành/môn chỉ đến từ form thủ công hoặc file HTML FLM.
- Mobile: bỏ slot/LO/giáo trình/đầu điểm giả; màn chi tiết dùng `slots`, `learningOutcomes`, `courseMaterials`, `labs` thật và hiện “chưa cập nhật đề cương” khi thiếu. Gửi/đọc bí kíp dùng `experience_notes`; duyệt realtime trên web.
