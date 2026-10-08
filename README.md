# Development
**Open this in vscode SSH to homeassistant `/config` folder**

Relies on home assistant advanced ssh server to install dependencies to allow vscode and AI agents to run.
Use `/config` for consistency (despite other symlinks as /homeassistant, /root/config & /root/homeassistant)

HA MCP server (`home-assistant`) is configured in `.mcp.json`, shared by Claude Code and VS Code. It runs `scripts/ha-mcp-launch.sh`, which reads HA connection credentials from `scripts/ha-mcp.env` (not in git).

Claude should be launched with `scripts/claude-ha-session.sh`. (It does ssh, tmux and cd /config, the master agent supervisor uses it.)

# Design / Wiki
## Downstairs Light Management

`input_select.downstairs_mode` drives automatic light timeouts (`packages/common/downstairs_light_management.yaml`):

| Mode | Rarely-occupied lights | Emily's bedroom lights |
|---|---|---|
| `daytime` | off after 1 h | off after 1 h |
| `evening` | off after 1 h | left on |
| `bedtime` | off after 10 min; Emily's door turns on bathroom + pool table TV lights | left on |
| `pause_until_tomorrow` / `pause_until_changed` | left on | left on |

- Rarely-occupied lights are `group.downstairs_managed_lights`; reload groups after editing it, or the running group keeps old members.
- Bedroom lights are every light in the `toy_room` area except `light.emily_makeup` and `light.emily_sign` (their state is unreliable and an automation turns them back on). Selection is the macro in `custom_templates/downstairs_lights.jinja`; run `homeassistant.reload_custom_templates` after editing it.
- Scheduler entries (stored in `.storage`, not git): `evening` at sunset −30 min (only from `daytime`), `bedtime` at 21:00 (skips both pauses), `daytime` at sunrise +30 min (skips `pause_until_changed`). Emily's sleep script sets `bedtime` unless paused.
- `pause_until_tomorrow` ends at the next morning transition; `pause_until_changed` only ends when changed manually (use for house sitters).

## Pool Pump Schedule

Scheduler entries "Pool Pump On" (10:00) and "Pool Pump Off" (16:00) start `script.pool_pump_set_state` with `target: on`/`off`. It retries once a minute for up to 10 minutes until `switch.pool_pool_pump` reaches the target, then notifies `notify.admins` on failure. A newer run replaces an in-progress one. Missed transitions while HA is down are not handled.

- Tuya (cloud) command errors are not `HomeAssistantError`, so `continue_on_error` doesn't catch them; each attempt runs in `script.pool_pump_command`, started via `script.turn_on` so errors don't stop the loop.
- Tuya can accept a command without delivering it, so success is checked by the switch state, not the command result.
- The Tuya SDK drops an identical command sent to the same device within 10 s.
- During an internet outage, retries and the phone notification both fail.
