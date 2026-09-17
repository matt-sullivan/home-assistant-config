# esphome-dashboard-hosting Specification

## Purpose
Hosts the ESPHome Device Builder dashboard as a standalone container, fully independent of the Home Assistant configuration directory, so ESPHome device management and AI-assisted editing never load Home Assistant context.

## Requirements

### Requirement: Standalone deployment
The system SHALL run the ESPHome Device Builder dashboard as a container process independent of any Home Assistant configuration directory or add-on framework.

#### Scenario: Dashboard reachable without HA
- **WHEN** the container is running on its host
- **THEN** the ESPHome dashboard UI SHALL be reachable via HTTP without Home Assistant being involved in serving it

### Requirement: mDNS device discovery
The system SHALL be network-configured so that mDNS-based device discovery and online/offline status reporting function correctly for ESP devices on the same broadcast domain.

#### Scenario: Device status visible
- **WHEN** an ESP device on the same VLAN is powered on and advertising via mDNS
- **THEN** the dashboard SHALL show it as online within the normal ESPHome polling interval

### Requirement: OTA discovery and deployment
The system SHALL support discovering and performing over-the-air (OTA) firmware updates to ESP devices reachable on the network.

#### Scenario: OTA update succeeds
- **WHEN** a valid ESPHome YAML is compiled and an OTA upload is triggered against a discovered device
- **THEN** the device SHALL receive and apply the new firmware without manual network reconfiguration

### Requirement: Pinned ESPHome version
The system SHALL run an explicitly pinned ESPHome version rather than tracking latest automatically.

#### Scenario: Version stays fixed across rebuilds
- **WHEN** the container is rebuilt without a deliberate version change
- **THEN** the resulting ESPHome version SHALL remain identical to the previous build
