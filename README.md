# ESPHome Config

This repository holds ESPHome device configuration at its root, plus the standalone container project (`docker/`) that hosts the ESPHome dashboard, sshd, and Claude Code for ESPHome work — decoupled from Home Assistant's own config, which lives in a separate repo.

## Structure

- Device YAML files, `packages/`, `archive/` — ESPHome device configs at the repo root, currently also deployed via the HA-integrated ESPHome Device Builder add-on. Being cut over to `docker/`'s persisted volume — see `openspec/changes/esphome-container/design.md` for status.
- `docker/` — standalone Docker container (Dockerfile, compose config) hosting the ESPHome dashboard, sshd, and Claude Code. Mounts this whole repo checkout directly as its `/config`.
- `openspec/` — design/spec/task tracking for this project.

## Development

See `AGENTS.md` for conventions.
