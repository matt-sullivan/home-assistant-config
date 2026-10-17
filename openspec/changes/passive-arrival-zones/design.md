# Design

## Technical context

- Zones (`configuration.yaml`): Home 85 m, from the core `homeassistant:` location (`latitude`, `longitude`, `radius`); HomeStreet1 48 m, centre 60 m from Home's; HomeStreet2 70 m, centre 99 m from Home's; both passive. The street zones were resized and made passive on 2026-10-17 (task 1.1).
- HA (2026.9.3) sets a tracker's state to the smallest-radius non-passive zone containing the reading (allowing for accuracy), so before they were passive, overlap readings resolved to a street zone over Home. Passive zones are skipped for state but still listed in the tracker's `in_zones`.
- Zone triggers and conditions test `in_zones` membership, so they work with passive zones.
- The iOS Companion app (source at `cae2b58`, 2026-10-15; Sara runs 2026.10.1) creates geofences for all zones with `track_ios` enabled, passive included (`ZoneManager` uses `AppZone.trackedZones()`, which doesn't filter `isPassive`); passive only affects the reported zone name.
- `open_garage_matt` and `open_garage_sara` trigger on tracker state `from: not_home` `to: [home, HomeStreet1, HomeStreet2]`, with conditions garage `closed` and in-car, default `mode: single`. Their action `cover.stop_cover` opens a closed door but stops a moving one.
- In-car detection (unchanged by this change): Matt's phone while Android Auto is running or on Bluetooth to `BMW 93379`, `MattMazda` or `Mazda` (the Mazda head unit has used both names); Sara's phone while on the BMW's Wi-Fi (`DIRECT-BMW 93379`).
- Android Companion app high accuracy mode reports location every 5 s (the minimum) via GPS, with a persistent notification. Its "only when entering zone" constraint with a trigger range creates an app-internal expanded zone around a chosen zone: high accuracy is on in the ring between them (entering the ring turns it on, entering the zone turns it off; leaving reverses this). The ring's outer edge is a Google geofence of radius zone radius + trigger range (Android app source `2116802`, 2026-10-16, `LocationSensorManager.addGeofenceToBuilder`). Google decides geofence transitions from its own location estimate, not HA's accuracy rule, and entry can be reported late. The geofences need the Location Zone sensor enabled. These settings live on the phone, not in this repo.
- The street zones extend up to ~110 m (HomeStreet1) and ~170 m (HomeStreet2) from Home's centre, i.e. ~25 m and ~85 m beyond Home's edge.
- Only these two automations reference the street zones. `group.family` consumers and `debug_matt_location` use tracker/person state only.

## Decisions

### Make HomeStreet1 and HomeStreet2 passive

Add `passive: true` to both zones. Tracker state then only chooses between `home` and `not_home`, while the zones remain available to zone triggers.

- **Alternative:** shrink or move the street zones off Home — rejected because any overlap still wins over Home, and zones clear of Home risk being skipped between updates while driving.
- **Alternative:** enlarge the Home zone to cover the street zones' area — rejected because it would cover the nearby street they drive past. Home was enlarged only to 85 m, which stays clear of it.

### Trigger the garage on street-zone entry or reaching home, from away only

In both garage automations:
- `zone` triggers, `event: enter`, on HomeStreet1 and HomeStreet2 for the tracker.
- Keep the state trigger `from: not_home` `to: home`, for arrivals with no street-zone reading (long update gaps, iOS skipping regions).
- Template condition `{{ trigger.from_state.state == 'not_home' }}`, so departures and drift at home don't count.
- Keep the garage `closed` and in-car conditions. The `closed` condition also stops a later `home` trigger re-sending `cover.stop_cover` to an opening door.
- `max_exceeded: silent`, since one update can fire a zone enter and the `home` state trigger together.
- `trace: stored_traces: 20`, so the runs blocked by conditions (drift at home, departures, arrivals on foot) don't push arrival traces out of the default 5.

- **Alternative:** a native state condition instead of the template — rejected because no native condition reads the trigger's from-state.

### Turn on Matt's high accuracy mode only in a ring around Home

On Matt's phone, enable high accuracy mode with the "only when entering zone" constraint on the Home zone, trigger range 135 m (outer radius 220 m), interval 5 s, and no Bluetooth constraint. The ring covers both street zones, with ~50–110 m of approach beyond them, so a drive in crosses the street zones with 5 s updates, and high accuracy is off once inside Home. The nearby restaurant, 300 m from home, stays ~80 m outside the ring, so an imprecise fix there is unlikely to turn high accuracy on.

- **Alternative:** a larger range (e.g. 300 m) for more approach — rejected because it would include the restaurant.
- **Alternative:** enlarge the street zones — rejected because driving past would open the door, needing an automatic close, which the proposal rules out.
- **Alternative:** high accuracy whenever connected to a car's Bluetooth — rejected because it runs for whole drives, and misses trips where Android Auto runs without the car's Bluetooth.
- **Alternative:** require car Bluetooth as well as the ring (the app's combination switch) — rejected because it misses Android Auto trips without car Bluetooth and adds a setting, to save battery only during rare nearby dinners.
- **Alternative:** constrain on a street zone instead of Home — rejected because a ring around a street zone covers the house, so high accuracy would stay on at home.

## Risks

- **Drift at home beyond the Home zone (state `not_home`), then a street-zone reading while Android Auto is on, e.g. sitting in the car in the garage** → Accepted: rare, and needs a reading more than 85 m plus its accuracy from Home's centre.
- **Driving past, or looping back just after leaving, within GPS accuracy of a street zone's edge opens the door with nobody arriving** (2026-10-17 tests came within 8–11 m of HomeStreet2) → Accepted: those routes were deliberate limit tests and are unusual. Monitored through traces, and the zones get resized if it happens.
- **Google geofence entry is detected late, so high accuracy starts after the street zones are reached** → Checked from Matt's tracker history on arrivals. The range can only grow ~50 m before reaching the restaurant; beyond that, an occasional miss is accepted.
- **The phone's Home geofence and HA's Home zone disagree at home (e.g. a drifting fix), turning high accuracy on at home** → Checked through a day at home with the High accuracy mode sensor.
- **Runs blocked by conditions still record traces (not logbook entries) for drift at home, departures and arrivals on foot** → Accepted: filtering on the previous state can only be done in a condition without extra helpers; stored traces raised to 20.
- **An older iOS app version on Sara's phone not monitoring passive zones** → Opening falls back to the `home` trigger, ~11–22 s later; checked on her first arrival.

