"""Exploratory session 15–30′ (guide tr.23) + runner ghi pass rate 3 runs.

Chạy:
    uv run pytest e2e_test -m e2e                       # 1 lượt thường
    uv run pytest e2e_test --timeout=420                # batch 3 lần: chạy lệnh này 3 lần
Kết quả + evidence đổ ra ../evidence/artemis/ (logs/, *.png) — đặt tên TC-* theo §2 test-plan.
"""

import time
from datetime import datetime

import pytest

from conftest import EVIDENCE_DIR, require_artemis, skip_without_adb

pytestmark = [skip_without_adb, pytest.mark.e2e]


@require_artemis
async def test_TC_EXPLORATORY_30min(pro_artemis, evidence_shot):
    """Phiên khám phá: agent Pro tự do tìm bug trong khung thời gian, báo cáo có kiểm chứng."""
    started = datetime.now()
    result = await pro_artemis.run(
        "Exploratory testing 20 phút trên 'FPTU Second Brain' (đã đăng nhập, có dữ liệu test): "
        "duyệt cả 4 tab + Notification Center + Cài đặt, thử các tương tác bất thường "
        "(quay màn hình khi loading, chạm nhanh 2 tab, lưu khi mất mạng, back giữa dialog). "
        "Mỗi phát vấn đề: chụp trạng thái, mô tả repro 1 dòng + mức nghiêm trọng. "
        "Kết thúc bằng danh sách phát hiện (hoặc 'KHÔNG phát hiện').",
    )
    duration_s = (datetime.now() - started).total_seconds()
    assert result.succeeded, f"ARTEMIS fail: {result.error or result.status}"
    assert duration_s >= 600, (
        f"Phiên quá ngắn ({duration_s:.0f}s) — guide tr.23 yêu cầu 15–30 phút."
    )
    evidence_shot("TC-EXPLORATORY-final")
    summary = getattr(result, "answer", "") or getattr(result, "summary", "") or str(result.status)
    (EVIDENCE_DIR / "exploratory-summary.md").write_text(
        f"# Exploratory session {datetime.now():%Y-%m-%d %H:%M}\n\n"
        f"Duration: {duration_s/60:.1f} phút · trace: {getattr(result, 'trace_id', '?')}\n\n"
        f"{summary}\n",
        encoding="utf-8",
    )


@require_artemis
async def test_TC_V5_session_log_capture(artemis, logcat, evidence_shot):
    """Capture logcat cả 1 phiên ngắn làm evidence TC-V5 (đóng nợ M10 NOT TESTED)."""
    stamp = int(time.time())
    logcat.start(f"TC-V5-session-{stamp}")
    await artemis.run("Duyệt lần lượt 4 tab của app 'FPTU Second Brain' rồi dừng ở tab Ghi chú.")
    text = logcat.stop_and_text()
    assert len(text.strip()) > 0, "logcat -s flutter rỗng — kiểm tra lại capture (M10 nợ TC-V5)"
    evidence_shot("TC-V5-end")
