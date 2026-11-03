# Video demo Lab 3 — Kịch bản 7′30″ (dải 5–10′, draft G3, 03/11)

> Quay bằng scrcpy/azscreen trên AVD hoặc device thật, 1080p, app debug-build (logcat bật để
> nói "kiểm chứng bằng log"). Trước khi quay: đăng xuất sẵn, mạng bật, Firestore đã seed (Xong 02/11).
> ⏳ các đoạn cần chạy lại sau gate-domain (account **@fpt.edu.vn**). Checklist guide: sign-in →
> 3 flows → sync/offline → notification → PDF export. Tổng **~7′30″**, mỗi cảnh 1 take; hỏng thì
> quay lại riêng cảnh đó (không dựng cắt cảnh quan trọng).

| # | Cảnh | Thời lượng | Hành động trên device | Lời thoại (VO) / text overlay | Bằng chứng kèm |
|---|---|---|---|---|---|
| 0 | Intro | 0:20 | Màn Home tĩnh | "FPTU Second Brain — PRM393 Lab 3. From offline prototype to a cloud app on Firebase, tested with ARTEMIS." | overlay repo + project |
| 1 | Google Sign-In | 0:45 | Chạm "Đăng nhập Google" → chọn account @fpt.edu.vn → vào Home | "Auth là Google chính chủ qua Firebase. App chặn email ngoài dominio fpt.edu.vn — kể cả khi client bỏ qua, server check vẫn từ chối." | `TC-01` + logcat `Sign-In succeeded` ⏳ |
| 1b | Domain reject (nhánh lỗi) | 0:30 | Đăng nhập account lạ (vd gmail thường) → app báo lỗi + tự sign-out | "Nhánh lỗi #1: invalid-domain. Fail-loud — không phiên nửa vời." | `TC-S-01` screenshot ⏳ |
| 2 | Flow 1 Curriculum | 0:50 | Tab Lộ trình → search `PRM` → mở PRM323 → tab Lịch slot → "Kiểm tra môn tiên quyết" | "Dữ liệu đọc thẳng từ Firestore `courses`, đã seed. Điều kiện tiên quyết đối chiếu `passedCourses` của đúng user này." | `FLW-01` + Console doc mở cạnh ⏳ |
| 3 | Flow 2 Tasks | 0:50 | Tạo task → check hoàn thành (snackbar HOÀN TÁC 8s) → **sửa task có sẵn** → mở Console Firebase chỉ doc update | "Update ghi đúng doc ID canonical — bug legacy từng làm not-found đã sửa ở `decae72`, verify lại bằng TC-V1." | `TC-V1` + Console ⏳ |
| 4 | Flow 2 Notes + offline | 0:40 | Tạo note → tắt WiFi (quick settings) → note lưu local, app báo lỗi sync thật → bật WiFi → manual sync → note lên Console | "Offline-first: `Source.serverAndCache`. Không mock im lặng — app nói rõ đang lỗi, rồi phục hồi." | `TC-V2`/`TC-F3-02` ⏳ |
| 5 | Flow 3 Advisor | 0:40 | Hỏi "Môn PRM323 có những đầu điểm nào?" → trả lời kèm nguồn → lỗi có chủ đích (tắt mạng giữa câu) → bấm "Thử lại" | "Ai Advisor có nhánh retry giữ nguyên câu hỏi — M4." | `TC-08`/`TC-09` ⏳ |
| 6 | PDF export | 0:50 | SyncVault → Export PDF → **dialog consent** → Hủy 1 lần (nói: từ chối là không upload) → Accept → progress % → Download URL → share | "Báo cáo generate từ dữ liệu đang xem, có font tiếng Việt. Consent bắt buộc trước khi rời máy." | `TC-10` + Storage file listing ⏳ |
| 7 | Notification 3 trạng thái | 0:50 | Gửi push từ Console: (a) app foreground → banner + Center; (b) background → hệ thống → tap mở đúng màn; (c) force-stop → cold start mở app | "FCM cả 3 vòng đời, token lưu theo uid, tap-routing về đúng màn." | `TC-13`/`TC-X-06` 6 ảnh ⏳ |
| 8 | Remote Config live | 0:35 | Bật `maintenance_mode` trên Console → app (không rebuild) refresh → UI đổi → tắt lại | "Cấu hình nóng — không cần build lại." | `TC-11` before/after ⏳ |
| 9 | Crashlytics + Analytics | 0:30 | Nút test non-fatal trong Demo Area → Dashboard Crashlytics thấy user id + custom key; DebugView thấy 2–3 events | "Mỗi crash gắn uid và auth_method; event có ≥2 tham số, đã lọc PII." | `TC-S-05` + dashboard ⏳ |
| 10 | ARTEMIS + review | 0:45 | Chiếu nhanh: chạy `uv run pytest -m e2e` 1 ca + pass-rate table + 1 finding `docs/code-review.md` + commit `fix(CR-01)` | "10+ ca E2E × 3 runs bằng ARTEMIS, assert giá trị quan sát được; 5+ findings AI review, sửa bằng 3 commit riêng." | `evidence/artemis/` ⏳ |
| 11 | Outro | 0:15 | Home → repo QR | "Repo, evidence, báo cáo: link mô tả video. Cảm ơn." | — |

**Ghi chú kỹ thuật quay:**
- Bật Developer Options → Show taps. Console Firefox/Chrome fullscreen cạnh emulator (split) cho các cảnh 3, 6, 8.
- Cắt/xen mờ mọi project number, email thật (dùng account test), API key (§9.3) — trước khi upload.
- Upload YouTube không công khai (unlisted) → dán link vào README + report; kiểm tra quyền truy cập.
- Nếu quá 8′: cắt cảnh 9 còn 20″, gộp 1b vào 1. Nếu dưới 5′ (hy hữu): thêm take chạy pytest đầy đủ.
