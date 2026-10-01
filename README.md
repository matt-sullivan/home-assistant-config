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
