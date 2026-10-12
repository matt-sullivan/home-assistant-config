## Why

Air cons in fan only mode should keep running when a door is left open. Fan only doesn't heat or cool, so an open door wastes no energy, and turning it off just annoys whoever is using it.

## What Changes

- Door-open auto shutoff no longer applies while an air con is in fan only mode.
- If an air con switches from fan only to a heating/cooling mode while a door is open, the 5-minute open-door countdown starts from the mode switch.
- After a Home Assistant restart with a door already open, the countdown starts from startup instead of shutting off immediately.
- Shutoff still applies in all other non-off modes (heat, cool, auto, heat_cool, dry).

## Capabilities

### New Capabilities
- `air-con-door-shutoff`: when an air con is turned off because a door is open.

### Modified Capabilities
None.

## Impact

- `blueprints/automation/homeassistant/air_con_limits.yaml` (used by the Sara Office, Parents, Toby and Living Room air con automations).
