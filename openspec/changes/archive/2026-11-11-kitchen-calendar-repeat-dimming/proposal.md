# Dim routine events and regular reminders

The kitchen tablet's week planner dims events that follow their usual pattern: the weekly routine, plus fortnightly and monthly reminders that the family has tagged. New and changed events stand out, so the family notices what's different this week.

## Context

- The home view's week planner shows seven days from today for the Matt, Sara, Kids and Meals Google calendars, each in its calendar's colour.
- Most events are the kids' weekly routine and other weekly events. These look the same as one-off events, so the week's unusual events are easy to miss.
- Slower-repeating events include things to do and reminders such as "Matt pay". Only the reminders are background information.
- Some repeating events are copied by hand rather than set to repeat in Google.
- All editing happens in Google Calendar, on phones; the tablet only displays.

## Goals

- A Matt, Sara or Kids event is shown dimmed when it continues an established weekly pattern: at least three occurrences, including the previous week's.
- A fortnightly or monthly event is dimmed the same way only if it's tagged as a reminder, with at least three occurrences, including the previous one.
- A weekly event is shown normally in the week after a missed week. New, moved and renamed events, untagged fortnightly and monthly events, and all meals are shown normally.
- Dimmed events stay readable, and tapping one still shows its details.
- Tagging is done in Google Calendar on any phone, with no change in HA.

## Approach

HA works out which events to dim. Every 15 minutes, a trigger-based template sensor reads the past ten weeks and the coming week from the Matt, Sara and Kids calendars. It lists the upcoming events that continue their pattern. A `#reminderonly` tag in an event's description opts it in to the fortnightly and monthly patterns. The week planner's card-mod style turns that list into CSS that dims the matching events.

## Trade-offs and limits

- A new weekly routine is shown normally for its first two weeks, and a new reminder series for its first two occurrences.
- Only earlier occurrences are compared. The last session before a break stays dimmed, because a future cancellation isn't treated as a change.
- Only the title and start time are compared. An edit that keeps both, such as a new location or end time, stays dimmed.
- An untagged reminder stays highlighted. The tag shows in the event's details on phones and the tablet.
- Dimming can lag a Google edit by up to 15 minutes.
- Meals are never dimmed: the weekly meal plan is meant to be read in full.

## Capabilities

- `family-calendar` (modified)
