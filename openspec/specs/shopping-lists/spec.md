# shopping-lists Specification

## Purpose
Lets the family see and update the Google Keep shopping list from the kitchen, while Keep stays where the list lives.

## Requirements

### Requirement: Add to the shopping list by voice
Assist SHALL add items to the Keep shopping list when asked.

#### Scenario: Ask Assist
- **WHEN** someone in the kitchen says the wake word and "add eggs to the shopping list"
- **THEN** eggs appear in the Keep shopping list

### Requirement: Keep shopping list on the tablet
The kitchen dashboard SHALL show the Google Keep shopping list and let people add items and tick them off. Changes made on the tablet SHALL appear in Keep, and changes made in Keep, on phones or through Google Home SHALL appear on the tablet.

#### Scenario: Add on the tablet
- **WHEN** someone adds "milk" to the shopping list on the tablet
- **THEN** "milk" appears in the Keep list on Matt's, Sara's and Emily's phones

#### Scenario: Tick off on a phone
- **WHEN** Sara ticks off an item in Keep while shopping
- **THEN** it is shown as done on the tablet

### Requirement: Keep remains the source of the list
Syncing SHALL NOT lose items or note content added in Keep, and the list SHALL keep working in Keep and Google Home if the sync stops.

#### Scenario: Sync stopped
- **WHEN** Home Assistant is offline and someone adds items in Keep
- **THEN** the items stay in Keep and appear on the tablet once the sync resumes
