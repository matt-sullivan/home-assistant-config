## Why

Turn off lights left on during the day while leaving bedroom lights on when people are likely present in the evening and at night, base all light behavior on the single downstairs mode, and bring the internal stairs light under timeout management.

## What Changes

- Add an `evening` downstairs mode, entered 30 minutes before sunset; rename `normal` to `daytime`, entered 30 minutes after sunrise instead of 06:00.
- Classify downstairs lights as rarely occupied at night, bedroom, or unmanaged, each with its own timeouts per mode.
- Emily's bedroom lights, including her main light, time out only during the day; her main light no longer times out in the evening or at bedtime.
- Add the internal stairs and spare bedroom lights to the rarely-occupied lights.
- Rename `pause` to `pause_until_changed`; it persists until changed by a user, and scheduled and scripted mode changes no longer override it.
- Add `pause_until_tomorrow`, which behaves like `pause_until_changed` but ends when `daytime` next begins.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `downstairs-light-management`: adds `evening` mode and its activation, renames `pause` to `pause_until_changed` and makes it persist, adds `pause_until_tomorrow`, light categories and bedroom-light timeouts, and internal stairs membership.

## Impact

- `groups.yaml` managed-light group.
- `packages/common/downstairs_light_management.yaml` input select and automations.
- Scheduler schedules for mode transitions.
- `scripts.yaml` Emily sleep script.
