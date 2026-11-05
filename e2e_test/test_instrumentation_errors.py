"""Verified Lab 3 cases; observations asserted from TaskResult.output JSON."""
import pytest
from conftest import APP_PACKAGE, require_artemis, skip_without_adb
from observations import equals, contains_text
pytestmark = [skip_without_adb, pytest.mark.e2e]


@require_artemis
async def test_TC_S_01_auth_domain_reject(artemis, auth_account):
    observed = await artemis.run(
        'On this dedicated test device sign out, open native Google picker and choose its secondary non-FPT test account. If unavailable report account_available=false. Verify visible domain rejection and no private Home. Restore the dedicated FPT test account before finishing.',
        {'account_available': 'boolean', 'domain_error': 'literal error', 'foreign_home_visible': 'boolean', 'restored': 'boolean'},
    )
    if not observed['account_available']: pytest.skip('No secondary foreign test account; not a pass')
    assert '@fpt.edu.vn' in observed['domain_error']
    equals(observed,'foreign_home_visible',False)
    equals(observed,'restored',True)

@require_artemis
async def test_TC_S_06_remote_config_offline_defaults(artemis, restore_network):
    observed = await artemis.run(
        'From Home enable airplane mode using Android UI, reopen app and verify it renders Home or sign-in without fatal error. Cached RC flags may apply; do not infer server updates. Restore airplane mode OFF before finishing.',
        {'rendered': 'boolean', 'airplane_mode_restored': 'boolean'},
    )
    equals(observed,'rendered',True)
    equals(observed,'airplane_mode_restored',True)

@require_artemis
async def test_TC_X_06_fcm_foreground_center(artemis):
    observed = await artemis.run(
        'From Home open Trung tâm thông báo. Report actual notification count, first title if present, and literal empty message if zero. Do not claim push delivery simply because the center opens.',
        {'notification_count': 'integer', 'first_title': 'string', 'empty_message': 'string'},
    )
    assert type(observed['notification_count']) is int and observed['notification_count']>=0
    if observed['notification_count']==0: assert observed['empty_message']
    else: assert observed['first_title']

@require_artemis
async def test_TC_S_07_fcm_native_notification_settings(artemis):
    observed = await artemis.run(
        'On Android open App info for FPTU Second Brain then its Notifications settings. Read the actual permission status without changing it; return to the app. Report native settings screen label, permission status and whether app renders afterwards.',
        {'native_screen': 'literal Android screen label', 'permission_state': 'allowed or denied', 'app_rendered': 'boolean'},
    )
    assert observed['native_screen']
    assert observed['permission_state'] in {'allowed','denied'}
    equals(observed,'app_rendered',True)

@require_artemis
async def test_TC_14_analytics_events_log(artemis, logcat):
    logcat.start('TC-14')
    observed = await artemis.run(
        'From Home open Lộ trình, clear old query, type PRM, wait until results settle, open PRM323. Report shown course code and the final screen title. The test runner checks the actual analytics log for search_course and course_view.',
        {'course_code': 'literal course code'},
    )
    equals(observed,'course_code','PRM323')
    text=logcat.stop_and_text()
    assert 'Logged event: search_course' in text
    assert 'Logged event: course_view' in text

@require_artemis
async def test_TC_13_fcm_token_registered(artemis, logcat):
    logcat.start('TC-13')
    observed = await artemis.run(
        'Cold-start FPTU Second Brain with its existing session and network enabled; do not change accounts or permission. End on Home and report the final app title. The runner checks token registration logs, not token contents.',
        {'screen_title': 'literal title'},
    )
    equals(observed,'screen_title','FPTU Second Brain')
    assert 'Registered FCM token' in logcat.stop_and_text()
