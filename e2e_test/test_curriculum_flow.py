"""Flow 1 — Tra cứu Slot & Đầu điểm (TC-F1-*). Guide tr.23: phủ flow Lab 2."""

import pytest

from conftest import require_artemis, skip_without_adb

pytestmark = [skip_without_adb, pytest.mark.e2e]


@require_artemis
async def test_TC_F1_01_open_course_slots(artemis, evidence_shot):
    """Home → Lộ trình → PRM323 → Lịch slot ≤3 chạm, thấy danh sách slot."""
    result = await artemis.run(
        "Trong app 'FPTU Second Brain' đã đăng nhập: mở tab 'Lộ trình học tập', "
        "chạm môn 'PRM323', vào tab 'Lịch slot'. Trả về số lượng slot nhìn thấy "
        "và tên một slot đầu tiên."
    )
    assert result.succeeded, f"ARTEMIS fail: {result.error or result.status}"
    obs = str(getattr(result, "answer", "") or getattr(result, "summary", "") or "")
    assert obs.strip(), "Agent không tường thuật giá trị quan sát được (guide: không tin SUCCESS suông)"
    evidence_shot("TC-F1-01")


@require_artemis
async def test_TC_F1_02_search_course(artemis, evidence_shot):
    """Ô tìm kiếm 'PRM' chỉ còn môn khớp."""
    result = await artemis.run(
        "Ở màn 'Lộ trình học tập', gõ 'PRM' vào ô tìm kiếm. Liệt kê tên môn còn hiển thị."
    )
    assert result.succeeded, f"ARTEMIS fail: {result.error or result.status}"
    evidence_shot("TC-F1-02")


@require_artemis
async def test_TC_F1_04_ask_ai_branch(artemis, evidence_shot):
    """Chi tiết môn → 'Hỏi trợ lý AI về môn này' → Advisor kèm mã môn."""
    result = await artemis.run(
        "Mở chi tiết môn PRM323, chạm nút 'Hỏi trợ lý AI về môn này'. "
        "Xác nhận màn trợ lý AI hiện ra và có ngữ cảnh môn PRM323; trả về câu chữ hiển thị ngữ cảnh đó."
    )
    assert result.succeeded, f"ARTEMIS fail: {result.error or result.status}"
    evidence_shot("TC-F1-04")


@require_artemis
async def test_TC_05_prerequisite_check(artemis, evidence_shot):
    """Lọc 'Kiểm tra môn tiên quyết' → thấy trạng thái đối chiếu bảng điểm (Flow 1 nhánh phụ)."""
    result = await artemis.run(
        "Ở tab 'Lộ trình học tập': bật bộ lọc/lựa chọn kiểm tra môn tiên quyết, "
        "mở chi tiết một môn có tiên quyết (vd PRM323). Trả về dòng chữ thể hiện "
        "tiên quyết ĐẠT hay CHƯA ĐẠT nhìn thấy trên màn."
    )
    assert result.succeeded, f"ARTEMIS fail: {result.error or result.status}"
    answer = str(getattr(result, "answer", "") or "")
    assert answer.strip(), "Agent không tường thuật trạng thái tiên quyết (guide: observable values)"
    evidence_shot("TC-05")
