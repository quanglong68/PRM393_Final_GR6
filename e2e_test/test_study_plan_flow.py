"""Flow 2 — Quản lý Deadline & Undo (TC-F2-*) + close-out nợ M11E (TC-V1)."""

import pytest

from conftest import require_artemis, skip_without_adb

pytestmark = [skip_without_adb, pytest.mark.e2e]

UNIQUE = "E2E-F2 "  # prefix để nhận diện task do harness tạo


@require_artemis
async def test_TC_F2_01_toggle_task(artemis, evidence_shot):
    """Checkbox → gạch ngang + Snackbar HOÀN TÁC."""
    result = await artemis.run(
        f"Ở tab 'Việc cần làm': tạo task mới tiêu đề '{UNIQUE}toggle'. Sau đó tick checkbox task đó. "
        "Xác nhận task gạch ngang/chuyển nhóm 'Đã xong' và có snackbar hoàn tác; trả về chữ snackbar."
    )
    assert result.succeeded, f"ARTEMIS fail: {result.error or result.status}"
    evidence_shot("TC-F2-01")


@require_artemis
async def test_TC_F2_02_undo_within_8s(artemis, evidence_shot):
    """Nhánh recovery: HOÀN TÁC trong 8s trả task về chưa xong."""
    result = await artemis.run(
        f"Ở tab 'Việc cần làm' với task '{UNIQUE}toggle' vừa hoàn thành: "
        "chạm nút HOÀN TÁC trên snackbar trong vòng 8 giây. "
        "Xác nhận task trở lại nhóm chưa xong và trả về vị trí/nhãn nhìn thấy."
    )
    assert result.succeeded, f"ARTEMIS fail: {result.error or result.status}"
    evidence_shot("TC-F2-02")


@require_artemis
async def test_TC_V1_update_existing_task(artemis, device_state, logcat, evidence_shot):
    """NỢ M11E CLOSE-OUT: sửa task ĐÃ TỒN tại → updateTask pass, log không exception."""
    logcat.start("TC-V1")
    result = await artemis.run(
        f"Mở tab 'Việc cần làm', chạm vào nội dung task bắt đầu bằng '{UNIQUE}' (không phải checkbox), "
        "đổi tiêu đề thêm ' EDITED', bấm 'Lưu việc cần làm'. "
        "Xác nhận danh sách hiện tiêu đề mới và KHÔNG có banner lỗi."
    )
    log_text = logcat.stop_and_text()
    assert result.succeeded, f"ARTEMIS fail: {result.error or result.status}"
    assert "FirebaseException" not in log_text, f"Log chứa exception:\n{log_text[-800:]}"
    assert "editTask error" not in log_text, f"editTask báo lỗi:\n{log_text[-800:]}"
    evidence_shot("TC-V1")


@require_artemis
async def test_TC_F2_05_add_task_id_consistency(artemis, evidence_shot):
    """Task mới xuất hiện lại sau manual sync (doc ID canonical — M11D/E)."""
    result = await artemis.run(
        f"Tạo task '{UNIQUE}canonical' qua nút 'Thêm việc'. "
        "Vào Cài đặt & Đồng bộ, chạm 'Đồng bộ ngay bây giờ' và xác nhận dialog. "
        "Quay lại 'Việc cần làm': xác nhận task '{UNIQUE}canonical' vẫn còn; trả về dòng hiển thị của nó."
    )
    assert result.succeeded, f"ARTEMIS fail: {result.error or result.status}"
    evidence_shot("TC-F2-05")
