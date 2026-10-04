# remote-light-buttons Specification

## Purpose
Smart-switch buttons wired to no lamp toggle a target lamp on another device and show its state on the button LED. They talk directly to that device, so they keep working without HA.

## Requirements

### Requirement: Remote buttons
These buttons power no lamp. Each SHALL toggle its target lamp, and each target lamp SHALL have exactly one HA light entity. Remote lights SHALL be diagnostic HA entities, recorded for debugging and not used for control.

| Button | Remote | Target lamp |
|---|---|---|
| kitchen ch2 | "Hallway Remote" | entry "Hallway Light" |
| hallway-stairs ch1 | "Landing Remote" | pool room "Landing" |
| laundry-door ch3 | "Back Stairs Remote" | "Back Stairs Light" |

#### Scenario: Remote button press
- **WHEN** a remote button is pressed once
- **THEN** its target lamp SHALL toggle exactly once, whatever state the remote last saw

#### Scenario: HA unavailable
- **WHEN** a remote button is pressed while HA is down
- **THEN** its target lamp SHALL toggle

#### Scenario: Transient packet loss
- **WHEN** some of a press's messages are lost within its ~600 ms retry window
- **THEN** the target lamp SHALL still toggle exactly once

### Requirement: Remote state mirror
Each remote light SHALL mirror its target lamp's state. The button LED shows it where the LED follows the relay (kitchen ch2, laundry-door ch3; not hallway-stairs ch1, whose LED is sense-driven).

#### Scenario: Remote follows lamp
- **WHEN** the target lamp changes state from any source (its own button, a 2-way remote switch, HA, Google Assistant, or a remote)
- **THEN** the remote SHALL match the target's state within about a second

#### Scenario: Missed update or remote reboot
- **WHEN** a remote misses a state update or reboots
- **THEN** it SHALL match the target's state within 30 s

### Requirement: Loop-free and decoupled
- A target SHALL toggle only on a new remote press.
- State updates SHALL never cause a toggle.
- Targets SHALL NOT be configured with their remotes.

#### Scenario: Target state change
- **WHEN** a target lamp changes state
- **THEN** no lamp SHALL toggle as a result

#### Scenario: Device reboot
- **WHEN** any target or remote device boots
- **THEN** no lamp SHALL toggle

### Requirement: Link diagnostics
Each target SHALL expose its counts of accepted and duplicate toggles. Each remote SHALL expose the time since it last received its target's state.

#### Scenario: Healthy link
- **WHEN** a remote button is pressed with no packet loss
- **THEN** the target's toggle count SHALL rise by 1 and its duplicate count by 4

#### Scenario: Broadcasts not arriving
- **WHEN** a remote stops receiving its target's state
- **THEN** its state age SHALL keep rising past 30 s
