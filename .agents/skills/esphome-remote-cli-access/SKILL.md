---
name: esphome-remote-cli-access
description: "Use when: you need to run ESPHome commands to get a config hash, validate, compile or install, or get logs. Keywords: esphome, esphome cli, remote esphome, esphome container, compile, validate, install, logs."
---

# ESPHome Remote CLI Access

Use this skill to run ESPHome commands. It's necessary because the standard home assistant shell runs within the home assistant core container, esphome is only available in a home assistant add-on container.

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

(Replace esphome-subcommand-and-args with the desired ESPHome CLI command and its arguments, such as `config-hash /config/esphome/lights-emily.yaml`.)

## Example Use Case: Get Config Hash

```bash
 ssh homeassistant -p 22222 'docker exec addon_5c53de3b_esphome esphome config-hash /config/esphome/lights-emily.yaml'
```

## What This Skill Avoids

- Running ESPHome commands in a shell that doesn't have ESPHome installed.
- Assuming ESPHome is available directly to the agent.
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
ssh -p 22222 homeassistant 'docker exec <container name> esphome version'
```

(replace `<container name>` with the actual container name found in step 2)
