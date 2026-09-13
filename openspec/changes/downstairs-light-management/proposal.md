## Why

Emily needs downstairs lights when she gets up at night, but lights are often left on indefinitely. Manage them automatically without occupancy sensors while avoiding unnecessary shutoffs.

Use `bedtime` to provide short-lived lighting when Emily opens her door, `normal` for a longer daytime timeout, and `pause` when lights must remain on.

## What Changes

- Add a downstairs mode with `normal`, `bedtime` and `pause` states.
- Automatically manage a defined set of downstairs lights.
- Turn managed lights off after one hour in normal mode and after ten minutes in bedtime mode.
- Turn on the downstairs bathroom and pool table room lights when Emily's door opens in `bedtime` mode, without turning them on in `normal` or `pause` mode.
- Allow bedtime mode to be activated at 21:00, by Emily's sleep automation, or by a future explicit control.

## Capabilities

### New Capabilities

- `downstairs-light-management`: Mode-based timeout management and mode-based Emily door lighting.

### Modified Capabilities

None.

## Impact

- Adds a downstairs mode helper, managed-light inventory, and related automations.
- Updates Emily's sleep and door-triggered lighting behavior.