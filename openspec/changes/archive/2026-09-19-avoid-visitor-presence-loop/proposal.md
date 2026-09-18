## Why

Visitor presence currently makes `group.family` appear home, which immediately triggers logic that clears visitor presence. Visitor presence should behave like family presence without resetting itself.

## What Changes

- Keep `group.family` as the shared presence source for household automations.
- Clear visitor presence only when another person arrives home.

## Capabilities

### New Capabilities

- `visitor-presence`: Visitor presence participates in aggregate family presence and resets when a real person arrives without feedback loops.

## Impact

Visitor presence and holiday-light automations will be separated within `packages/holiday_lights/`.