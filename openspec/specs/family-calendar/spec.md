# family-calendar Specification

## Purpose
Shows the family's events, the kids' weekly routine and the meal plan together, so everyone knows what's on this week.

## Requirements

### Requirement: Week planner
The kitchen dashboard's home view SHALL show the current week, a column per day, with events from Matt's and Sara's calendars, the kids' routine calendar and the meals calendar. Each calendar's events SHALL be distinguishable at a glance.

#### Scenario: Routine and parent event on the same day
- **WHEN** Thursday has Emily's sport, Toby's tutoring and an event in Sara's calendar
- **THEN** Thursday's column shows all three, each marked by its calendar

#### Scenario: Tonight's dinner
- **WHEN** a dinner is planned for today in the meals calendar
- **THEN** it appears in today's column

### Requirement: Shared kids' routine calendar
The kids' weekly routine (sport, tutoring, OSHC and similar recurring activities) SHALL be kept as recurring events in a Google calendar shared by Matt and Sara, so it shows on their phones as well as the tablet.

#### Scenario: Routine on a phone
- **WHEN** Sara opens Google Calendar on her iPhone
- **THEN** the kids' routine events for the week are shown

### Requirement: Shared meals calendar
The meal plan SHALL be kept as events in a Google calendar shared by Matt and Sara.

#### Scenario: Plan a meal
- **WHEN** Matt adds a dinner event to the meals calendar on his phone
- **THEN** it is visible to Sara and on the tablet

### Requirement: Calendar edited in Google only
The tablet SHALL show calendar events but not allow adding, changing or deleting them. Changes made in Google Calendar SHALL appear on the tablet without anyone refreshing it.

#### Scenario: Event added on a phone
- **WHEN** Sara adds an event in Google Calendar
- **THEN** it appears on the tablet by itself

#### Scenario: Tap an event
- **WHEN** someone taps an event on the tablet
- **THEN** its details are shown and it can't be edited
