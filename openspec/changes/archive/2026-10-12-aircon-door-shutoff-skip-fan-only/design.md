## Context

Door shutoff lives in the `air_con_limits` blueprint: a template trigger (`door_open`) with `for: 5 min`, plus a `homeassistant` start trigger, both re-checked by a template condition in the action before `climate.turn_off`. Both templates test `not is_state(climate, 'off')`, so `unavailable` counts as on. The start trigger exists because a trigger whose condition is already true when automations attach never fires; it currently shuts off immediately at startup.

Observed at the last restart: `sensor.uptime` 02:03:56; air cons (ESPHome) went `unavailable` → real state at 02:03:58; doors (ZHA) re-wrote their state at 02:04:06; automations attached at "Home Assistant started" 02:04:47. Both entity types get `last_changed` reset to startup.

Two instances (Sara Office, Parents) override the blueprint's `mode: restart` with `mode: single`.

## Decisions

- **Native "both true for 5 minutes" pattern** replaces the `door_open` template trigger, start trigger and re-check:
  - Triggers (id `door_open`):
    - door sensors `to: 'on'`, `for: 5 min`;
    - climate `to:` active modes (`heat`, `cool`, `heat_cool`, `auto`, `dry`), `for: 5 min`;
    - startup template `{{ now() - states('sensor.uptime') | as_datetime(now()) >= timedelta(minutes=10) }}` — false when automations attach, true once ~10 min after startup.
  - Conditions on the door branch: door sensors `state: 'on'`, `for: 5 min`, `match: any`; climate `state:` active modes, `for: 5 min`.
  - Whichever of door/mode reaches 5 min last fires; the conditions confirm the other. After restart, `last_changed` is reset, so the conditions pass and the startup trigger covers changes missed before automations attached.
  - Active modes are whitelisted (as the existing `climate_changed` trigger already does), which excludes `off`, `fan_only`, `unavailable` and `unknown`.
  - Alternatives rejected:
    - `time_pattern` polling: runs the automation every minute, flooding logbook, recorder and traces.
    - Jinja `last_changed` trigger: more accurate with overlapping doors but harder to read and debug, and fails silently if startup takes > 5 min.
    - Start trigger + `delay`: cancelled by climate triggers in `restart` mode, blocks clamping in `single` mode.
- **`door_sensors` stays optional** (`default: []`), so air cons can use temperature limits alone. HA accepts an empty `entity_id` list for state triggers and conditions; the door trigger then never fires and the `match: any` door condition is false, so the door branch never runs.
- Update the blueprint `description` and `door_sensors` input description for the fan only exemption.

## Risks / Trade-offs

- [Overlapping doors: door A opens, B opens later, A closes — shutoff waits for B's own 5 min] → only affects the living room; rare.
- [Startup longer than 10 min: startup trigger already true at attach, so a door left open across the restart isn't caught] → last startup took 51s; recovers on the next door/mode change.
- [Automation reload while a door is open and the air con active: no trigger fires] → same as today; recovers on the next door/mode change.
