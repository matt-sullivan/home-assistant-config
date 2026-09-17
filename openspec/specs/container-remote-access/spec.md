# container-remote-access Specification

## Purpose
Provides SSH and Claude Code access inside the ESPHome container so an AI agent can edit device configs and trigger compile/flash/OTA deployments directly on the live config tree, with no separate dev environment or file-sync step, and without exposing Home Assistant credentials.

## Requirements

### Requirement: SSH access to the container
The system SHALL expose an SSH service on the container for interactive and remote-agent access, authenticating only via public key.

#### Scenario: Pubkey login succeeds
- **WHEN** a client with an authorized public key connects via SSH
- **THEN** the client SHALL obtain a shell inside the container

#### Scenario: Password login rejected
- **WHEN** a client attempts to authenticate with a password
- **THEN** the SSH service SHALL reject the connection

### Requirement: Persistent SSH host identity
The system SHALL persist SSH host keys across container rebuilds and restarts via a mounted volume.

#### Scenario: Rebuild does not change host identity
- **WHEN** the container image is rebuilt and restarted
- **THEN** SSH clients SHALL see the same host key fingerprint as before the rebuild, producing no host-key-changed warning

### Requirement: CLI-driven ESPHome deployment
The system SHALL allow compiling and deploying ESPHome device configs from within the container via the `esphome` CLI (`run` and `upload` commands).

#### Scenario: Compile and OTA deploy
- **WHEN** `esphome run <file>.yaml` is executed inside the container for a valid device config
- **THEN** the config SHALL be compiled and deployed over the air, with logs streamed to the invoking session

### Requirement: Claude Code operates on the live config tree
Claude Code running inside the container SHALL read and write ESPHome device YAML directly on the container's persisted volume, with no separate sync/copy step to a different dev environment.

#### Scenario: Edit takes effect without sync
- **WHEN** Claude Code edits a device YAML file inside the container
- **THEN** a subsequent `esphome run`/`upload` for that file SHALL use the edited content directly, with no file-copy step required
