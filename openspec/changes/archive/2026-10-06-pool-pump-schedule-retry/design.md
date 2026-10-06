## Context

- `switch.pool_pool_pump` uses the Tuya cloud integration. Its state is updated from device reports rather than set optimistically, so a failed command leaves the state unchanged.
- The scheduler custom component triggers the pump through two daily schedules, "Pool Pump On" (`switch.schedule_pool_pump_on`) and "Pool Pump Off" (`switch.schedule_pool_pump_off`). Each currently calls `switch.turn_on` or `switch.turn_off` directly. Scheduler service calls are non-blocking.
- The Tuya SDK silently drops a command identical to one sent to the same device less than 10 s earlier, so retries must be at least 10 s apart.
- Tuya command failures raise non-`HomeAssistantError` exceptions, such as `tuya_sharing.exceptions.ApiRequestException` and `urllib3` `MaxRetryError`.

## Goals / Non-Goals

**Non-Goals:**
- Continuous enforcement of the schedule between transitions, which would override manual control.
- Any restart-specific handling, such as detecting, reporting or applying a transition missed while Home Assistant was down.
- Moving to local Tuya control.

## Decisions

### Retry script called by the scheduler
New script `script.pool_pump_set_state` with field `target` (`on`/`off`). Both scheduler entries are changed to call it instead of `switch.turn_*`. The change is made through the scheduler UI or the `scheduler.edit` service, never by editing `.storage`.
- Alternative: replace the scheduler with automations driven by `input_datetime` helpers. Rejected because it would drop the scheduler UI the user manages times with.

Script logic:
- `mode: restart`, so the next scheduled transition supersedes an in-progress one.
- Repeat while the pump is not in the `target` state and fewer than 10 attempts have run:
  - Send one command.
  - Wait up to 60 s for the pump state to equal `target`, which also paces the retries at one per minute.
- If the pump is still not in the `target` state after the loop, notify `notify.admins`.

### Commands isolated in a separate fire-and-forget script
Each attempt starts `script.pool_pump_command` (field `target`) via `script.turn_on`, which calls `switch.turn_on`/`turn_off`. Tuya exceptions then abort only that inner run and are logged, and the retry loop continues.
- Alternative: `continue_on_error: true`. Rejected because it only suppresses `HomeAssistantError`, so Tuya's exceptions would still abort the loop.

### Pump switch state as the success signal
Success is judged by the pump's switch state, not its power sensor. The switch state reflects the device's own report, and power can lag or read low during priming.

### Placement
Both scripts go in a new package file, `packages/raspipool/pool_pump_schedule.yaml`.

## Risks / Trade-offs

- [If a scheduled command fails and you manually issue the same command, e.g. "off" while the pump is already off, the state doesn't change and retries continue] → Retries end after 10 minutes. You can also stop them by turning off `script.pool_pump_set_state`.
