# Lab 3 Analytics Plan

> Tên event dưới đây **khớp 1-1 với code** (`lib/services/analytics_service.dart`,
> 13 helpers funnel qua `logEvent` + PII filter). Cột Parameters là những gì
> `logEvent` thực gửi. DebugView bật bằng adb setprop (xem README —
> firebase_analytics 13.x không còn `enableDebugMode()`).

| Event | Trigger | Parameters (type) | Product question |
|---|---|---|---|
| `login_success` | Google sign-in succeeds | `method` (string) | How many users return each week? |
| `search_course` | User runs a search (debounced) | `query_length` (int) | Which topics are searched most but exported least? |
| `course_view` | Course detail opens | `course_id` (string), `code` (string) | Which items are opened most after a search? |
| `prerequisite_check` | User taps prerequisite check | `course_id` (string), `is_eligible` (bool) | Which prerequisites are most often checked? |
| `task_create` | Task persists successfully | `category` (string) | Which categories get the most tasks? |
| `task_complete` | Task changes to completed | `task_id` (string), `course_id` (string) | How many tasks do users complete per week? |
| `note_create` | Note persists successfully | `course_id` (string), `content_length` (int) | How many notes do users create per week? |
| `advisor_query` | User submits advisor question | `topic` (string) | Which advisor questions are most common? |
| `sync_triggered` | Manual sync reload completes | `trigger_type` (string) | How often do users sync? |
| `export_report` | PDF export succeeds/fails | `status` (string), `file_size_kb` (int), `duration_ms` (int) | How many exports lead to storage? |
| `notification_received` | Push handled (foreground banner or tap) | `type` (string), `action` (string: 'foreground'/'tap') — không chứa nội dung message | Do pushes drive vault returns? |
| `strategy_view` | User opens Strategy Simulator (tap 'Mô phỏng GPA') | `source` (string: 'advisor'/'direct') | Do learners who see advice go on to plan with the simulator? (guide §6.4 'xem strategy') |
| `strategy_preset_applied` | User applies a preset scenario in the simulator | `preset` (string slug) | Which strategy scenarios do students actually try? (guide §6.4 'tạo strategy'; điểm mô phỏng KHÔNG được log — quy tắc PII) |

## Flow mapping

| Flow | Event | Measurement |
|---|---|---|
| Sign-in | `login_success` | Weekly active users |
| Search course | `search_course`, `course_view` | Popular topics, drop-off at search |
| Curriculum flow | `course_view`, `prerequisite_check` | Prerequisite awareness |
| Study Plan | `task_create`, `task_complete`, `note_create` | User engagement |
| Advisor/Strategy | `advisor_query`, `strategy_view`, `strategy_preset_applied` | Advice → planning conversion (rubric §6.4) |
| Sync & notifications | `sync_triggered`, `notification_received` | Cloud reliability, push effectiveness |
| Export | `export_report` | Export success rate |

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
