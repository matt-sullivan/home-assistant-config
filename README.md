# Development
**Open this in vscode SSH to homeassistant `/config` folder**

Relies on home assistant advanced ssh server to install dependencies to allow vscode and AI agents to run.
Use `/config` for consistency (despite other symlinks as /homeassistant, /root/config & /root/homeassistant)

Has HA MCP server configured in .vscode, running scripts/ha-mcp-launch.sh but reliant on ~/.config to set HA connection credentials.

Claude should be launched with `scripts/claude-ha-session.sh`. (It does ssh, tmux and cd /config, the master agent supervisor uses it.)

# Design / Wiki
## Downstairs Light Management

The `input_select.downstairs_mode` helper controls automatic downstairs light timeouts:

- `normal` turns managed lights off after one hour.
- `bedtime` turns managed lights off after ten minutes and enables Emily's door lighting.
- `pause` disables automatic timeouts.

Scheduler entries set `bedtime` at 21:00 and `normal` at 06:00. The Emily makeup light is excluded because its device automation restores power shortly after it is turned off.

## Pool Pump Schedule

Scheduler entries "Pool Pump On" (10:00) and "Pool Pump Off" (16:00) start `script.pool_pump_set_state` with `target: on`/`off`. It retries once a minute for up to 10 minutes until `switch.pool_pool_pump` reaches the target, then notifies `notify.admins` on failure. A newer run replaces an in-progress one. Missed transitions while HA is down are not handled.

- Tuya (cloud) command errors are not `HomeAssistantError`, so `continue_on_error` doesn't catch them; each attempt runs in `script.pool_pump_command`, started via `script.turn_on` so errors don't stop the loop.
- Tuya can accept a command without delivering it, so success is checked by the switch state, not the command result.
- The Tuya SDK drops an identical command sent to the same device within 10 s.
- During an internet outage, retries and the phone notification both fail.
