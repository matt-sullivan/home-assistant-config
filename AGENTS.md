# Home Assistant Config Guidelines

## Project Overview

This is a Home Assistant configuration repository. It uses a mix of YAML config files, ESPHome device configs, a few custom components downloaded from HACS, and Lovelace dashboards.

## Key Conventions

### Config Structure

File and directory structure follows standard home assistant layout. Config is tracked in git.
- `configuration.yaml` — root config; uses `!include` and `!include_dir_named packages` for modularity
- `automations.yaml`, `scripts.yaml`, `scenes.yaml`, `groups.yaml` — all standard home assistant config files, edited directly and through the ui
- `packages/` — split configuration by feature (common, raspipool, holiday_lights); each subfolder loaded as a named package
- `esphome/` — ESPHome device YAML files; `secrets.yaml` inside holds ESPHome-specific secrets
- `custom_components/` — third-party or custom integrations installed here by HACS
- `zha_quirks/` — custom ZHA device quirks (Python)
- `blueprints/` — reusable automation/script/template blueprints
- `secrets.yaml` - passwords and other sensitive content not committed to git.

### Home Assistant Best Practices

- Always consult the `home-assistant-best-practices` skill before creating or editing automations, scripts, helpers, or dashboards
- Prefer native HA helpers (input_boolean, counter, timer, etc.) over template sensors for state storage
- Before renaming entities, check all consumers (automations, scripts, dashboards, templates) — use `mcp_ha-mcp_ha_search`
- Config validation: run `ha core check` from `/root/homeassistant`
- Utility meter `source` must match actual `entity_id`; verify after any rename

### ESPHome

- See the `esphome-remote-cli-access` skill for esphome CLI access
- ESPHome secrets `esphome/secrets.yaml`, logically separate from home assistant secrets.

### Lovelace Dashboards

- `ui-lovelace.yaml` — main dashboard
- `ui-lovelace-emily.yaml`, `ui-lovelace-toby.yaml`, `ui-lovelace-pool.yaml` — per-user/feature dashboards. The pool is no longer used.
- Dashboard resources managed via `packages/common/dashboard.yaml`

## Build and Validation

```bash
# Validate HA config
ha core check

```
