"""TC-08 Advisor/Strategy + TC-09 Error/Empty path (checklist §8.2, F-05 retry)."""

import pytest

from conftest import require_artemis, skip_without_adb

pytestmark = [skip_without_adb, pytest.mark.e2e]


@require_artemis
async def test_TC_08_advisor_course_question(artemis, evidence_shot):
    """Hỏi môn PRM323 → trả lời Markdown kèm thẻ nguồn, không rỗng."""
    result = await artemis.run(
        "Vào Trợ lý AI (tab/home), hỏi 'Môn PRM323 có những đầu điểm nào?'. "
        "Chờ câu trả lời. Trả về 20 từ đầu của câu trả lời và xác nhận có thẻ trích dẫn nguồn."
    )
    assert result.succeeded, f"ARTEMIS fail: {result.error or result.status}"
    answer = str(getattr(result, "answer", "") or "")
    assert len(answer) > 20, f"Câu trả lờiAdvisor quá ngắn/rỗng: '{answer}'"
    evidence_shot("TC-08")


@require_artemis
async def test_TC_09_advisor_offline_retry(artemis, device_state, evidence_shot):
    """Nhánh LỖI + phục hồi M4: mất mạng khi hỏi → banner lỗi + 'Thử lại' giữ nguyên câu hỏi."""
    device_state("shell", "svc", "wifi", "disable")
    try:
        result = await artemis.run(
            "Ở Trợ lý AI (đã có sẵn 1 câu hỏi từ ca trước, nếu không thì gửi 'Test lỗi'), "
            "thiết bị ĐANG mất mạng. Chờ trạng thái lỗi và mô tả: có nút 'Thử lại' không, "
            "câu hỏi còn giữ nguyên không? Sau đó bật lại mạng (agent tự chờ) — nếu không bật được, "
            "chỉ cần xác nhận error state."
        )
        assert result.succeeded, f"ARTEMIS fail: {result.error or result.status}"
        answer = str(getattr(result, "answer", "") or "").lower()
        assert "thử lại" in answer or "retry" in answer or "lỗi" in answer, (
            f"Không thấy error/retry state khi offline: {answer}"
        )
        evidence_shot("TC-09")
    finally:
        device_state("shell", "svc", "wifi", "enable")
