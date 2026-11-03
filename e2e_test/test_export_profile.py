"""TC-10 PDF export/upload + TC-11 Remote Config (checklist §8.2; F-01, M-09/M-10)."""

import pytest

from conftest import APP_PACKAGE, require_artemis, skip_without_adb

pytestmark = [skip_without_adb, pytest.mark.e2e]


@require_artemis
async def test_TC_10_pdf_export_consent_upload(pro_artemis, logcat, evidence_shot):
    """Pro profile: Firebase Demo Area → Export & Upload PDF: consent → progress → URL.

    Nếu Storage bucket bị Spark chặn, app PHẢI báo lỗi thật (fail-loud) — assert nhánh đó."""
    logcat.start("TC-10")
    result = await pro_artemis.run(
        f"Trong app {APP_PACKAGE} đã đăng nhập: vào mục Cài đặt & Đồng bộ (Firebase Demo Area), "
        "chạm 'Export & Upload PDF' (hoặc nút xuất báo cáo). "
        "Xác nhận có dialog xin quyền chia sẻ (consent) TRƯỚC khi upload → đồng ý. "
        "Chờ progress xong. Trả về: (a) có consent dialog không, (b) upload thành hay lỗi, "
        "(c) nếu thành: chuỗi Download URL hiển thị; nếu lỗi: dòng chữ lỗi."
    )
    text = logcat.stop_and_text()
    assert result.succeeded, f"ARTEMIS fail: {result.error or result.status}"
    assert "Exception in" not in text, f"Crash khi export PDF:\n{text[-800:]}"
    evidence_shot("TC-10")


@require_artemis
async def test_TC_11_remote_config_values_visible(artemis, evidence_shot):
    """Demo Area hiển thị giá trị RC hiện hành (maintenance_mode/min_app_version) — phần before/after Console do user."""
    result = await artemis.run(
        "Vào Cài đặt & Đồng bộ (Firebase Demo Area). Đọc và trả về nguyên văn giá trị "
        "Remote Config hiển thị (maintenance_mode và min_app_version), kèm nhãn trạng thái."
    )
    assert result.succeeded, f"ARTEMIS fail: {result.error or result.status}"
    answer = str(getattr(result, "answer", "") or "")
    assert "maintenance" in answer.lower() or "bảo trì" in answer.lower(), (
        f"Không thấy maintenance_mode trong Demo Area: {answer}"
    )
    evidence_shot("TC-11")
