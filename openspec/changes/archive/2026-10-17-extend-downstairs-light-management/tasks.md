## 1. Configuration

- [x] 1.1 In `groups.yaml`, add `light.internal_stairs` to and remove `light.emily_lights_emily_main` from `group.downstairs_managed_lights`; reload groups and verify the running group's members match the file.
- [x] 1.2 Update `packages/common/downstairs_light_management.yaml`:
  - In `input_select.downstairs_mode`, rename `normal` to `daytime` and `pause` to `pause_until_changed`, and add `evening` and `pause_until_tomorrow`.
  - Update the existing timeout automation templates from `normal` to `daytime`.
  - Change the existing normal timeout automation (`downstairs_lights_normal_timeout`) into the mode-based one-hour timeout per design (`daytime` and `evening`, bedroom lights in `daytime` only).
  - Run `ha core check`, reload input selects and automations, and verify the options are, in this order (dashboard display order), `daytime`, `evening`, `bedtime`, `pause_until_tomorrow`, `pause_until_changed`.
- [x] 1.3 Create the Scheduler evening schedule at sunset −30 min selecting `evening` with a mode-is-`daytime` condition; verify its next trigger is 30 minutes before the next sunset.
- [x] 1.4 Add pause conditions per design: not `pause_until_changed` or `pause_until_tomorrow` on the 21:00 schedule and the mode selection in `script.emily_sleep_time` (`scripts.yaml`); not `pause_until_changed` on the morning schedule, which also moves from 06:00 to sunrise +30 min and selects `daytime`; verify its next trigger. Run `ha core check` and reload scripts.
- [x] 1.5 Add `light.spare_bedroom_spare_bedroom_light` to `group.downstairs_managed_lights` in `groups.yaml`; run `ha core check`, reload groups and verify the running group's members match the file.

## 2. Validation

- [x] 2.1 Render the one-hour timeout's light-list template for each mode and confirm `daytime` returns the group plus all Emily's bedroom lights except makeup and sign, and `evening` returns the group only.
- [x] 2.2 Verify each item (history/logbook or live test):
  - [x] Evening schedule in `daytime` sets `evening`; in `pause_until_changed`, `pause_until_tomorrow` or `bedtime` leaves the mode unchanged.
  - [x] In `pause_until_changed`, the 21:00 and morning schedules and Emily's sleep script leave the mode unchanged, and the sleep script's bedroom actions still run.
  - [x] In `pause_until_tomorrow`, the 21:00 schedule and sleep script leave the mode unchanged and the morning schedule sets `daytime`.
  - [x] In `pause_until_tomorrow`, no timeouts turn lights off and Emily door opening turns on no lights.
  - [x] Outside both pause options, the 21:00 and morning schedules and the sleep script still set the mode.
  - [x] Managed light on ≥1h in `evening` is turned off.
  - [x] Emily door opening in `evening` turns on no lights.
  - [x] Bedroom light (including main) on ≥1h in `daytime` is turned off.
  - [x] No bedroom light turned off in `evening`, `bedtime` or `pause_until_changed` (unused Emily lights skipped).
  - [x] Light bar left on overnight is turned off at the first timeout evaluation after the mode becomes `daytime`.
  - [x] Makeup and sign lights are never turned off by timeouts (sign skipped as unused).
  - [x] `light.internal_stairs` is turned off by one-hour and bedtime timeouts.
  - [x] `light.spare_bedroom_spare_bedroom_light` is turned off by one-hour and bedtime timeouts.
