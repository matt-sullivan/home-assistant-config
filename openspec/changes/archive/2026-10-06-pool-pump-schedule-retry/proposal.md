## Why

The pool pump should reliably follow its daily on/off schedule even when a command to the cloud-connected switch fails transiently, and admins should be told when it doesn't.

Context: on 2026-09-15 the scheduled 10:00 turn-on failed with a Tuya cloud error and the pump stayed off until manually started. Transitions missed while Home Assistant is down (e.g. 2026-09-10) are rare and accepted.

## What Changes

- Scheduled pump transitions are verified and retried until the pump reaches the target state or a retry limit is reached; admins are notified if it never does.

## Capabilities

### New Capabilities

- `pool-pump-schedule`: Scheduled pool pump on/off transitions are retried on failure, with admins notified when retries are exhausted.

### Modified Capabilities

## Impact

- Pool pump scheduler entries ("Pool Pump On", "Pool Pump Off").
- New pool pump package configuration in `packages/raspipool/`.
- Notifications to `notify.admins`.
