# Media room lamps with an all-on/all-off remote

Make the media room's two lamps, "Door" and "Interior", report and switch correctly in HA, and make the Media Room Remote an "all off if any on, else all on" button.

## Context

- The media room switch (6952HA) and the Media Room Remote (6951HA) are a standard 2-way pair for the Door lamp only. Interior is wired 1-way on the media room's ch2.
- The media room is configured unsensed, so HA shows relay state; after a remote press Door is wrong in HA.
- This board's ch2 sense path, or the wiring it was on, showed a fault before (`docs/deta-695xha-hardware.md`), so the sense inputs aren't trusted for control. UDP between the devices is reliable.
- The remote's button LED is rewired to a GPIO and is firmware-driven. The media room's button LEDs follow their channel's sense circuit.
- The remote's own HA light entities are already hidden.

## Goals

- HA shows each lamp's true state, including after remote presses.
- On/off commands to a lamp already in that state change nothing; each media room button, and each HA command, changes only its own lamp.
- A remote press turns both lamps off if either is on, otherwise both on.
- The remote's button LED is on when any lamp is on.
- Lamp control keeps working if a sense input fails, and sense faults show in HA diagnostics.

## Approach

The media room owns both lamps and takes their state from its relays. The remote's relay stays in one fixed position, so only the media room switches Door. A remote press is sent over the network, and the media room applies the group rule. The media room broadcasts whether any lamp is on, and the remote LED shows it. The sense inputs only feed diagnostics, including a count of switches they didn't confirm.

## Trade-offs and limits

- The remote does nothing when the network or the media room is down: it no longer switches Door through the 2-way wiring, so that the media room's relays always give the lamps' state.
- When the media room's state stops arriving, the remote LED keeps its last state.

## External impact

- HA: the media room lights become new entities named "Door" and "Interior"; the old "Light 1"/"Light 2" entities go. No HA automations, scripts, scenes or dashboards reference them.

## Capabilities

- `light-group-remote` (new)
