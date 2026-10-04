# Spec Delta

## Purpose

The status LED indicates device health: off in normal operation, blinking only for warnings or errors, so a healthy switch has no lit indicator.

## ADDED Requirements

### Requirement: Status LED off when healthy
The 6914HA series 3 status LED SHALL be off while the device is connected and healthy and SHALL blink on warning or error states.

#### Scenario: Normal operation
- **WHEN** the device is connected to Wi-Fi and HA
- **THEN** the status LED SHALL be off

#### Scenario: Connection lost
- **WHEN** the device loses its Wi-Fi or HA connection
- **THEN** the status LED SHALL blink
