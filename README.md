# ESPHome Config

This repository holds ESPHome device configuration at its root, plus the standalone container project (`docker/`) that hosts the ESPHome dashboard, sshd, and Claude Code for ESPHome work — decoupled from Home Assistant's own config, which lives in a separate repo.

## Structure

- Device YAML files, `packages/`, `archive/` — ESPHome device configs at the repo root, deployed via `docker/`'s persisted volume (see below).
- `docker/` — standalone Docker container (Dockerfile, compose config) hosting the ESPHome dashboard, sshd, and Claude Code. Mounts this whole repo checkout directly as its `/config`.
- `openspec/` — design/spec/task tracking for this project.

## Development

VSCode: ssh esphome, folder /config
<br>Claude: ssh esphome, tmux, cd /config, claude --name "blah" --rc

relies on ~/.ssh/config: 
```
ssh esphome 
Host esphome
  Hostname frigate-srv3
  Port 2222
  User abc
```

See `AGENTS.md` for conventions.

## Testing
Maintain a list of devices and features in TESTING.md that need to be tested physically after devices are flashed
