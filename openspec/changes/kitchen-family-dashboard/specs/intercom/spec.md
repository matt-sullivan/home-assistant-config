# Delta Spec

## Purpose

Lets the kitchen and the videophone in Emily's bedroom call each other with two-way video and audio.

## ADDED Requirements

### Requirement: Call the videophone from the kitchen
Someone at the kitchen tablet SHALL be able to call the videophone from any view, with two-way audio and video once connected.

#### Scenario: Kitchen calls Emily
- **WHEN** someone taps call on the tablet and Emily answers on the videophone
- **THEN** both ends see and hear each other

### Requirement: Answer calls in the kitchen
A call from the videophone SHALL automatically answer over whatever view is open.

#### Scenario: Emily calls the kitchen
- **WHEN** Emily calls the kitchen from the videophone while the tablet shows the calendar
- **THEN** the tablet rings briefly then connects the call

### Requirement: Hang up from either end
Either end SHALL be able to end a call, and the tablet SHALL return to the view it showed before the call.

#### Scenario: Videophone hangs up
- **WHEN** Emily ends the call on the videophone
- **THEN** the call ends on the tablet and it returns to its previous view
