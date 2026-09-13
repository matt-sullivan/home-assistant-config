# Home Assistant Config Guidelines

This is a Home Assistant configuration repository. It uses a mix of YAML config files, ESPHome device configs, a few custom components downloaded from HACS, and Lovelace dashboards.

- Keep changes focused and preserve existing conventions.
- Validate Home Assistant configuration with `ha core check` when configuration changes are made.
- Do not expose secrets from `secrets.yaml` or `ha-mcp.env` files.
- Be very concise in everything you write
- Be very thorough in any analysis, do not jump to conclusions

## Key Conventions

### Config Structure

File and directory structure follows standard home assistant layout. Config is tracked in git.
- `configuration.yaml` — root config; uses `!include` and `!include_dir_named packages` for modularity
- `automations.yaml`, `scripts.yaml`, `scenes.yaml`, `groups.yaml` — all standard home assistant config files, edited directly and through the ui
- `packages/` — split configuration by feature (common, raspipool, holiday_lights); each subfolder loaded as a named package
- Put new feature configuration in the appropriate package instead of expanding `configuration.yaml` unless the integration requires root-level configuration.
- `esphome/` — ESPHome device YAML files; `secrets.yaml` inside holds ESPHome-specific secrets
- `custom_components/` — third-party or custom integrations installed here by HACS; avoid modifying HACS-managed or generated files unless explicitly requested
- `zha_quirks/` — custom ZHA device quirks (Python)
- `blueprints/` — reusable automation/script/template blueprints
- `secrets.yaml` - passwords and other sensitive content not committed to git.
- `scripts/ha-mcp.env` - HA API connection url and secrets, not committed to git.

### Home Assistant Best Practices

- Always consult the `home-assistant-best-practices` skill before creating or editing automations, scripts, helpers, or dashboards
- Prefer native HA helpers (input_boolean, counter, timer, etc.) over template sensors for state storage
- Before renaming entities, check all consumers (automations, scripts, dashboards, templates) — use `mcp_ha-mcp_ha_search`
- Config validation: run `ha core check` from `/root/homeassistant`
- Utility meter `source` must match actual `entity_id`; verify after any rename

### ESPHome

- See the `esphome-remote-cli-access` skill for esphome CLI access
- Run ESPHome validation and builds through the remote ESPHome add-on container over SSH; ESPHome is not available in the Home Assistant shell.
- ESPHome secrets `esphome/secrets.yaml`, logically separate from home assistant secrets.

### OpenSpec

- Use the OpenSpec workflow for planned feature changes: read the relevant proposal, design, specs, and tasks before implementing, and keep task status up to date.
- you have openspec skills, follow the instructions provided by those skills
- Before implementing a change, check active OpenSpec changes
- maintain specs to make sure they're very concise and consistent
    - logically separate statements into their best location in proposal, design, tasks or specs.
    - no duplicated content across files
    - Avoid statements in one format that are just reworded from other sections. e.g. capabilities as reworded tasks, duplicate 'impact' and 'whats changed' sections.
    - proposal.md why section should focus on the goal and what we want to achieve, if context is necessary put it after goal statements or in a separate section of that file. 
    - specs folder contents are statements about things that should work particular ways, not just a rewording of tasks
    - avoid tasks that are not actions to be done
    - ensure each task is a logically separate action, group related updates as bullet point details of a single task
    - avoid commentary that doesn't specify anything
    - include a design migration plan only when the change has meaningful deployment sequencing, data migration, compatibility, or rollback complexity; omit it for straightforward configuration changes
    - during implementation record problems and new knowledge in session notes files separate from the spec unless it's actually a change to the design, tasks or spec
    - explicitly list each item that is important to be tested, in tasks.md or a reference to another file. Be concise but list each item separately with a checkbox or bullet point.
- do not include extra work that's not part of the active change
- Do not implement broad unrelated refactors inside a feature change.
- After a change is complete
    - update project documentation with new configuration and any valuable knowledge or lesssons learned to remember
    - archive with `openspec archive <change-name>`.
    - Cleanup the git history including the archive operation. Consider rebasing anything that's not pushed to origin to keep medium to large sized commits grouped by logical changes with concise messages. Don't worry about other branches, they can rebase as needed, ensure history retains logical order of operations.

### Lovelace Dashboards

- `ui-lovelace.yaml` — main dashboard
- `ui-lovelace-emily.yaml`, `ui-lovelace-toby.yaml`, `ui-lovelace-pool.yaml` — per-user/feature dashboards. The pool is no longer used.
- Dashboard resources managed via `packages/common/dashboard.yaml`

## Build and Validation

```bash
# Validate HA config
ha core check

```
