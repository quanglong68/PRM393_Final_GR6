"""Nhánh lỗi từng dịch vụ Firebase (rubric tr.25: "mỗi dịch vụ có ca kiểm thử lỗi") — TC-S-*.
Một số ca chỉ assert qua log/Console; nhóm cần can thiệp Console được skip kèm lý do."""

import pytest

from conftest import APP_PACKAGE, require_artemis, skip_without_adb

pytestmark = [skip_without_adb, pytest.mark.e2e]


@require_artemis
async def test_TC_S_01_auth_domain_reject(pro_artemis, evidence_shot):
    """S-10: tài khoản ngoài @fpt.edu.vn bị chặn với thông báo domain."""
    result = await pro_artemis.run(
        f"Trong app {APP_PACKAGE}: đăng xuất nếu đang đăng nhập, rồi bấm 'Đăng nhập với Google'. "
        "Nếu picker chỉ hiện account @fpt.edu.vn thì báo 'SKIPPED-NO-FOREIGN-ACCOUNT'. "
        "Nếu chọn được account khác domain, xác nhận app báo lỗi 'Chỉ tài khoản @fpt.edu.vn' "
        "và KHÔNG vào được Home; trả về chữ hiển thị."
    )
    assert result.succeeded, f"ARTEMIS fail: {result.error or result.status}"
    evidence_shot("TC-S-01")


@require_artemis
async def test_TC_S_06_remote_config_offline_defaults(artemis, device_state, logcat, evidence_shot):
    """RC init fail (chưa bật mạng sau force-stop) → app dùng defaults, không crash."""
    device_state("shell", "am", "force-stop", APP_PACKAGE)
    device_state("shell", "svc", "wifi", "disable")
    try:
        logcat.start("TC-S-06")
        result = await artemis.run(
            "Mở app 'FPTU Second Brain' (thiết bị đang mất mạng). "
            "Xác nhận app vào tới màn hình (Home hoặc sign-in) thay vì crash/ treo; "
            "mô tả màn hình thấy."
        )
        log_text = logcat.stop_and_text()
        assert result.succeeded, f"ARTEMIS fail: {result.error or result.status}"
        assert "FATAL EXCEPTION" not in log_text, f"Crash khi RC/Firebase offline:\n{log_text[-1000:]}"
        evidence_shot("TC-S-06")
    finally:
        device_state("shell", "svc", "wifi", "enable")


@require_artemis
async def test_TC_X_06_fcm_foreground_center(artemis, evidence_shot):
    """Notification Center mở được, danh sách hiển thị (delivery đẩy thật cần Console — evidence ảnh)."""
    result = await artemis.run(
        "Trong app: mở Notification Center (icon chuông / mục Thông báo). "
        "Trả về số mục hiển thị và tiêu đề mục đầu, hoặc xác nhận empty state."
    )
    assert result.succeeded, f"ARTEMIS fail: {result.error or result.status}"
    evidence_shot("TC-X-06")


@require_artemis
async def test_TC_S_07_fcm_permission_native(artemis, device_state, evidence_shot):
    """TƯƠNG TÁC ANDROID GỐC: cấp/deny POST_NOTIFICATIONS qua system dialog rồi check app không crash."""
    device_state("shell", "pm", "revoke", APP_PACKAGE, "android.permission.POST_NOTIFICATIONS")
    result = await artemis.run(
        f"Mở app {APP_PACKAGE} (vừa bị thu hồi quyền thông báo). "
        "Nếu có dialog xin quyền, chọn 'Cho phép'. Xác nhận app hoạt động bình thường sau đó."
    )
    assert result.succeeded, f"ARTEMIS fail: {result.error or result.status}"
    # restore
    device_state("shell", "pm", "grant", APP_PACKAGE, "android.permission.POST_NOTIFICATIONS")
    evidence_shot("TC-S-07")
