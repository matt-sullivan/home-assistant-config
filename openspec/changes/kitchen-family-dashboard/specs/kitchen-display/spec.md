# Delta Spec

## Purpose

The wall tablet in the kitchen: a family dashboard that is always on, runs unattended, and gives quick access to the calendar, lists, home status, Assist and calls.

## ADDED Requirements

### Requirement: Always-on dashboard
The kitchen tablet SHALL show the family dashboard full screen at all times, with no browser controls or Home Assistant sidebar visible.

#### Scenario: Normal use
- **WHEN** someone looks at the tablet at any time of day
- **THEN** the dashboard is on screen

### Requirement: Unattended recovery
The tablet SHALL return to the dashboard without anyone touching it after a power loss, a reboot, a network outage or Home Assistant restarting.

#### Scenario: Power restored
- **WHEN** power returns after an outage
- **THEN** the tablet starts and shows the dashboard

#### Scenario: Home Assistant restarts
- **WHEN** Home Assistant restarts or the network drops and returns
- **THEN** the dashboard reconnects and shows current information

### Requirement: Locked to the dashboard
Family members SHALL NOT be able to leave the dashboard, open other apps, or change the tablet's settings from the tablet without an admin PIN.

#### Scenario: Kid tries to exit
- **WHEN** someone presses home, back or swipes from the screen edges
- **THEN** the dashboard stays on screen

### Requirement: Navigation always available
Every view of the dashboard SHALL have controls on screen to reach the other views, start a call and start Assist.

#### Scenario: Switch view
- **WHEN** someone is on any view
- **THEN** they can reach any other view with one tap

### Requirement: Return to home view
The dashboard SHALL return to its home view after a period with no touches.

#### Scenario: Left on another view
- **WHEN** someone opens the cameras view and walks away
- **THEN** the dashboard goes back to the home view

### Requirement: Home controls
A separate controls view SHALL show a small list of commonly used HA entities: garage door, downstairs (lights) mode, and a button to trigger the existing leaving home script. The home view SHALL be left to the calendar.

#### Scenario: Garage open on the controls view
- **WHEN** the garage door is open and someone opens the controls view
- **THEN** the controls view shows it as open

#### Scenario: Open the garage
- **WHEN** someone taps to open the closed garage door on the controls view
- **THEN** the door opens

### Requirement: Open Garage View
The dashboard SHALL automatically show a view with the garage camera and garage door control when the garage door opens.

#### Scenario: Garage opens
- **WHEN** the garage door opens
- **THEN** the dashboard shows the garage camera and garage door control

### Requirement: Home Cameras
A separate view SHALL show live feeds from the home's cameras.

#### Scenario: Check cameras
- **WHEN** someone opens the cameras view
- **THEN** live feeds from the cameras are shown

### Requirement: Hands-free Assist
Anyone in the kitchen SHALL be able to use Assist by saying a wake word, without touching the tablet, on any view. Assist SHALL reply by voice and show the conversation on screen.

#### Scenario: Voice command
- **WHEN** someone says the wake word and a command
- **THEN** Assist carries it out and replies by voice

#### Scenario: Tap to talk
- **WHEN** someone taps the Assist control
- **THEN** Assist listens without the wake word

### Requirement: Screen brightness by time of day
The tablet screen SHALL be at full brightness during the day, at a medium level in the evening while the kitchen lights are on, and dim at night once they're off. Each level SHALL be adjustable from Home Assistant without editing configuration.

#### Scenario: Evening
- **WHEN** the sun has set and the kitchen lights are on
- **THEN** the screen is at the evening level

#### Scenario: Bedtime
- **WHEN** the kitchen lights are turned off after sunset
- **THEN** the screen dims to the night level

### Requirement: Dark screen at night
After sunset with the kitchen lights off, the screen SHALL go dark after 1 minute without a touch, and stay connected. A touch, the kitchen lights turning on, the garage opening or a call SHALL bring the dashboard back. It SHALL not go dark during a call.

#### Scenario: Asleep
- **WHEN** the kitchen lights are off after sunset and nobody touches the tablet for 1 minute
- **THEN** the screen goes dark

#### Scenario: Wake on touch
- **WHEN** someone touches the dark screen
- **THEN** the dashboard is shown

#### Scenario: Lights on
- **WHEN** the kitchen lights are turned on while the screen is dark
- **THEN** the dashboard is shown at the evening level

#### Scenario: Call at night
- **WHEN** a call rings while the screen is dark
- **THEN** the call is shown and the screen stays on until it ends
