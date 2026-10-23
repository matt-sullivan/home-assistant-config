# Tasks

## 1. Zones

- [x] 1.1 In `configuration.yaml`, add `passive: true` to HomeStreet1 and HomeStreet2 and reload zones; verify: `ha core check` passes and both zone entities have `passive: true`.

## 2. Garage automations

- [x] 2.1 In `automations.yaml`, update `open_garage_matt` and `open_garage_sara` per design (zone enter triggers, `home` state trigger, from-`not_home` condition, `max_exceeded: silent`, `stored_traces: 20`) and reload automations; verify: `ha core check` passes and the loaded configs match. — passed; both automations loaded `on`, no log errors.

## 3. Matt's high accuracy ring

- [x] 3.1 On Matt's phone, enable the Location Zone sensor and high accuracy mode with the "only when entering zone" constraint on Home, trigger range 135 m, interval 5 s, and the High accuracy mode sensor (manual); verify: the new High accuracy mode entity appears in HA and reports off at home. — passed; entity is `binary_sensor.pixel_8_pro_high_accuracy_mode` (registered 09:31), `off` at home 10:10–10:14.
- [x] 3.2 Group check: on a drive home, the High accuracy mode sensor turns on before the street zones and off on reaching Home, and the tracker updates about every 5 s in between. (deferred) — passed 2026-10-17 10:09, judged from the update interval (the sensor wasn't in HA yet): ~28 s outside the ring, ~3 s from 195 m; no further updates in the 40 s after reaching Home.

## 4. Final verification

Checked from tracker history, automation traces and logbook. Daily checks for the deferred items: `monitoring.md`.

- [ ] 4.1 Scenario "GPS drift toward a street zone while at home": Matt stays `home` through a day at home, and neither tracker shows a HomeStreet1/HomeStreet2 state. (deferred)
- [x] 4.2 Scenario "Entering a street zone by car": Matt's arrival opens the door on street-zone entry. (deferred) — passed 2026-10-17 10:09:52; HomeStreet2 entry opened the door, 11 s before `home`; the later `home` trigger was blocked by "Garage closed".
- [x] 4.3 Scenario "Reaching home without a street zone reading" or street-zone entry: Sara's arrival opens the door; record which trigger fired. (deferred) — passed 2026-10-17 13:15:19; HomeStreet2 entry opened the door, 10 s before `home`; the later `home` trigger was blocked by "Garage closed".
- [x] 4.4 Scenario "Leaving home by car": no open; trace shows the from-`not_home` condition failed or no trigger. (deferred) — passed 2026-10-17 10:13–10:14; HomeStreet2 (drift) and HomeStreet1 (driving out) entries both blocked by "Arriving from away" (from `home`).
- [ ] 4.5 Scenario "Arriving on foot": no open. (deferred)
- [x] 4.6 A single update firing both zone enter and `home` triggers runs the action once, with no "already running" warning. (deferred) — passed 2026-10-20 15:10:30 (Sara); HomeStreet1 entry ran the action, the `home` trigger 2 ms later stopped as `failed_single`.
- [ ] 4.7 High accuracy mode stays off through a day at home, and battery use at home is unchanged. (deferred)
- [ ] 4.8 No door opens without an arrival over the first two weeks: each successful garage run lines up with an arrival in tracker history. (deferred)
