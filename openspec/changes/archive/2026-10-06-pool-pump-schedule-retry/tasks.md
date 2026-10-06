## 1. Implementation

- [x] 1.1 Create `packages/raspipool/pool_pump_schedule.yaml` with `script.pool_pump_command` and `script.pool_pump_set_state` per design; verify `ha core check` passes and both scripts exist after reload.
- [x] 1.2 Change the "Pool Pump On"/"Pool Pump Off" scheduler actions to call `script.pool_pump_set_state` with `target: on`/`off` (scheduler UI or `scheduler.edit`); verify the scheduler switch `actions` attributes show the script.

## 2. Validation

"Plug offline" means the plug is unpowered at the wall and `switch.pool_pool_pump` shows `unavailable`. When restoring power, use a target opposite to the plug's power-up state (check the Smart Life app).

- [x] 2.1 Pump off, run `script.pool_pump_set_state` with `target: on`: the pump turns on after one command, and there is no notification.
- [x] 2.2 Pump already on, run with `target: on`: no command is sent (trace).
- [x] 2.3 Plug offline, run with `target: on`: the trace shows an attempt about every minute, and the loop continues after inner command errors.
- [x] 2.4 Continuing 2.3, restore power: the next retry turns the pump on, retrying stops, and there is no notification.
- [x] 2.5 Plug offline, run with `target: on`, then restore power and turn the pump on from HA before the next retry: retrying stops.
- [x] 2.6 Plug offline for more than 10 minutes, run with `target: on`: an admin notification names the failed transition.
- [x] 2.7 Plug offline, start `target: on` retries, then run `target: off`: the on run stops and the off run proceeds.
- [x] 2.8 Observe the next scheduled 10:00 and 16:00 transitions: the script trace runs and the pump changes state.

## 3. Wrap-up

- [x] 3.1 Update project documentation with the retry behaviour and the Tuya `continue_on_error` limitation; archive the change.
