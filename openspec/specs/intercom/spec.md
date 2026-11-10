# intercom Specification

## Purpose
Lets the kitchen and the videophone in Emily's bedroom call each other with two-way video and audio.

## Requirements

### Requirement: Call the videophone from the kitchen
Someone at the kitchen tablet SHALL be able to call the videophone from any view, with two-way audio and video once connected.

#### Scenario: Kitchen calls Emily
- **WHEN** someone taps call on the tablet and Emily answers on the videophone
- **THEN** both ends see and hear each other

### Requirement: Answer calls in the kitchen
A call from the videophone SHALL automatically answer and show full screen, whatever view is open.

#### Scenario: Emily calls the kitchen
- **WHEN** Emily calls the kitchen from the videophone while the tablet shows the calendar
- **THEN** the tablet switches to the call, rings briefly, then connects it

### Requirement: Hang up from either end
Either end SHALL be able to end a call, and the tablet SHALL then return to its home view when left untouched.

#### Scenario: Videophone hangs up
- **WHEN** Emily ends the call on the videophone
- **THEN** the call ends on the tablet, and it goes back to the home view once nobody touches it
