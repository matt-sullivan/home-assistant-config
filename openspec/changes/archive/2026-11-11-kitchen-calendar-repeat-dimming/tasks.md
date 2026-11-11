# Tasks

## 1. Repeats sensor

- [x] 1.1 Add trigger-based template sensor `sensor.kitchen_calendar_repeats` to `packages/common/kitchen_display.yaml` per design (15-minute trigger, `calendar.get_events` over Matt, Sara and Kids for 77 days, weekly rule, `#reminderonly` fortnightly and monthly rules, `repeats` attribute); verify: `ha core check` passes and the template reloads — passed; template also tested via /api/template with live data and 19 synthetic cases
- [x] 1.2 Group check: the `repeats` attribute lists this week's established weekly routine (e.g. Kids "Baseball Training", "TRL") and excludes one-off events (e.g. "Hernia Surgeon"), untagged fortnightly and monthly events (e.g. "Sara 1pm finish", "Matt pay") and meals, compared with the `calendar.get_events` output — passed; 8 live entries (Kids/Matt weekly routine), none of the excluded events

## 2. Dimming on the week planner

- [x] 2.1 Add the `card_mod` style template to the week planner in `ui-lovelace-kitchen.yaml` per design; verify: the rendered template in Developer Tools gives one CSS rule per `repeats` entry, with escaped quotes — passed
- [x] 2.2 Group check: on the tablet (via CDP), the matching `div.event` elements have opacity 0.45 and the others have 1. If not, apply the shadow-root fallback from design Risks — passed; card-mod reaches the card shadow root, no fallback needed

## 3. Final verification

- [x] 3.1 Scenarios Weekly routine, Untagged fortnightly event and Repeated meal against the live calendars; verify: dimmed and undimmed events match the sensor — passed
- [x] 3.2 Weekly scenarios Second week of a new routine, Weekly event missed last week, Week after a missed week, Last session before a break, Moved time, Different calendar and Weekly all-day event, using temporary test events in Google Calendar; verify: each event's emphasis matches its scenario — passed (Google test events created twice by mistake; duplicates did not affect results)
- [x] 3.3 Reminder scenarios Monthly reminder, Monthly by weekday, Fortnightly reminder and Weekly event tagged as a reminder, using temporary tagged test events; verify: each event's emphasis matches its scenario — passed
- [x] 3.4 Scenarios Earlier event deleted and Tag added on the test events; verify: emphasis changes within 15 minutes — passed; tag added by deleting and re-creating the occurrence with the tag (HA cannot edit Google events)
- [x] 3.5 Remove all temporary test events from Google Calendar; verify: none left in the 77-day window — passed; 79 deleted, none left
- [x] 3.6 Scenario Tap a dimmed event (manual); verify: the details dialog opens — passed (manual)
- [x] 3.7 Dimmed events are readable from across the kitchen and the calendar colours are still clear (manual) — passed (manual)

## 4. Wrap-up

- [x] 4.1 Add to README → Kitchen Tablet: what gets dimmed, the `#reminderonly` tag, and `sensor.kitchen_calendar_repeats`

## Workflow follow-up

- Archive the change and tidy the git history.
