# Design

## Technical context

- `calendar.get_events` (with a response) returns `start`, `end`, `summary` and `status` for each event, plus `description` and `location` when set. Timed events have local ISO times with an offset (`2026-11-04T17:00:00+10:00`); all-day events have plain dates (`2026-11-11`). Recurrence fields aren't returned. A 97-day read of the three calendars returned 133 events.
- week-planner-card 1.14.1 renders each event as `div.event` inside a `div.day`, in the card's shadow root.
  - The day's classes include its weekday in lowercase (`wednesday`).
  - The event's classes include `fullday` for all-day events. Its attributes include `data-entity`, `data-summary` (the title, which this card doesn't rewrite), `data-start-hour` (`H`, no leading zero) and `data-start-minute` (`mm`).
  - The card shows seven days from today, so a weekday class names exactly one day.
- card-mod is loaded on every dashboard through `frontend: extra_module_url`. Its `style` accepts Jinja templates, which HA re-renders when a referenced entity changes.

## Decisions

### Work out repeats in a trigger-based template sensor

`sensor.kitchen_calendar_repeats` is defined in `packages/common/kitchen_display.yaml` under a new `template:` key.

- **Trigger:** every 15 minutes (`time_pattern`). No start trigger: trigger-based template sensors restore their state and attributes after a restart.
- **Action:** `calendar.get_events` for `calendar.matt`, `calendar.sara` and `calendar.kids`. `calendar.meals` is left out, so meals are never dimmed. The window starts at today 00:00 minus 70 days, which covers two months back by weekday of the month (up to 5 weeks each), and lasts 77 days. The response is kept as a variable.
- **State:** the number of entries in `repeats`.
- **`repeats` attribute:** a list of `{calendar, weekday, summary, hour, minute, all_day}`, one per event from today onward that meets "Weekly events dimmed" or "Regular reminders dimmed".
  - An event's key is its `summary` plus its start time: the `HH:MM` part of `start`, ignoring the offset so a DST change still matches, or empty for all-day events. Keys are collected per calendar and date. "Held on date D" means the key is in D's set.
  - Weekly: held at −7 days and at one of −14, −21 or −28.
  - Fortnightly (tagged only): held at −14 and −28, and not at −7 or −21. The −7/−21 check stops a weekly event that missed a week from passing as fortnightly.
  - Monthly (tagged only): held in each of the previous two months on the same day of the month, or on the same weekday and week of the month (week = `(day − 1) // 7`). Days that don't exist in a shorter month are treated as absent. Like fortnightly, it requires the event not to be held 7 or 21 days earlier, or a weekly event that missed a week would match by weekday of the month.
  - Tagged means this occurrence's description contains `#reminderonly` as a whole word, matched case-insensitively.
  - Later dates aren't checked, so a break that starts next week doesn't change this week.
- `hour` is unpadded to match the card's `data-start-hour`.

HA does the matching, so the result can be checked in Developer Tools. The card stays a stock HACS install.

- **Alternative:** a plain automation that writes to a helper — rejected because a trigger-based template sensor is the native way to keep an action's result as state, and needs no helper.
- **Alternative:** HA writes markers into the Google events — rejected because it edits the family's shared calendars from HA and has to be undone when a routine changes.
- **Alternative:** a JS module that patches the card to compare weeks — rejected because it hooks into the card's internals, which can change in any update, and puts the logic where it can't be inspected from HA.
- **Alternative:** treat a slower series as recurring from Google's repeat rule — rejected because `calendar.get_events` doesn't return it, and events copied by hand have none.

### Opt slower patterns in with a `#reminderonly` description tag

People add `#reminderonly` to an event's description in Google Calendar. Weekly events need no tag.

- It's invisible in calendar grids, covers a whole series when added while editing "All events", and comes along when an event is copied.
- It names what the event is (a reminder), not how the tablet shows it.
- It only opts an event in to the pattern check. A tagged one-off is still shown normally.

- **Alternative:** an emoji or tag in the title — rejected because it clutters the title people read every day.
- **Alternative:** a list of opted-in titles in an HA helper — rejected because it's kept apart from the events and breaks when a title changes.
- **Alternative:** a separate Google calendar for reminders — rejected because it changes the event's colour and whose calendar it's in.
- **Alternative:** Google event colour — rejected because the HA Google integration doesn't expose it.

### Dim with a card-mod template on the week planner

The `custom:week-planner-card` on the home view gets `card_mod.style`. Its template loops over `state_attr('sensor.kitchen_calendar_repeats', 'repeats')` and emits one rule per entry:

```
.day.wednesday .event[data-entity="calendar.kids"][data-summary="Baseball Training"][data-start-hour="17"][data-start-minute="00"] { opacity: 0.45; }
```

- All-day entries use `.event.fullday` in place of the hour and minute attributes.
- Summaries escape `\` and `"` for CSS.
- An opacity of 0.45 keeps the calendar colour and text readable. Opacity doesn't change hit-testing, so taps still open the details.

- **Alternative:** a greyscale filter — rejected because the calendar colour is how people tell whose event it is.

## Risks

- **card-mod's style may not reach events inside the card's shadow root** → Check on the tablet first. If it doesn't, target the root with card-mod's `.:` / `$` shadow-root syntax.
- **A Google API error during the refresh leaves a partial or empty response** → A failed action stops the trigger run, so the sensor keeps its previous value; verify this when testing. At worst, events are shown undimmed.
- **The 70-day read grows slow or large** → Accepted: about 130 events today. The attribute holds only this week's matches.
- **A timed event at 00:00 and an all-day event with the same title on the same day** → Accepted: the `fullday` class keeps them apart.

## Migration and rollback

Remove the `card_mod` block and the sensor to go back; `#reminderonly` tags left in Google descriptions are harmless.
