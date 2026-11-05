"""Verified Lab 3 cases; observations asserted from TaskResult.output JSON."""
import pytest
from conftest import APP_PACKAGE, require_artemis, skip_without_adb
from observations import equals, contains_text
pytestmark = [skip_without_adb, pytest.mark.e2e]


@require_artemis
async def test_TC_V5_session_log_capture(artemis, logcat):
    logcat.start('TC-V5')
    observed = await artemis.run(
        'From Home visit Trang chủ, Lộ trình, Việc cần làm and Ghi chú. Open a course detail and return to Ghi chú. Report literal visited tab names and final screen title. Do not modify records.',
        {'visited_tabs': 'array of actual tab labels', 'screen_title': 'literal final title'},
    )
    assert set(['Trang chủ','Lộ trình','Việc cần làm','Ghi chú']).issubset(set(observed['visited_tabs']))
    equals(observed,'screen_title','Ghi chú học tập')
    assert logcat.stop_and_text().strip()


@pytest.mark.exploratory
@pytest.mark.timeout(1800)
@require_artemis
async def test_TC_EXPLORATORY_20min(pro_artemis, auth_account):
    import time
    started=time.monotonic()
    observed=await pro_artemis.run(
        'Explore the app for 15-20 minutes on the dedicated test account. Cover all tabs, course detail tabs, academic input validation without saving fabricated grades, Advisor consent, Strategy, notifications, Sync Vault, error/recovery and Back behavior. Do not change billing, accounts or cloud configuration. Create only uniquely named E2E records if needed. Record every issue with reproduction steps and severity, or an empty issues list after actual exploration. Report screens visited.',
        {'issues':'array of {repro,severity,screen}','screens_visited':'array'}, timeout=1500)
    elapsed=time.monotonic()-started
    assert elapsed>=900, f'Exploration too short: {elapsed:.1f}s; never pad duration with fake results'
    assert isinstance(observed['issues'],list)
    assert len(set(observed['screens_visited']))>=8
