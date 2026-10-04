# Proposal

## Why

Make HA and Google Assistant reliably reflect and control the stair and hallway lights:
- Each lamp has exactly one HA entity, showing its true state.
- On and off commands never act as toggles.
- Smart-switch buttons that power no lamp control their lamp remotely and show its state, without needing HA.

Also fix status LEDs that stay on when the device is healthy.

Context:
- The pooltable-stairs "Hallway Light" channel has no power sensing, so HA guesses its state and every command toggles the relay.
- Testing confirmed WB3S P9 is the 6952HA channel 2 power-status pin (CB3S P8 at the same module position). P9 works on pooltable-stairs. On hallway-stairs it toggles constantly, where it senses the same lamp that pooltable-stairs ch1 senses reliably.
- Three buttons are wired to no lamp:
  - kitchen hallway, for the lamp on the entry switch;
  - hallway-stairs landing, for the pool room Landing lamp;
  - laundry-door ch3, for the back stairs lamp.

## What Changes

- Pooltable-stairs ch2 gains power sensing. Both channels are renamed: "Internal Stairs Light" (ch1) and "Downstairs Hallway Light" (ch2).
- Hallway-stairs ch2 (the same lamp as pooltable-stairs ch1) is removed from HA; its button still switches the lamp locally.
- Entry "Hallway Entry" is renamed "Hallway Light".
- Power-sensed lights report their sensed state from boot. They also expose edge-count diagnostics for an observation period.
- Buttons with no lamp become **remote buttons**, talking directly to the target device over UDP on the existing Wi-Fi:
  - A press toggles the target lamp.
  - The target broadcasts its state, and the remote shows it on its button LED.
  - Remote lights are disabled diagnostic entities in HA, for debugging only.
  - Remotes and their targets:
    - kitchen "Hallway Kitchen" → "Hallway Remote", target Hallway Light;
    - hallway-stairs "Stair Bottom Landing Light" → "Landing Remote", target pool room "Landing";
    - laundry-door "Stairs" → "Back Stairs Remote", target "Back Stairs Light".
- **BREAKING**: the `light_N_group`/`switch_N_group` mechanism (devices calling HA actions) is removed, which retires `group.hallway_lights`.
- Sara Office (2-way hardware, no remote switch) becomes a plain light. Its state matches the lamp, including after a reboot.
- The 6914HA series 3 status LED (Emily, Spare Bedroom; always on) moves to its real pin, P22.
- **BREAKING**: renamed and removed entities get new HA entity IDs or disappear. References are updated by the HA handoff.
- HA-side work is handed to the "linked lights update" agent (see `ha-handoff.md`). No HA config is changed by this change.

## Capabilities

### New Capabilities
- `two-way-light-sensing`: state reporting, idempotent control and diagnostics for lights with power-status sensing.
- `remote-light-buttons`: buttons with no lamp control a target lamp on another device directly, and show its state.
- `device-status-led`: status LED is off when the device is healthy.

### Modified Capabilities
None.

## Impact

- ESPHome:
  - Packages:
    - `packages/lights-6903ha-*.yaml`, `packages/lights-6904ha-*.yaml`, `packages/lights-6911-6912ha-common.yaml`, `packages/lights-6914ha-series3.yaml`;
    - new: `packages/lights-6952ha-sensed.yaml`, `packages/lights-6952ha-unsensed.yaml`, `packages/lights-6951ha.yaml`, `packages/udp-link-target.yaml`, `packages/udp-link-remote.yaml`;
    - removed: `packages/lights-6952ha.yaml`.
  - Devices: `lights-pooltable-stairs.yaml`, `hallway-stairs.yaml`, `lights-back-stairs.yaml`, `lights-laundry-door.yaml`, `lights-kitchen.yaml`, `lights-entry.yaml`, `lights-pooltable-room.yaml`, `lights-sara-office.yaml`, `lights-emily.yaml`, `lights-spare-bedroom.yaml`.
- HA (master branch, via delegated agent):
  - retiring `group.hallway_lights`;
  - "Hallway" area;
  - entity cleanup and reference updates;
  - Google exposure.
- `TESTING.md`: physical test items.
