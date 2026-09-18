# Visitor Presence Specification

## Purpose

Keep the house operating normally (i.e. avoiding away automations) if the kids
or housesitters are there where Sara and Matt aren't home.

## Requirements

### Requirement: Visitors count as family presence
The system SHALL treat enabled visitor presence as home presence wherever aggregate family presence is used.

#### Scenario: Visitor is home alone
- **WHEN** visitor presence is enabled while all other people are away
- **THEN** aggregate family presence is home

### Requirement: Another person arriving clears visitor presence
The system SHALL clear enabled visitor presence when a person other than visitors arrives home, without clearing it in response to visitor presence itself.

#### Scenario: Visitor presence is enabled
- **WHEN** visitor presence changes from disabled to enabled while all other people remain away
- **THEN** visitor presence remains enabled

#### Scenario: Another person arrives
- **WHEN** a person other than visitors changes from away to home while visitor presence is enabled
- **THEN** visitor presence becomes disabled