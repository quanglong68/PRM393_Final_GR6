"""Flow 3 — Quick Capture Ghi chú & Vault Sync (TC-F3-*)."""

import pytest

from conftest import require_artemis, skip_without_adb

pytestmark = [skip_without_adb, pytest.mark.e2e]


@require_artemis
async def test_TC_F3_01_create_note(artemis, evidence_shot):
    """Tạo note → 'Lưu vào Vault' → thấy trong danh sách."""
    result = await artemis.run(
        "Ở tab 'Ghi chú': tạo ghi chú mới tiêu đề 'E2E F3 note', thêm 1 dòng nội dung, "
        "bấm 'Lưu vào Vault'. Xác nhận note xuất hiện trong danh sách và trả về tên note."
    )
    assert result.succeeded, f"ARTEMIS fail: {result.error or result.status}"
    evidence_shot("TC-F3-01")


@require_artemis
async def test_TC_F3_02_offline_save_error_branch(artemis, device_state, logcat, evidence_shot):
    """Nhánh LỖI + TƯƠNG TÁC ANDROID GỐC (guide tr.23): tắt wifi qua adb → lưu note phải báo lỗi thật."""
    device_state("shell", "svc", "wifi", "disable")
    device_state("shell", "svc", "data", "disable")
    try:
        logcat.start("TC-F3-02")
        result = await artemis.run(
            "Sửa ghi chú 'E2E F3 note' (hoặc tạo mới 'E2E offline'), đổi nội dung rồi bấm lưu. "
            "Thiết bị ĐANG mất mạng. Mô tả chính xác thông báo trên màn hình (snake bar/toast/chữ lỗi)."
        )
        log_text = logcat.stop_and_text()
        assert result.succeeded, f"ARTEMIS fail: {result.error or result.status}"
        assert "Không thể" in str(getattr(result, "answer", "")) or "lỗi" in str(
            getattr(result, "answer", "")
        ).lower(), f"UI phải báo lỗi thật khi offline, không im lặng: {getattr(result, 'answer', '')}"
        evidence_shot("TC-F3-02-offline")
        assert "EXCEPTION" not in log_text or "Failed host lookup" in log_text, (
            f"Crash ngoài mong đợi khi offline:\n{log_text[-800:]}"
        )
    finally:
        device_state("shell", "svc", "wifi", "enable")
        device_state("shell", "svc", "data", "enable")


@require_artemis
async def test_TC_F3_03_reconnect_sync_recovery(artemis, device_state, evidence_shot):
    """Recovery: bật lại mạng → manual sync → note đồng bộ, không còn lỗi."""
    device_state("shell", "svc", "wifi", "enable")
    result = await artemis.run(
        "Chờ 10 giây cho mạng hồi. Vào Cài đặt & Đồng bộ, bấm 'Đồng bộ ngay bây giờ' + xác nhận. "
        "Mở lại tab 'Ghi chú' và xác nhận ghi chú 'E2E' còn nguyên nội dung, không có banner lỗi."
    )
    assert result.succeeded, f"ARTEMIS fail: {result.error or result.status}"
    evidence_shot("TC-F3-03-recovered")
