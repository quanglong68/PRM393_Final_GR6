"""Host-only parser tests; never counted as Android E2E passes."""
import sys
import unittest
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "e2e_test"))
from observations import parse_observation, equals, terminal_observation, contains_text

class ObservationContractTest(unittest.TestCase):
    def test_success_without_observation_fails(self):
        for output in (None, 'SUCCESS', {}, {'visible_text': ''}):
            with self.subTest(output=output), self.assertRaises(AssertionError):
                parse_observation(output)

    def test_fenced_json_and_observed_fields(self):
        observed = parse_observation('```json\n{"visible_text":"Remote Config", "enabled":false}\n```')
        equals(observed, 'enabled', False)

    def test_boolean_is_not_integer_and_missing_field_fails(self):
        for observed in ({'value': True}, {}):
            with self.subTest(observed=observed), self.assertRaises(AssertionError):
                equals(observed, 'value', 1)

    def valid_steps(self):
        return [{'session_id':'test-session', 'step_id':'final-id', 'step_number':2,
                 'action_taken':{'action':'report_task_status', 'args':{'status':'completed',
                   'explanation':'{"visible_text":"Remote Config", "enabled":false}'}}}]

    def test_sdk_missing_output_uses_exact_final_report(self):
        observed, evidence = terminal_observation(self.valid_steps(), 'test-session')
        equals(observed, 'enabled', False)
        self.assertEqual(evidence['step_id'], 'final-id')

    def test_terminal_action_can_return_observation_as_arguments(self):
        steps = self.valid_steps()
        steps[0]['action_taken']['args'] = {
            'status': 'completed',
            'explanation': 'The course is visible.',
            'visible_text': 'Lộ trình học tập',
            'course_codes': ['PRM323'],
        }
        observed, _ = terminal_observation(steps, 'test-session')
        self.assertEqual(observed, {
            'visible_text': 'Lộ trình học tập', 'course_codes': ['PRM323'],
        })

    def test_terminal_action_can_return_nested_fields(self):
        steps = self.valid_steps()
        fields = {'visible_text': 'Lộ trình học tập', 'course_codes': ['PRM323']}
        steps[0]['action_taken']['args'] = {
            'status': 'completed',
            'explanation': 'The course is visible.',
            'custom_fields': fields,
        }
        observed, _ = terminal_observation(steps, 'test-session')
        self.assertEqual(observed, fields)

    def test_other_session_cannot_supply_observation(self):
        with self.assertRaises(AssertionError):
            terminal_observation(self.valid_steps(), 'other-session')

    def test_nonterminal_action_after_report_is_not_completion(self):
        steps = self.valid_steps() + [{'session_id':'test-session', 'step_id':'later',
                                     'step_number':3,'action_taken':{'action':'click'}}]
        with self.assertRaises(AssertionError):
            terminal_observation(steps, 'test-session')

    def test_native_ui_evidence_takes_precedence_over_model_text(self):
        observed = {'visible_text':'fabricated label', 'native_visible_text':'Remote Config'}
        contains_text(observed, 'Remote Config')
        with self.assertRaises(AssertionError):
            contains_text(observed, 'fabricated label')

if __name__ == '__main__':
    unittest.main()
