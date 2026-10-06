## Purpose

Keep the pool pump following its daily on/off schedule despite transient command failures, and tell admins when it doesn't.

## ADDED Requirements

### Requirement: Scheduled transitions are retried until confirmed
At each scheduled on or off time, the system SHALL command the pump to the scheduled state and, if the pump does not reach that state, SHALL retry about once per minute for up to 10 minutes. Retrying SHALL stop as soon as the pump is in the scheduled state.

#### Scenario: Command succeeds first time
- **WHEN** the scheduled on time arrives and the pump turns on after the first command
- **THEN** no further commands are sent and no notification is sent

#### Scenario: Command fails then succeeds
- **WHEN** the scheduled on time arrives, the first command fails, and a later retry succeeds within 10 minutes
- **THEN** the pump is on, retrying stops, and no notification is sent

#### Scenario: Pump already in scheduled state
- **WHEN** the scheduled off time arrives and the pump is already off
- **THEN** no command is sent

#### Scenario: Pump reaches scheduled state by other means
- **WHEN** retries are in progress and the pump reaches the scheduled state through any other means
- **THEN** retrying stops

### Requirement: Admins are notified when a scheduled transition fails
The system SHALL notify admins when the pump is not in the scheduled state after the retry period ends.

#### Scenario: All retries fail
- **WHEN** the scheduled on time arrives and the pump is still off after 10 minutes of retries
- **THEN** admins receive a notification that the pump failed to turn on

### Requirement: A newer scheduled transition supersedes an in-progress one
The system SHALL stop retrying a scheduled transition when the next scheduled transition starts.

#### Scenario: Off time arrives during on retries
- **WHEN** retries to turn the pump on are still in progress at the scheduled off time
- **THEN** on retries stop and the off transition proceeds

