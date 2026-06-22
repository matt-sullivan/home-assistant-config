---
name: esphome-remote-cli-access
description: "Get ESPHome CLI access when not running on the home assistant server. Use when: ESPHome command is missing locally, you need config hash/compile/run logs. Keywords: esphome cli, remote esphome, esphome container, config hash."
---

# ESPHome Remote CLI Access

Use this skill to run ESPHome commands on Home Assistant when not running on the home assistant server.

## Outcome

- Run ESPHome CLI from the correct remote container.
- Retrieve values such as config hash using the same code path ESPHome uses.

## Preconditions (usually already met)

- SSH access to host `homeassistant` on port `22222`.
- User can run docker commands on the remote host (directly or through sudo).
- Config files are available under `/config/esphome` in Home Assistant.

## Command Line Template

```bash
 ssh homeassistant -p 22222 'docker exec addon_5c53de3b_esphome esphome <esphome-subcommand-and-args>'
```

Replace esphome-subcommand-and-args with the desired ESPHome CLI command and its arguments, such as `config-hash /config/esphome/lights-emily.yaml`.

## Example Use Case: Get Config Hash

```bash
 ssh homeassistant -p 22222 'docker exec addon_5c53de3b_esphome esphome config-hash /config/esphome/lights-emily.yaml'
```

## Quick Commands

Resolve container once:

```bash
ssh -p 22222 homeassistant 'docker ps --format "{{.Names}}" | grep -i esphome | head -1'
```

Run one-off command:

```bash
ssh -p 22222 homeassistant 'c=$(docker ps --format "{{.Names}}" | grep -i esphome | head -1); docker exec "$c" esphome <subcommand> /config/esphome/<file>.yaml'
```

## What This Skill Avoids

- Assuming local ESPHome is installed.
- Using non-ESPHome hash approximations when exact parity is required.

## Potential Diagnostic Steps if not working

1. Verify remote connectivity.

```bash
ssh -p 22222 homeassistant 'echo connected'
```

2. Discover the ESPHome container name dynamically.

```bash
ssh -p 22222 homeassistant 'docker ps --format "{{.Names}}" | grep -i "esphome" | head -1'
```

3. Verify ESPHome CLI availability inside that container.

```bash
ssh -p 22222 homeassistant 'c=$(docker ps --format "{{.Names}}" | grep -i esphome | head -1); docker exec "$c" esphome version'
```
