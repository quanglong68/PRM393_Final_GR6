"""TC-01 Sign-In native, TC-02 Auth routing, TC-12 Logout (checklist §8.2)."""

import pytest

from conftest import APP_PACKAGE, require_artemis, skip_without_adb

pytestmark = [skip_without_adb, pytest.mark.e2e]


@require_artemis
async def test_TC_01_google_signin_native(artemis, device_state, logcat, evidence_shot):
    """Tương tác Android gốc: picker Google hệ thống + account @fpt.edu.vn (S-10)."""
    device_state("shell", "am", "force-stop", APP_PACKAGE)
    logcat.start("TC-01")
    result = await artemis.run(
        f"Mở app {APP_PACKAGE}. Nếu thấy nút 'Đăng nhập với Google': chạm, "
        "chọn tài khoản @fpt.edu.vn trong picker hệ thống, chờ về Home. "
        "Nếu đang sẵn Home thì đăng xuất rồi đăng nhập lại. "
        "Trả về tên hiển thị trên Home sau khi sign-in."
    )
    log_text = logcat.stop_and_text()
    assert result.succeeded, f"ARTEMIS fail: {result.error or result.status}"
    assert "invalid-domain" not in log_text, "Account test không phải @fpt.edu.vn — sửa .env TEST_ACCOUNT_EMAIL"
    assert "Sign-In succeeded" in log_text, f"Không thấy log sign-in thành công:\n{log_text[-600:]}"
    evidence_shot("TC-01")


@require_artemis
async def test_TC_02_auth_routing(device_state, artemis, evidence_shot):
    """Chưa đăng nhập → Sign-in screen; có phiên → Home (routing đúng, không crash)."""
    device_state("shell", "pm", "clear", "notifications", APP_PACKAGE)
    result = await artemis.run(
        f"Mở app {APP_PACKAGE} (cold start). Mô tả màn hình đầu tiên thấy: "
        "'Đăng nhập với Google' (chưa phiên) hay 'Chào ...' Home (đã phiên)."
    )
    assert result.succeeded, f"ARTEMIS fail: {result.error or result.status}"
    answer = str(getattr(result, "answer", "") or "")
    assert ("Đăng nhập" in answer) or ("Chào" in answer), (
        f"Màn đầu không thuộc 2 nhánh routing hợp lệ: {answer}"
    )
    evidence_shot("TC-02")


@require_artemis
async def test_TC_12_logout_clears_state(artemis, evidence_shot):
    """Đăng xuất → về Sign-in; đăng nhập lại dữ liệu user còn nguyên (Firestore, không local cache giả)."""
    result = await artemis.run(
        f"Trong app {APP_PACKAGE} đang đăng nhập: tìm nút 'Đăng xuất' (Home/Settings), xác nhận, "
        "chờ về màn 'Đăng nhập với Google'. Sau đó đăng nhập lại bằng account @fpt.edu.vn, "
        "mở tab 'Việc cần làm' và xác nhận task 'E2E-F2' (nếu từng tạo) vẫn còn."
    )
    assert result.succeeded, f"ARTEMIS fail: {result.error or result.status}"
    evidence_shot("TC-12")
