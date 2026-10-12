## Purpose

Turn off air cons that are heating, cooling or drying while a door in their room is left open, so energy isn't wasted, without interrupting fan only use.

## ADDED Requirements

### Requirement: Air con turns off after a door is open for 5 minutes
The system SHALL turn off an air con, and notify parents naming the open doors, when any of its doors has been open for more than 5 minutes while the air con is in any mode other than off or fan only. The 5 minutes SHALL count only time where both a door is open and the air con is in such a mode.

The turn off processing may be delayed up to 3 minutes to simplify implementation, and up to 15 minutes after home assistant is restarted, and may restart its timer if the air con mode is changed.

#### Scenario: Cooling with door open
- **WHEN** an air con is cooling and one of its doors stays open for 5 minutes
- **THEN** the air con turns off and parents are notified naming the open door

#### Scenario: Door closed before 5 minutes
- **WHEN** an air con is heating and its door opens then closes within 5 minutes
- **THEN** the air con keeps running

#### Scenario: Door already open at Home Assistant start
- **WHEN** Home Assistant starts while an air con is heating and one of its doors is open
- **THEN** the air con does not turn off immediately

### Requirement: Fan only mode is exempt from door shutoff
The system SHALL NOT turn off an air con because of an open door while it is in fan only mode.

#### Scenario: Fan only with door open
- **WHEN** an air con is in fan only mode and one of its doors stays open for more than 5 minutes
- **THEN** the air con keeps running and no notification is sent

#### Scenario: Switched from fan only to cool with door open
- **WHEN** an air con has been in fan only mode with a door open for more than 5 minutes, then is switched to cool with the door still open
- **THEN** the air con turns off 5 minutes after the switch to cool

#### Scenario: Fan only at Home Assistant start
- **WHEN** Home Assistant starts while an air con is in fan only mode and one of its doors is open
- **THEN** the air con keeps running
