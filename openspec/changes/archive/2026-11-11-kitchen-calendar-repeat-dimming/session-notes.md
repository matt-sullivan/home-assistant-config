# Session notes

- 2026-11-11: the monthly rule also needs the fortnightly rule's "not 7 or 21 days earlier" check; without it a tagged weekly event that missed last week matches the previous months by weekday of the month. Added to design.
- 2026-11-11: the sensor template was tested by rendering it through `/api/template` with live `calendar.get_events` data and 19 synthetic cases (one per scenario plus tag-spelling and quote cases); all matched. Test harness: session scratchpad `caltest/run.py`.
- 2026-11-11: `homeassistant.update_entity` on a Google calendar entity forces an immediate re-sync from Google (otherwise edits take up to ~15 min to reach HA).
- 2026-11-11: the card shows events with the same calendar, title and time only once, so duplicate Google events don't double up on the tablet.
