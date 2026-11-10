# Home Assistant Config Guidelines

This is a Home Assistant configuration repository. It uses a mix of YAML config files, a few custom components downloaded from HACS, and Lovelace dashboards.

- Keep changes focused and preserve existing conventions.
- Validate Home Assistant configuration with `ha core check` when configuration changes are made.
- Do not expose secrets from `secrets.yaml` or `ha-mcp.env` files.
- Be very concise in everything you write
- Be very thorough in any analysis, do not jump to conclusions
- Do not make any changes to ESPHome configuration while working on home assistant, suggest delegating to an agent focused on esphome

## Key Conventions

### Config Structure

File and directory structure follows standard home assistant layout. Config is tracked in git.
- `configuration.yaml` — root config; uses `!include` and `!include_dir_named packages` for modularity
- `automations.yaml`, `scripts.yaml`, `scenes.yaml`, `groups.yaml` — all standard home assistant config files, edited directly and through the ui
- `packages/` — split configuration by feature (common, raspipool, holiday_lights); each subfolder loaded as a named package
- Put new feature configuration in the appropriate package instead of expanding `configuration.yaml` unless the integration requires root-level configuration.
- `custom_components/` — third-party or custom integrations installed here by HACS; avoid modifying HACS-managed or generated files unless explicitly requested
- `zha_quirks/` — custom ZHA device quirks (Python)
- `blueprints/` — reusable automation/script/template blueprints
- `secrets.yaml` - passwords and other sensitive content not committed to git.
- `scripts/ha-mcp.env` - HA API connection url and secrets, not committed to git.

### Home Assistant Best Practices

- Always consult the `home-assistant-best-practices` skill before creating or editing automations, scripts, helpers, or dashboards. It is served by the `home-assistant` MCP server as resource `skill://home-assistant-best-practices/SKILL.md` (not a local skill).
- Prefer native HA helpers (input_boolean, counter, timer, etc.) over template sensors for state storage
- Before renaming entities, check all consumers (automations, scripts, dashboards, templates) — use `mcp__home-assistant__ha_search`
- Config validation: run `ha core check` from `/config`
- Utility meter `source` must match actual `entity_id`; verify after any rename

### Working folders
- Tools (Claude Code, git) report the real path `/homeassistant`; it is the same directory as `/config` (symlink). Refer to it as `/config`.
- No worktrees: all sessions share one checkout at `/config` on `master`.

### ESPHome

- ESPHome device configs are not managed here; they live on the `esphome-main` branch of this repo, checked out separately outside the Home Assistant VM.

### OpenSpec

- Use the OpenSpec workflow for planned feature changes: read the relevant proposal, design, specs, and tasks before implementing, and keep task status up to date.
- you have openspec skills, follow the instructions provided by those skills
- Before implementing a change, check active OpenSpec changes
- maintain specs to make sure they're very concise and consistent
    - Logically separate statements into their best location in proposal, design, specs or tasks.
    - Proposals describe goals and outcomes; design describes implementation details considerations and decisions; specs describe externally observable behavior; tasks describe actions.
    - Keep proposals and behavioral specs implementation-agnostic.
    - The proposal.md why section should focus on the goal and what we want to achieve, if context is necessary put it after goal statements or in a separate section of that file. 
    - Put implementation details, design considerations, design decisions, mechanisms, integrations, and configuration structures in design.md.
    - No duplicated content across files
    - Avoid statements in one format that are just reworded from other sections. e.g. capabilities as reworded tasks, duplicate 'impact' and 'whats changed' sections.
    - specs folder contents are statements about things that should work particular ways, not just a rewording of tasks
    - avoid tasks that are not actions to be done
    - ensure each task is a logically separate action, group related updates as bullet point details of a single task
    - avoid commentary that doesn't specify anything
    - include a design migration plan only when the change has meaningful deployment sequencing, data migration, compatibility, or rollback complexity; omit it for straightforward configuration changes
    - during implementation record problems and new knowledge in session notes files separate from the spec unless it's actually a change to the design, tasks or spec
    - explicitly list each item that is important to be tested, in tasks.md or a reference to another file. Be concise but list each item separately with a checkbox or bullet point.
- Use the specs as the source of truth, do not rely on agent memory, ensure that reading the specs provides a very similar mental model to the agents model
- do not include extra work that's not part of the active change
- Do not implement broad unrelated refactors inside a feature change.
- After a change is complete
    - update project documentation with new configuration and any valuable knowledge or lesssons learned to remember
    - archive with `openspec archive <change-name>`.
    - Cleanup the git history including the archive operation. Consider rebasing anything that's not pushed to origin to keep medium to large sized commits grouped by logical changes with concise messages. Don't worry about other branches, they can rebase as needed, ensure history retains logical order of operations.

### Lovelace Dashboards

- `ui-lovelace.yaml` — main dashboard
- `ui-lovelace-emily.yaml`, `ui-lovelace-toby.yaml`, `ui-lovelace-pool.yaml` — per-user/feature dashboards. The pool is no longer used.
- `ui-lovelace-kitchen.yaml` — kitchen wall tablet dashboard (`kitchen-display`). Shared `navbar-card` template on every view. The `call` view's `voip-stack-card` has `show_on_ring: true`: it keeps the Kitchen phone online on every view and opens `call` when it rings.
- Dashboard resources are in storage mode (Settings → Dashboards → Resources): HACS and VoIP Stack register their own, with a version stamp that changes on each update. `frontend: extra_module_url` in `packages/common/dashboard.yaml` loads kiosk-mode and card-mod on every dashboard.

### Kitchen tablet

- Before working on the kitchen wall tablet, read README.md → Kitchen Tablet.

## Build and Validation

```bash
# Validate HA config
ha core check

```

## Writing Style
- Write documents in the present tense, as current state.
- A new reader needs what is true now, not how it got there.
- History belongs in git, PR descriptions, changelogs, ADRs and decision records, spec archives, and logs.
- A log is a record that is explicitly dated or append-only; everything else (READMEs, docs, specs, runbooks, code comments) is not one.
- Code comments say why the code is this way now, not how it got here.
- When a past claim turns out wrong, replace it.
- Do not narrate the correction ("was X, now Y", "previously", "earlier claim disproved", dated investigation notes).