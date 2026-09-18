## Purpose

Provide predictable automatic management for downstairs lights when occupancy sensors are unavailable, including mode-based lighting when Emily opens her door.

## Requirements

### Requirement: Downstairs mode controls managed-light timeout policy

The system SHALL provide a single downstairs mode with the values `normal`, `bedtime`, and `pause`.

The managed lights SHALL include the pool table room, downstairs bathroom, downstairs hallway, laundry, Emily's bedroom lights except `light.emily_makeup`, and downstairs deck.

`light.emily_makeup` SHALL remain outside automatic timeout management because its required always-powered behavior turns it back on shortly after it is switched off.

When the downstairs mode is `normal`, each managed light that remains on for at least one hour SHALL be turned off.

When the downstairs mode is `bedtime`, each managed light that remains on for at least ten minutes SHALL be turned off.

When the downstairs mode is `pause`, managed lights SHALL NOT be turned off by this automatic timeout behavior, regardless of how long they remain on.

Timeout evaluation SHALL apply independently to each managed light and SHALL consider the selected mode when the timeout condition is evaluated, including when the mode changes while a light is already on.

#### Scenario: Normal mode expires a managed light

- **WHEN** a managed light remains on for at least one hour while downstairs mode is `normal`
- **THEN** that light is turned off

#### Scenario: Bedtime mode expires a managed light

- **WHEN** a managed light remains on for at least ten minutes while downstairs mode is `bedtime`
- **THEN** that light is turned off

#### Scenario: Bedtime mode catches up an existing light

- **WHEN** a managed light has already been on for at least ten minutes and downstairs mode changes to `bedtime`
- **THEN** that light is eligible to be turned off during the next timeout evaluation

#### Scenario: Normal mode does not apply bedtime expiry

- **WHEN** a managed light has been on for ten minutes but less than one hour while downstairs mode is `normal`
- **THEN** the light remains on

#### Scenario: Pause mode prevents automatic expiry

- **WHEN** a managed light remains on while downstairs mode is `pause`
- **THEN** the light remains on until it is turned off by another action

#### Scenario: Pause mode protects an already-running light

- **WHEN** a managed light has exceeded a normal or bedtime timeout and downstairs mode changes to `pause` before the next timeout evaluation
- **THEN** the timeout behavior does not turn off that light

#### Scenario: Managed lights are evaluated independently

- **WHEN** two managed lights have different on durations
- **THEN** each light is turned off only when its own active-mode timeout is reached

### Requirement: Downstairs bedtime activation sources remain separate

The system SHALL set downstairs mode to `bedtime` at 21:00 each day and to `normal` at 06:00 each day.

The system SHALL set downstairs mode to `bedtime` when Emily's sleep automation runs.

The system SHALL allow a future explicit button or control to set downstairs mode to `bedtime`.

#### Scenario: Scheduler bedtime begins

- **WHEN** the local time reaches 21:00
- **THEN** downstairs mode is set to `bedtime`

#### Scenario: Scheduler normal mode begins

- **WHEN** the local time reaches 06:00
- **THEN** downstairs mode is set to `normal`

#### Scenario: Emily sleep action begins bedtime

- **WHEN** Emily's sleep automation runs
- **THEN** downstairs mode is set to `bedtime` and the sleep automation's existing bedroom behavior continues

### Requirement: Emily door lighting follows downstairs mode

The system SHALL turn on the downstairs bathroom light and pool table room light when Emily's door opens while downstairs mode is `bedtime`.

The door-triggered lighting SHALL not change the timeout policy.

#### Scenario: Emily opens her door in bedtime mode

- **WHEN** Emily's door changes to open while downstairs mode is `bedtime`
- **THEN** the downstairs bathroom and pool table room lights are turned on

#### Scenario: Emily opens her door in normal mode

- **WHEN** Emily's door changes to open while downstairs mode is `normal`
- **THEN** the door-triggered lighting does not turn on those lights

#### Scenario: Emily opens her door in pause mode

- **WHEN** Emily's door changes to open while downstairs mode is `pause`
- **THEN** the door-triggered lighting does not turn on any lights
