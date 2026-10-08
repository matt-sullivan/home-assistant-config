## MODIFIED Requirements

### Requirement: Downstairs mode controls managed-light timeout policy

The system SHALL provide a single downstairs mode with the values `daytime`, `evening`, `bedtime`, `pause_until_changed`, and `pause_until_tomorrow`.

`pause_until_tomorrow` SHALL behave exactly as `pause_until_changed` everywhere in this capability, except that the next morning transition ends it. When set between midnight and the morning transition, it therefore ends that same morning; the name accepts this imprecision.

Downstairs lights SHALL be in one of these categories:

- Rarely occupied at night: the pool table room, downstairs bathroom, downstairs hallway, internal stairs, laundry, spare bedroom, and downstairs deck lights.
- Bedroom: every light in Emily's bedroom except `light.emily_makeup` and `light.emily_sign`, including lights later added to her bedroom.
- Unmanaged: `light.emily_makeup` and `light.emily_sign`. Their reported state does not reflect the true light state and they are automatically turned back on shortly after being switched off, so automatic timeouts SHALL NOT turn them off.

The term managed light below means a rarely-occupied light.

When the downstairs mode is `daytime` or `evening`, each managed light that remains on for at least one hour SHALL be turned off.

When the downstairs mode is `bedtime`, each managed light that remains on for at least ten minutes SHALL be turned off.

When the downstairs mode is `pause_until_changed`, managed lights SHALL NOT be turned off by this automatic timeout behavior, regardless of how long they remain on.

Timeout evaluation SHALL apply independently to each managed light and SHALL consider the selected mode when the timeout condition is evaluated, including when the mode changes while a light is already on.

#### Scenario: Daytime mode expires a managed light

- **WHEN** a managed light remains on for at least one hour while downstairs mode is `daytime`
- **THEN** that light is turned off

#### Scenario: Evening mode expires a managed light

- **WHEN** a managed light remains on for at least one hour while downstairs mode is `evening`
- **THEN** that light is turned off

#### Scenario: Bedtime mode expires a managed light

- **WHEN** a managed light remains on for at least ten minutes while downstairs mode is `bedtime`
- **THEN** that light is turned off

#### Scenario: Bedtime mode catches up an existing light

- **WHEN** a managed light has already been on for at least ten minutes and downstairs mode changes to `bedtime`
- **THEN** that light is eligible to be turned off during the next timeout evaluation

#### Scenario: Daytime and evening modes do not apply bedtime expiry

- **WHEN** a managed light has been on for ten minutes but less than one hour while downstairs mode is `daytime` or `evening`
- **THEN** the light remains on

#### Scenario: Pause mode prevents automatic expiry

- **WHEN** a managed light remains on while downstairs mode is `pause_until_changed`
- **THEN** the light remains on until it is turned off by another action

#### Scenario: Pause mode protects an already-running light

- **WHEN** a managed light has exceeded a one-hour or bedtime timeout and downstairs mode changes to `pause_until_changed` before the next timeout evaluation
- **THEN** the timeout behavior does not turn off that light

#### Scenario: Managed lights are evaluated independently

- **WHEN** two managed lights have different on durations
- **THEN** each light is turned off only when its own active-mode timeout is reached

### Requirement: Downstairs bedtime activation sources remain separate

The evening transition SHALL occur 30 minutes before sunset each day, and the morning transition 30 minutes after sunrise each day.

The system SHALL set downstairs mode to `evening` at the evening transition, only if the mode is `daytime` at that time.

The system SHALL set downstairs mode to `bedtime` at 21:00 each day, unless the mode is `pause_until_changed` or `pause_until_tomorrow`.

The system SHALL set downstairs mode to `daytime` at the morning transition, unless the mode is `pause_until_changed`.

The system SHALL set downstairs mode to `bedtime` when Emily's sleep automation runs, unless the mode is `pause_until_changed` or `pause_until_tomorrow`.

No automatic transition SHALL change the mode while it is `pause_until_changed`; `pause_until_changed` SHALL only be left by an explicit user selection.

The system SHALL allow a future explicit button or control to set downstairs mode to `bedtime`.

#### Scenario: Evening begins before sunset

- **WHEN** the evening transition occurs while downstairs mode is `daytime`
- **THEN** downstairs mode is set to `evening`

#### Scenario: Sunset does not override other modes

- **WHEN** the evening transition occurs while downstairs mode is `bedtime` or `pause_until_changed` or `pause_until_tomorrow`
- **THEN** downstairs mode is unchanged

#### Scenario: Scheduler bedtime begins

- **WHEN** the local time reaches 21:00 while downstairs mode is not `pause_until_changed` or `pause_until_tomorrow`
- **THEN** downstairs mode is set to `bedtime`

#### Scenario: Scheduler daytime mode begins

- **WHEN** the morning transition occurs while downstairs mode is not `pause_until_changed`
- **THEN** downstairs mode is set to `daytime`

#### Scenario: Pause until tomorrow ends in the morning

- **WHEN** downstairs mode is `pause_until_tomorrow` and the local time reaches 21:00 or Emily's sleep automation runs
- **THEN** downstairs mode remains `pause_until_tomorrow`, and it changes to `daytime` at the next morning transition

#### Scenario: Emily sleep action begins bedtime

- **WHEN** Emily's sleep automation runs while downstairs mode is not `pause_until_changed` or `pause_until_tomorrow`
- **THEN** downstairs mode is set to `bedtime` and the sleep automation's existing bedroom behavior continues

#### Scenario: Pause persists until changed by a user

- **WHEN** downstairs mode is `pause_until_changed` and the local time reaches 21:00 or the morning transition occurs, or Emily's sleep automation runs
- **THEN** downstairs mode remains `pause_until_changed` and the sleep automation's other bedroom behavior continues

### Requirement: Emily door lighting follows downstairs mode

The system SHALL turn on the downstairs bathroom light and pool table room light when Emily's door opens while downstairs mode is `bedtime`.

The door-triggered lighting SHALL not change the timeout policy.

#### Scenario: Emily opens her door in bedtime mode

- **WHEN** Emily's door changes to open while downstairs mode is `bedtime`
- **THEN** the downstairs bathroom and pool table room lights are turned on

#### Scenario: Emily opens her door in daytime mode

- **WHEN** Emily's door changes to open while downstairs mode is `daytime`
- **THEN** the door-triggered lighting does not turn on those lights

#### Scenario: Emily opens her door in evening mode

- **WHEN** Emily's door changes to open while downstairs mode is `evening`
- **THEN** the door-triggered lighting does not turn on those lights

#### Scenario: Emily opens her door in pause mode

- **WHEN** Emily's door changes to open while downstairs mode is `pause_until_changed`
- **THEN** the door-triggered lighting does not turn on any lights

## ADDED Requirements

### Requirement: Bedroom lights expire only during the day

While the downstairs mode is `daytime`, each bedroom light that has been on for at least one hour SHALL be turned off.

Bedroom lights SHALL NOT be turned off by automatic timeouts while the downstairs mode is `evening`, `bedtime` or `pause_until_changed`.

Each bedroom light SHALL be evaluated independently.

#### Scenario: Bedroom light left on during the day

- **WHEN** a bedroom light has been on for at least one hour while the mode is `daytime`
- **THEN** that light is turned off

#### Scenario: Bedroom in use in the evening or at night

- **WHEN** a bedroom light is on for more than one hour while the mode is `evening`, `bedtime` or `pause_until_changed`
- **THEN** no automatic timeout turns the light off

#### Scenario: Night light left on overnight

- **WHEN** a bedroom light has been on for more than one hour when the mode changes to `daytime`
- **THEN** that light is turned off at the next timeout evaluation

#### Scenario: Unmanaged lights

- **WHEN** `light.emily_makeup` or `light.emily_sign` is on for more than one hour in any mode
- **THEN** no automatic timeout turns it off
