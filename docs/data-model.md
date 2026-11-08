# Hợp đồng tích hợp mobile và web

- Project hiện có `prm323-lab2-gr6`, Firestore Standard `(default)`.
- Đăng nhập Google. Web đọc chính `users/{uid}` và chỉ cho `staff` hoặc `admin`. Mobile dành cho `user`. Hồ sơ Lab 3 thiếu role được nhận là sinh viên; mobile gán `user` qua giao dịch trước khi gửi lần đầu.
- Người quản trị bootstrap Admin trong Console sau khi rà các giá trị role đã tồn tại. Rules Lab 3 từng cho chủ hồ sơ ghi trường tùy ý, vì vậy **rà role trước khi deploy Rules mới**. Không ghi email thật hoặc token demo trong Git.

| Path | Trường | Quyền |
| --- | --- | --- |
| `users/{uid}` | `role` thuộc `user/staff/admin`; các trường hồ sơ học tập Lab 3 | Chủ đọc và cập nhật hồ sơ, giữ role. Admin cập nhật riêng trường role của tài khoản khác. Staff không đọc hồ sơ riêng. |
| `courses/{CODE}` | `code`, `name`, `credits`, `semester`, `major`, `archived` tùy chọn | Người đăng nhập đọc. Staff/Admin tạo và sửa các trường quản lý. Giữ nguyên syllabus hiện có. Archive bằng `archived: true`; app bỏ qua môn đó khi tải. Không xóa. |
| `study_plan_submissions/{uid}_{semester}` | `uid`, `semester` int 1–12, `summary` string 1–600, `status`, `reason` string tối đa 300, `createdAt` timestamp; sau duyệt thêm `reviewedAt`, `reviewedBy` | Sinh viên tạo pending, reason rỗng, đúng UID. Chủ/Staff/Admin đọc. Staff/Admin chỉ duyệt pending thành approved/rejected, lý do bắt buộc. Một hồ sơ mỗi kỳ, không xóa hoặc duyệt lại. |
| `announcements/{id}` | `title` 1–120, `body` 1–1000, `authorUid`, `publishedAt` timestamp | Staff/Admin đăng bằng UID của mình. Người đăng nhập đọc. Không cập nhật/xóa. |
| `users/{uid}/sync/{id}` | Metadata Lab 3. PDF cục bộ thêm `fileName`, `sizeBytes`, `generatedAt` ISO, `source: local_pdf`, `createdAt` timestamp | Chỉ chủ. Không tải PDF cục bộ lên cloud. |
| `users/{uid}/{tasks,notes,notifications,tokens}/{id}` | Dữ liệu riêng Lab 3 | Quyền owner hiện có. |
| `curriculums/{id}`, `audit_logs/{id}` | Dữ liệu Lab 3 | Curriculum chỉ đọc khi đăng nhập. Audit chỉ tạo bản ghi gắn UID. |

Web cập nhật quyết định bằng một write gồm `status, reason, reviewedBy, reviewedAt`, với `reviewedAt: serverTimestamp()`. Form thông báo dùng `publishedAt: serverTimestamp()`. Dashboard có thể chạy count theo ba trạng thái trong `study_plan_submissions`, rồi vẽ biểu đồ ba nhóm.
