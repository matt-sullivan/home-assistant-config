# local-https-access Specification

## Purpose
Makes Home Assistant reachable over HTTPS on the home network, so browsers allow the microphone and camera, without disturbing existing HTTP access.

## Requirements

### Requirement: Local HTTPS access
Home Assistant SHALL be reachable on the home network over HTTPS at a hostname with a certificate that browsers trust. The certificate SHALL renew without manual steps or restarting Home Assistant.

#### Scenario: Open over HTTPS
- **WHEN** a device on the home network with IPv6 opens the HTTPS hostname
- **THEN** the Home Assistant frontend loads with no certificate warning, and the microphone and camera can be allowed

#### Scenario: Certificate renewal
- **WHEN** the certificate nears expiry
- **THEN** it is renewed and Home Assistant keeps running

### Requirement: Existing access unchanged
`http://homeassistant:8123`, `http://homeassistant.local:8123` and Nabu Casa remote access SHALL keep working, and devices that fetch media from Home Assistant SHALL be unaffected.

#### Scenario: Existing HTTP URL
- **WHEN** a device or tool opens `http://homeassistant:8123`
- **THEN** it works as before

#### Scenario: TTS to a speaker
- **WHEN** Home Assistant plays TTS on a Google Home speaker or an ESPHome media player
- **THEN** it plays as before

### Requirement: No unreachable IPv4 address published
`ha.matt-sullivan.id.au` SHALL have no IPv4 address record, and Home Assistant SHALL NOT update one.

#### Scenario: DNS lookup
- **WHEN** someone looks up `ha.matt-sullivan.id.au`
- **THEN** only its IPv6 address is returned
