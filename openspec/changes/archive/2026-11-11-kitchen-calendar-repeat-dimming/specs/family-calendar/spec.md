# Delta Spec

## ADDED Requirements

### Requirement: Weekly events dimmed
The week planner SHALL dim a Matt, Sara or Kids event when the same event was held 7 days earlier and at least once more 14, 21 or 28 days earlier. The same event means the same calendar, title and time of day, with all-day matching all-day.

#### Scenario: Weekly routine
- **WHEN** Kids has "Baseball Training" at 17:00 this Wednesday and on each of the previous two Wednesdays
- **THEN** this Wednesday's "Baseball Training" is dimmed

#### Scenario: Second week of a new routine
- **WHEN** "Swimming" is held this week and last week only
- **THEN** this week's "Swimming" is shown at full emphasis

#### Scenario: Weekly event missed last week
- **WHEN** "Baseball Training" was held two and three weeks ago but cancelled last week
- **THEN** this week's "Baseball Training" is shown at full emphasis

#### Scenario: Week after a missed week
- **WHEN** "Baseball Training" was held last week and three weeks ago, but cancelled two weeks ago
- **THEN** this week's "Baseball Training" is dimmed

#### Scenario: Last session before a break
- **WHEN** "Baseball Training" is dimmed this week and cancelled next week
- **THEN** this week's "Baseball Training" stays dimmed

#### Scenario: Moved time
- **WHEN** this week's "Tutoring" starts at 17:30 and the previous weeks' started at 17:00
- **THEN** this week's "Tutoring" is shown at full emphasis

#### Scenario: Different calendar
- **WHEN** this week's "Emily PT" is in Kids and the previous weeks' were in Sara
- **THEN** this week's "Emily PT" is shown at full emphasis

#### Scenario: Weekly all-day event
- **WHEN** Kids has an all-day "Sports day" this Friday and on each of the previous two Fridays
- **THEN** this Friday's "Sports day" is dimmed

### Requirement: Regular reminders dimmed
The week planner SHALL dim a Matt, Sara or Kids event whose description contains `#reminderonly` when the same event was held twice before at a fortnightly or monthly interval. Fortnightly means 14 and 28 days earlier, and not 7 or 21 days earlier. Monthly means the previous two months, on the same day of the month or the same weekday of the month. Untagged events SHALL NOT be dimmed on these patterns.

#### Scenario: Monthly reminder
- **WHEN** "Matt pay" is tagged `#reminderonly` and is on the 14th of this month and the previous two months
- **THEN** this month's "Matt pay" is dimmed

#### Scenario: Monthly by weekday
- **WHEN** a tagged reminder is on the second Tuesday of this month and the previous two months
- **THEN** this month's occurrence is dimmed

#### Scenario: Fortnightly reminder
- **WHEN** a tagged reminder is this Friday, two Fridays ago and four Fridays ago
- **THEN** this Friday's occurrence is dimmed

#### Scenario: Untagged fortnightly event
- **WHEN** "Sara 1pm finish" has no tag and is held every two weeks
- **THEN** it is shown at full emphasis

#### Scenario: Weekly event tagged as a reminder
- **WHEN** a tagged weekly event was cancelled last week
- **THEN** this week's occurrence is shown at full emphasis, not treated as fortnightly

### Requirement: Dimmed events readable and tappable
Dimmed events SHALL keep their calendar colour, stay readable on the tablet, and still show their details when tapped. Meals events SHALL never be dimmed.

#### Scenario: Tap a dimmed event
- **WHEN** someone taps a dimmed event
- **THEN** its details are shown

#### Scenario: Repeated meal
- **WHEN** Meals has an all-day "Pizza" this Friday and on each of the previous two Fridays
- **THEN** this Friday's "Pizza" is shown at full emphasis

### Requirement: Dimming follows calendar changes
Dimming SHALL update by itself within 15 minutes of a calendar change in Google, with no change to any Google event.

#### Scenario: Earlier event deleted
- **WHEN** "TRL" has been held for three weeks and last week's is deleted in Google Calendar
- **THEN** within 15 minutes, this week's "TRL" is shown at full emphasis

#### Scenario: Tag added
- **WHEN** `#reminderonly` is added to all events of a monthly series held for three months
- **THEN** within 15 minutes, this month's occurrence is dimmed
