## 1. Mode and Light Inventory

- [x] 1.1 Add the `downstairs_mode` input select with `normal`, `bedtime`, and `pause` options.
- [x] 1.2 Create the explicit managed-light group with the rooms and lights listed in the specification, excluding `light.emily_makeup`.

## 2. Timeout Behavior

- [x] 2.1 Add the normal-mode timeout automation with a one-hour per-light threshold.
- [x] 2.2 Add the bedtime-mode timeout automation with a ten-minute per-light threshold.
- [x] 2.3 Ensure each timeout automation triggers only when eligible work exists, evaluates managed lights independently, and honors the current mode, including mode changes and `pause`.

## 3. Bedtime Activation

- [x] 3.1 Create daily Scheduler-component schedules that set `downstairs_mode` to `bedtime` at 21:00 and `normal` at 06:00.
- [x] 3.2 Update the Emily sleep automation to set `downstairs_mode` to `bedtime` while preserving its existing behavior.

## 4. Emily Door Lighting

- [x] 4.1 Move the Emily door automation into the downstairs package and ensure an opening in `bedtime` mode turns on the downstairs bathroom and pool table room lights.

## 5. Validation

- [x] 5.1 Run Home Assistant configuration validation.
- [x] 5.2 Exercise normal, bedtime, pause, mode-change, simultaneous-light, and Emily-door scenarios, including the negative cases for normal and pause door openings.