## 1. Mode and Light Inventory

- [ ] 1.1 Add the `downstairs_mode` input select with `normal`, `bedtime`, and `pause` options.
- [ ] 1.2 Create the explicit managed-light group with the rooms and lights listed in the specification.

## 2. Timeout Behavior

- [ ] 2.1 Add the normal-mode timeout automation with a one-hour per-light threshold.
- [ ] 2.2 Add the bedtime-mode timeout automation with a ten-minute per-light threshold.
- [ ] 2.3 Ensure each timeout automation evaluates managed lights independently and honors the current mode, including mode changes and `pause`.

## 3. Bedtime Activation

- [ ] 3.1 Add a separate 21:00 automation that sets `downstairs_mode` to `bedtime`.
- [ ] 3.2 Update the Emily sleep automation to set `downstairs_mode` to `bedtime` while preserving its existing behavior.

## 4. Emily Door Lighting

- [ ] 4.1 Update the Emily door automation so an opening in `bedtime` mode turns on the downstairs bathroom and pool table room lights.

## 5. Validation

- [ ] 5.1 Run Home Assistant configuration validation.
- [ ] 5.2 Exercise normal, bedtime, pause, mode-change, simultaneous-light, and Emily-door scenarios, including the negative cases for normal and pause door openings.