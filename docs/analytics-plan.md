# Lab 3 Analytics Plan

## Events

| Event | Trigger | Parameters (type) | Product question |
|---|---|---|---|
| `login` | Google sign-in succeeds | `method` (string) | How many users return each week? |
| `search` | User runs a search | `search_term` (string), `result_count` (int) | Which topics are searched most but exported least? |
| `view_course` | Course detail opens | `course_id` (string), `code` (string) | Which items are opened most after a search? |
| `prerequisite_check` | User taps prerequisite check | `course_id` (string), `is_eligible` (bool) | Which prerequisites are most often checked? |
| `task_create` | Task persists successfully | `category` (string) | Which categories get the most tasks? |
| `task_complete` | Task changes to completed | `task_id` (string), `course_id` (string) | How many tasks do users complete per week? |
| `note_create` | Note persists successfully | `course_id` (string), `content_length` (int) | How many notes do users create per week? |
| `advisor_query` | User submits advisor question | `topic` (string) | Which advisor questions are most common? |
| `sync_triggered` | Manual sync reload completes | `trigger_type` (string) | How often do users sync? |
| `export_report` | PDF export succeeds/fails | `status` (string), `file_size_kb` (int), `duration_ms` (int) | How many exports lead to storage? |

## Flow mapping

| Flow | Event | Measurement |
|---|---|---|
| Sign-in | `login` | Weekly active users |
| Search course | `search`, `view_course` | Popular topics, drop-off at search |
| Curriculum flow | `view_course`, `prerequisite_check` | Prerequisite awareness |
| Study Plan | `task_create`, `task_complete`, `note_create` | User engagement |
| Export | `export_report` | Export success rate |
| Sign-out | `logout` (if implemented) | Session duration proxy |

## Privacy and correctness

- No email, display name, message body, token, or document content enters event parameters.
- Analytics calls use `AnalyticsService`, not concrete Firebase type checks.
- Course lookup and prerequisite predicates are pure; no events fire during `build`.
- `setUserId` runs after authenticated Google sign-in.

## Manual verification

1. Build and install debug APK with valid Firebase configuration.
2. Enable Analytics DebugView for test device.
3. Execute each trigger once.
4. Confirm event name and parameters.
5. Repeat a rebuild without user action; confirm no duplicate course or prerequisite events.
6. Record screenshots in `evidence/firebase/analytics/` without exposing account secrets.

Code tests prove call wiring only. They do not prove Firebase Console delivery.
