"""Strict ARTEMIS SDK output parsing: status alone is never a passing assertion."""
import json
import re


def parse_observation(output):
    if isinstance(output, dict):
        result = output
    elif isinstance(output, str):
        text = output.strip()
        text = re.sub(r"^```(?:json)?\s*|\s*```$", "", text)
        try:
            result = json.loads(text)
        except json.JSONDecodeError as exc:
            raise AssertionError("ARTEMIS did not return the requested JSON observation") from exc
    else:
        raise AssertionError("Missing structured TaskResult.output; SUCCESS alone is insufficient")
    if not isinstance(result, dict) or not isinstance(result.get("visible_text"), str):
        raise AssertionError("Observation requires a literal visible_text string")
    if not result["visible_text"].strip():
        raise AssertionError("Empty visible_text is not evidence")
    return result


def equals(observation, key, value):
    assert key in observation, f"Missing reported field: {key}"
    assert type(observation[key]) is type(value), f"Wrong type for {key}"
    assert observation[key] == value, f"{key}: expected {value!r}, observed {observation[key]!r}"


def terminal_observation(steps, session_id):
    """Read the actual final report from this session when SDK output is absent.

    The step API can hold the structured observation in the terminal action's
    arguments or in its JSON explanation while TaskResult.output is absent.
    """
    assert isinstance(steps, list) and steps, 'No recorded ARTEMIS steps'
    assert all(step.get('session_id') == session_id for step in steps), 'Cross-session trace rejected'
    final = max(steps, key=lambda step: step['step_number'])
    action = final.get('action_taken') or {}
    assert action.get('action') == 'report_task_status', 'No terminal report action'
    args = action.get('args') or {}
    assert args.get('status') == 'completed', 'Terminal report did not complete'
    output = args.get('custom_fields', args.get('explanation'))
    if 'visible_text' in args:
        output = {key: value for key, value in args.items()
                  if key not in {'status', 'explanation'}}
    return parse_observation(output), {
        'session_id': session_id, 'step_id': final['step_id'],
        'step_number': final['step_number'], 'action_taken': action,
    }


def contains_text(observation, text):
    visible = observation.get('native_visible_text', observation['visible_text'])
    assert text.casefold() in visible.casefold(), (
        f"Expected visible text {text!r}; observed {visible!r}"
    )
