## Purpose

Decide whether Matt and Sara are home or away, so presence-based automations act on where they actually are.

## ADDED Requirements

### Requirement: Presence is decided by the Home zone only
A person's presence SHALL be home while their phone's reported location, allowing for its accuracy, is within the Home zone, and away otherwise. Home street zones SHALL NOT change a person's presence.

#### Scenario: GPS drift toward a street zone while at home
- **WHEN** Matt's phone, inside the house, reports a location nearer a street zone's centre than Home's but still within the Home zone allowing for accuracy
- **THEN** Matt stays home

#### Scenario: In a street zone outside Home
- **WHEN** a phone reports a location inside a home street zone but outside the Home zone
- **THEN** that person is away
