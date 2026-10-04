# Spec Delta

## Purpose

Lights wired with power-status sensing (including 2-way circuits) report the lamp's true state and respond to on/off commands idempotently, regardless of which switch last changed the lamp.

## ADDED Requirements

### Requirement: Sensed state reporting
A power-sensed light SHALL report the lamp's sensed on/off state, including changes made by a remote 2-way switch and the state at device boot.

#### Scenario: Remote switch changes lamp
- **WHEN** the remote 2-way switch turns the lamp on or off
- **THEN** the light entity SHALL report the new state

#### Scenario: Device boots with lamp on
- **WHEN** the device boots while the lamp is powered via the remote switch
- **THEN** the light entity SHALL report on once the sensor settles

### Requirement: Idempotent on/off
A power-sensed light SHALL switch the lamp only when the commanded state differs from the sensed state; on and off commands SHALL never act as toggles.

#### Scenario: Turn on an already-on lamp
- **WHEN** HA or Google Assistant commands "on" while the lamp is sensed on
- **THEN** the lamp SHALL remain on

#### Scenario: Turn off with stale HA state
- **WHEN** "off" is commanded while the lamp is sensed off but HA last showed on
- **THEN** the lamp SHALL remain off and the entity SHALL report off

### Requirement: Pooltable stairs lights
Pooltable-stairs SHALL expose two power-sensed lights: "Internal Stairs Light" (channel 1) and "Downstairs Hallway Light" (channel 2).

#### Scenario: Both channels sensed
- **WHEN** either lamp is switched from any switch on its circuit
- **THEN** the corresponding entity SHALL report the lamp's state

### Requirement: Single entity per lamp
Hallway-stairs channel 2 SHALL NOT be exposed to HA; its button SHALL still switch the internal stairs lamp locally.

#### Scenario: Hallway-stairs channel 2 button
- **WHEN** the hallway-stairs channel 2 button is pressed
- **THEN** the internal stairs lamp SHALL change state and "Internal Stairs Light" SHALL report it

### Requirement: 2-way hardware without a remote switch
A light on 2-way switch hardware with no remote switch connected SHALL behave as a plain light: its state SHALL match the lamp at all times, including after a reboot, and on/off commands SHALL be idempotent.

Lights covered: Sara Office.

#### Scenario: Sara Office reboot
- **WHEN** lights-sara-office reboots
- **THEN** the lamp and the HA light state SHALL agree

#### Scenario: Off while off
- **WHEN** "off" is commanded while the Sara Office lamp is off
- **THEN** the lamp SHALL remain off

### Requirement: Sensor diagnostics
Each power-status input on 2-way hardware, used or not, SHALL expose as recorded diagnostic entities its debounced state and a count of raw input transitions per reporting interval. Inputs that drive a light SHALL also expose a count of relay switches the sensor didn't confirm within 1 s.

#### Scenario: Stable lamp
- **WHEN** the lamp state is unchanged for a full interval
- **THEN** the count SHALL be 0

#### Scenario: Single switch event
- **WHEN** the lamp is switched once
- **THEN** the count for that interval SHALL be 1

#### Scenario: Lamp circuit not responding
- **WHEN** the relay switches but the sensed state doesn't follow within 1 s
- **THEN** the unconfirmed-switch count SHALL increase by 1
