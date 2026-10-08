## Context

Downstairs timeouts use `group.downstairs_managed_lights` and two template-triggered automations in `packages/common/downstairs_light_management.yaml`. Mode transitions at 21:00 and 06:00 are Scheduler-component schedules. All of Emily's lights are in the `toy_room` area (named "Emilys Bedroom"), mostly via their device area. `light.emily_sign`, like `light.emily_makeup`, has a "light back on" automation. `light.internal_stairs` is on the same ESPHome device as the downstairs hallway light.

## Goals / Non-Goals

**Goals:**

- All light behavior keys off `input_select.downstairs_mode`; no automation reads sun position directly.
- Rarely-occupied lights are `group.downstairs_managed_lights`; bedroom lights are selected by area so no extra list needs maintaining.

**Non-Goals:**

- Whole-house modes, a separate adults-bedtime mode, or label-based categories (later change: label areas by category, with per-light label overrides).

## Decisions

### Add `evening` option and sun-offset Scheduler schedules

Rename the `normal` option to `daytime` and add `evening`, ordered chronologically before the pause options. Create a Scheduler schedule at sunset −30 min that selects `evening`, with a condition that the mode is `daytime` so it doesn't cancel `pause_until_changed` or an early `bedtime`. The 06:00 schedule moves to sunrise +30 min and selects `daytime` instead of `normal`; the 21:00 schedule is otherwise unchanged. Alternative: a package automation with a sun trigger — rejected to keep all mode transitions in one place.

### Pause options

Rename the `pause` option to `pause_until_changed` and add `pause_until_tomorrow`. The 21:00 Scheduler schedule and the Emily sleep script's mode selection get mode-is-not-`pause_until_changed` and mode-is-not-`pause_until_tomorrow` conditions; the script's condition wraps only the mode selection so the rest of the script still runs. The morning schedule gets only a mode-is-not-`pause_until_changed` condition. Timeout and door automations act only in modes they name, so they need no change for `pause_until_tomorrow`. Selecting a mode on the dashboard is the way to leave `pause_until_changed`. Alternative: disabling the schedules and automations that set the mode while away — rejected as easy to get wrong.

### One-hour timeout automation selects lights by mode

The existing normal timeout automation (`downstairs_lights_normal_timeout`) becomes the one-hour timeout for both `daytime` and `evening`. Its light list depends on the mode:

- `daytime`: `group.downstairs_managed_lights` members plus bedroom lights.
- `evening`: `group.downstairs_managed_lights` members only.

Bedroom lights are `area_entities('toy_room')` filtered to `light.*`, minus `light.emily_makeup` and `light.emily_sign`. Use the area id rather than its name so renaming the area doesn't break it. Disabled entities have no state and are skipped.

Template triggers can't use automation variables, so the trigger and action share the list via a macro, `macro_one_hour_lights(mode)` in `custom_templates/downstairs_lights.jinja` (imported with `as_function`); `homeassistant.reload_custom_templates` is required after editing it. Threshold, per-light evaluation and `mode: parallel` are unchanged. The door automation already requires `bedtime`, so it needs no change.

Alternatives: a separate bedroom automation — rejected because it duplicates the one-hour timeout and differs only in light selection; a second group — rejected because it needs manual upkeep.

### Update rarely-occupied group membership

Add `light.internal_stairs` and `light.spare_bedroom_spare_bedroom_light` to and remove `light.emily_lights_emily_main` from `group.downstairs_managed_lights`; the main light is then selected as a bedroom light. Groups must be reloaded after editing `groups.yaml`; otherwise the running group keeps the old members.

## Risks / Trade-offs

- [Any new light placed in Emily's area becomes a bedroom light] → intended; add it to the exclusion list if it must never turn off.
- [A forgotten `pause_until_changed` disables all timeouts indefinitely] → use `pause_until_tomorrow` for one-off occasions; the mode is visible on the dashboard Quick Access tab.
- [Each future mode-setting source must skip both pause options] → two conditions per source.
- [Scheduler schedules live in `.storage`, not git] → existing trade-off from the original change; document the evening schedule in project docs.
