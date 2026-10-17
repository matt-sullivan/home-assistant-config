## Purpose

Open the garage door as Matt or Sara drives home, without opening it when they aren't arriving by car.

## ADDED Requirements

### Requirement: Garage opens when a family member drives home
The system SHALL open the garage door, and notify, when Matt's or Sara's phone arrives from away into a home street zone or the Home zone while the garage door is closed and that phone is in a car. It SHALL NOT operate the door when the phone was not away immediately before.

#### Scenario: Entering a street zone by car
- **WHEN** Matt's phone, away and in a car, reports a location inside a home street zone with the garage closed
- **THEN** the garage door opens and Matt is notified

#### Scenario: Reaching home without a street zone reading
- **WHEN** Sara's phone, away and in a car, next reports a location inside the Home zone only, with the garage closed
- **THEN** the garage door opens

#### Scenario: Leaving home by car
- **WHEN** Matt drives out and his phone reports a location in a street zone while still home
- **THEN** the garage door is not operated

#### Scenario: GPS drift at home
- **WHEN** a phone at home reports a location inside a street zone
- **THEN** the garage door is not operated

#### Scenario: Door not closed
- **WHEN** a phone arrives home in a car while the garage is not closed
- **THEN** the garage door is not operated

### Requirement: In-car detection
The system SHALL treat Matt's phone as in a car while it is connected to either family car, and Sara's phone as in a car while it is connected to her car.

#### Scenario: Arriving on foot
- **WHEN** a phone arrives home from away while not in a car
- **THEN** the garage door is not operated
