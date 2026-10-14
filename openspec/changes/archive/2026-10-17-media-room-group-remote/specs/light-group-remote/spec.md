# Delta Spec

## Purpose

A remote button that turns a group of lamps on another switch all off or all on, with the lamps' state and control owned by that switch.

## ADDED Requirements

### Requirement: Media room lamps
Media room "Door" and "Interior" SHALL each report its lamp's state, including after remote presses. On/off commands SHALL switch a lamp only when its state differs. Each media room button and HA command SHALL change only its own lamp.

#### Scenario: Remote press reported
- **WHEN** the remote is pressed
- **THEN** both entities SHALL report the lamps' new states

#### Scenario: Turn on an already-on lamp
- **WHEN** "on" is commanded for a lamp that is on
- **THEN** no lamp SHALL change

#### Scenario: Local switch of one lamp
- **WHEN** a media room button or HA switches one lamp
- **THEN** the other lamp SHALL NOT change

### Requirement: Group remote button
A remote press SHALL turn both lamps off if either is on, otherwise both on. A press SHALL take effect once. The remote SHALL have no HA light entities.

#### Scenario: Either lamp on
- **WHEN** the remote is pressed while one or both lamps are on
- **THEN** both lamps SHALL be off

#### Scenario: Both lamps off
- **WHEN** the remote is pressed while both lamps are off
- **THEN** both lamps SHALL be on

#### Scenario: Media room unreachable
- **WHEN** the remote is pressed and its message doesn't reach the media room
- **THEN** no lamp SHALL change

### Requirement: Remote button LED
The remote's button LED SHALL be on when either lamp is on.

#### Scenario: Only Interior on
- **WHEN** only Interior is on
- **THEN** the remote LED SHALL be on

### Requirement: No switching on boot
Neither device SHALL change any lamp when it boots or receives a periodic state update.

#### Scenario: Device reboot
- **WHEN** the media room or the remote reboots
- **THEN** no lamp SHALL change

### Requirement: Group remote diagnostics
The media room SHALL expose counts of accepted and duplicate remote presses, and of lamp switches its sense inputs didn't confirm. The remote SHALL expose the time since it last received the media room's state.

#### Scenario: Healthy link
- **WHEN** the remote is pressed with no packet loss
- **THEN** the accepted count SHALL rise by 1, and repeated copies of the press SHALL be counted as duplicates

#### Scenario: Sense fault
- **WHEN** a lamp is switched and its sense input doesn't follow
- **THEN** that channel's unconfirmed count SHALL rise

#### Scenario: Link down
- **WHEN** the remote stops receiving the media room's state
- **THEN** its state age SHALL keep rising past 30 s
