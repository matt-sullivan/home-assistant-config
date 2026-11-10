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

## Kitchen Tablet

- Samsung SM-T580 on unofficial LineageOS 24, running the Kiosk Satellite app, signed in as the non-admin `kitchen` HA user. It's an ESPHome-API device with `*.kitchen_tablet_*` entities and remote admin on port 2324. Wireless debugging is on, but its port changes after every reboot or adbd restart, and a reboot can turn it off. `adb root` (Rooted debugging) restarts adbd, so the port changes again. adb works from the HA host or the tablet-video-leak-dev container (adb server port 5038).
- Loads `https://ha.mattnet.xyz/kitchen-display/home`: Caddy on frigate-srv3 (192.168.3.9) serves HTTPS and proxies to HA. HA trusts it as a proxy, and the name has an AAAA record only.
- Views are switched by `select.kitchen_tablet_dashboard_view`. The automations in `packages/common/kitchen_display.yaml` handle the garage, the 2-minute idle return to home (which also ends the call view), and screen brightness by time of day, with levels in `input_number.kitchen_tablet_brightness_day`, `_evening` and `_night`. At night with the kitchen light off, Kiosk Satellite's black screensaver starts after 1 minute without a touch. The display isn't turned off, because the touchscreen has no tap-to-wake and a suspend drops Wi-Fi.
- Live video uses the Generic Camera entities `camera.<name>_540p` (Frigate go2rtc restreams at 960×540 H.264, 10 fps). The 4K HEVC main streams exhaust the tablet's video memory. Keep it to two live streams at most: the hardware decoder allows four instances.
- VoIP Stack runs the `release-test` branch of the fork `matt-sullivan/esphome-intercom` (commit `184f5f91`: 2026.11.0 plus `show_on_ring`, auto-answer in WebViews, the encoder fallback and resubscribing after an HA restart), copied into `custom_components/voip_stack`. Don't update it through HACS, which would overwrite it. After changing its files, restart HA: VoIP Stack then re-registers its resource stamped with the newest file time, which the card passes on to its imports, so the tablet fetches the new JS.
- Runs LineageOS 24.0-20261108 or later, which fixes the gralloc dma-buf fd leak that crashed the kiosk app after hours of video (upstream issue #5). Update with `gtaxlwifi-los24-install.zip` in Settings → System → Updater → ⋮ → Local update; data and Google apps are kept. Nothing needs reapplying after a reboot.
- Never `pm disable-user` persistent system packages on the tablet. Disabling `com.android.bluetooth` crash-looped `system_server`, and recovery needed a rescue script added to the system partition from recovery. Details are in `openspec/changes/archive/2026-11-11-kitchen-family-dashboard/session-notes.md`.

### Power

Needs a 2 A+ USB charger with the plug firmly seated. The tablet sets a 1.65 A input limit when it detects a wall charger; a weaker charger or a loose plug can't supply that, and the charger chip draws only what the supply holds up to (STATUS1 reg 0x08 bit 0 set, in debugfs regmap `4-0049`).

Draw on battery, home page:

| HA brightness (Android /255) | Draw |
|---|---|
| 1% (13) | 1.4 W |
| 25% (71) | 2.3 W |
| 50% (133) | 2.9 W |
| 75% (194) | 3.3 W |
| 100% (255) | 4.3 W |

Delivered with the U-shaped cable: Apple 2 A about 6.9 W (the tablet's limit; +0.67 A into the battery at 100%), ZTE 1 A and a smaller Apple about 5 W (+0.15 A at 100%), Heymix 65 W USB-A port about 4.3 W (about 2.8 W when not fully seated), so the Heymix drains the battery at full brightness.
