# Hợp đồng dữ liệu mobile và web quản trị

- Project `prm323-lab2-gr6`, Firestore Standard `(default)`.
- Đăng nhập Google. Web quản trị đọc `users/{uid}` và chỉ cho `staff` hoặc `admin`. Mobile dành cho `user`.
- Không còn fallback theo email `@fpt.edu.vn` / `@fe.edu.vn`. Vai trò chỉ lấy từ `users/{uid}.role` (hoặc custom claim `role` / `admin`).
- Tài khoản Admin đầu tiên được gán thủ công trong Firebase Console. Sau đó Admin có thể cấp `staff`/`admin` cho tài khoản khác qua trường `role` (rules chỉ cho Admin sửa đúng trường này).
- Không có seed/mock data trong repo phục vụ chương trình đào tạo. Dữ liệu ngành và môn học chỉ đến từ file HTML FLM do cán bộ nhập trên web.

| Path | Trường | Quyền |
| --- | --- | --- |
| `users/{uid}` | `role` thuộc `user/staff/admin`; các trường hồ sơ học tập | Chủ đọc/cập nhật hồ sơ của mình nhưng không được đổi `role`. Chỉ Admin đọc/sửa `role` của người khác và đọc hồ sơ người khác; Staff không đọc hồ sơ riêng của sinh viên. |
| `majors/{code}` | `code`, `name`, `nameEn`, `description`, `totalSemesters` 1–12, `source` (`manual`/`flm_html`), `archived` | Người đăng nhập đọc. Staff/Admin tạo/sửa/xóa. `code` phải trùng document ID. |
| `courses/{major}__{code}` | `code`, `name`, `nameVi`, `credits` 0–30, `semester` 0–12, `major`, `prerequisites`, `overview`, `studentTasks`, `tools`, `lecturer`, `link`, `resourceLinks`, `syllabusId`, `syllabusStatus` (`complete`/`partial`/`metadata`/`manual`), `slots`, `labs`, `learningOutcomes`, `courseMaterials`, `constructiveQuestions`, `totalSlots`, `completedSlots`, `archived` | Người đăng nhập đọc. Staff/Admin tạo/sửa/xóa. ID dạng `BIT_SE_K19B__PRF192` để cùng một môn có thể nằm trong nhiều ngành. Rules vẫn chấp nhận ID cũ `{code}` để tương thích dữ liệu cũ. |
| `experience_notes/{id}` | `courseDocId`, `courseCode`, `courseName`, `major`, `uid`, `authorName`, `content` 20–2000, `lecturerTip` ≤500, `examTip` ≤500, `rating` 0–5, `status`, `createdAt`; sau duyệt thêm `reason`, `reviewedBy`, `reviewedAt` | Sinh viên tạo `pending` với `uid` của mình; môn học phải tồn tại. Chủ đọc note của mình, mọi người đọc note `approved`, Staff/Admin đọc tất cả. Staff/Admin duyệt `pending` → `approved`/`rejected`, bắt buộc lý do 1–300 và `reviewedBy` đúng UID. Chủ được xóa note `pending`; Admin xóa mọi note. |
| `announcements/{id}` | `title` 1–120, `body` 1–1000, `authorUid`, `publishedAt` | Staff/Admin đăng bằng UID của mình. Người đăng nhập đọc. Chỉ Admin xóa. |
| `study_plan_submissions/{uid}_{semester}` | `uid`, `semester` 1–12, `summary` 1–600, `status`, `reason` ≤300, `createdAt` | Giữ cho tính năng kế hoạch học tập trên mobile. Web quản trị **không còn duyệt** collection này. |
| `users/{uid}/{tasks,notes,tokens,notifications,sync}/{id}` | Dữ liệu riêng của sinh viên | Chỉ chủ sở hữu. |
| `curriculums/{id}` | Dữ liệu Lab 3 cũ | Chỉ đọc khi đăng nhập; web quản trị được phép xóa khi dọn dữ liệu. Không tạo/cập nhật mới. |
| `audit_logs/{id}` | Bản ghi audit | Chỉ tạo bản ghi gắn UID; không đọc/sửa/xóa từ client. |

## Quy ước nghiệp vụ

- **Điểm số do sinh viên tự nhập** trong hồ sơ học tập trên mobile. Admin chỉ quản lý chương trình, môn học và môn tiên quyết; không nhập điểm thay sinh viên.
- **Môn tiên quyết** nằm trong `courses.prerequisites` và được Admin nhập/sửa cùng đề cương. Mobile dùng danh sách này để cảnh báo khi lập kế hoạch.
- **Đề cương thiếu dữ liệu**: khi chỉ import trang chương trình, môn học được ghi với `syllabusStatus: "metadata"` và các mảng chi tiết rỗng. Mobile hiển thị “chưa cập nhật đề cương”, không sinh slot/LO/giáo trình giả.
- **Dashboard** dùng `getCountFromServer` (aggregation query) cho `users`, `experience_notes` theo trạng thái và `majors`; các bảng/card cập nhật realtime bằng `onSnapshot`.
- **Dọn dữ liệu cũ** chỉ xóa `majors`, `courses`, `curriculums`. Giữ nguyên `users`, `announcements`, `experience_notes`, `study_plan_submissions`.
