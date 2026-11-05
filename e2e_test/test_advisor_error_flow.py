"""Verified Lab 3 cases; observations asserted from TaskResult.output JSON."""
import pytest
from conftest import APP_PACKAGE, require_artemis, skip_without_adb
from observations import equals, contains_text
pytestmark = [skip_without_adb, pytest.mark.e2e]


@require_artemis
async def test_TC_08_advisor_course_question(artemis):
    observed = await artemis.run(
        "From Home open Cố vấn học tập. Choose Môn học, ask 'Tư vấn môn PRM323', accept the question consent if shown. Wait for the real reply and report its exact text; it must ground credits/prerequisites in Firebase and disclose missing personal data.",
        {'reply': 'literal reply text'},
    )
    assert 'PRM323' in observed['reply']
    assert 'tín chỉ' in observed['reply']
    assert 'Nguồn:' in observed['reply']

@require_artemis
async def test_TC_09_empty_search_recovery(artemis):
    observed = await artemis.run(
        'From Home open Lộ trình, clear old search and search ZZZ_NO_COURSE_20261104. Verify zero course rows and empty-state text. Clear search and verify courses return. Report both counts and literal empty message.',
        {'empty_count': 'integer', 'empty_message': 'literal empty message', 'recovered_count': 'integer'},
    )
    equals(observed,'empty_count',0)
    assert 'Không tìm thấy' in observed['empty_message']
    assert type(observed['recovered_count']) is int and observed['recovered_count']>0
