# ESPHome Config Guidelines

This repository branch `esphome-main` is scoped to ESPHome device configuration only. The full Home Assistant config is in this repo on the main branch; this branch holds ESPHome device YAML at its root and the docker project that hosts the ESPHome dashboard, sshd, and Claude Code for ESPHome work.

- Keep changes focused and preserve existing conventions.
- Do not expose secrets from `secrets.yaml`.
- Be very concise in everything you write
- Be very thorough in any analysis, do not jump to conclusions

## Key Conventions

### Repo Structure

- Device YAML files, `packages/`, `archive/` — ESPHome device configs, live at the repo root so the whole checkout can be mounted directly into the docker container as its `/config`.
- `secrets.yaml` (gitignored) holds ESPHome secrets.
- `docker/` — standalone Docker container hosting the ESPHome dashboard, sshd, and Claude Code, decoupled from Home Assistant. See "Docker Container" below.
- `openspec/` — covers this whole ESPHome project (device configs and the `docker/` container alike), not just one part of it.

### ESPHome

- Device configs are currently also managed via the HA-integrated ESPHome Device Builder add-on until docker is deployed and cut over (see `openspec/changes/archive/2026-09-17-esphome-container/design.md`'s Migration Plan). See the `esphome-remote-cli-access` skill for CLI access to that add-on. **Note:** if that add-on's deployment pulls from this repo's old `esphome/` subdirectory path, flattening device configs to the repo root may need a matching update there - that's a live-server change, out of scope for this repo and not something to do without Matt's explicit direction (see "Servers" below).
- Once docker is deployed and cut over, use it directly instead — compile/flash/OTA via its own `esphome` CLI over SSH (see "Docker Container" below).

### Docker Container

- Do not add Home Assistant config, secrets, or automations to `docker/` - it's scoped to ESPHome only.
- `docker/Dockerfile` builds `FROM ghcr.io/imagegenius/esphome`, pinned by digest to their `2026.9.0` (Alpine) build - bump deliberately, pin by digest not just tag (see `openspec/changes/archive/2026-09-17-esphome-container/design.md` for why Alpine, and why not the Ubuntu variant - imagegenius abandoned it after ESPHome 2026.4.5). ESPHome + `esphome-device-builder` (the dashboard - a separate package since ESPHome 2026.9.0) come pre-wired from the base image; Node.js/npm are added via `apk` (current versions, unlike Ubuntu's frozen default apt package).
- The whole git checkout (this repo's ESPHome-only branch root, `.git` included) is mounted directly at `/config` inside the container - matches the base image's own `VOLUME /config` declaration exactly, so git works natively there with no symlink or base-image script overrides needed. SSH host keys and `authorized_keys` live on a separate `/ssh` volume; `abc`'s shell login home (`/home/abc` - bash history, npm/pip caches, Claude Code's own state) is a third, separate volume too - none of these three get baked into the image or mixed into `/config`'s git history. All three need `chown -R`, not just `chown`, in whatever runs at container start (they're mounted `:Z` only, no `:U` - see design.md for why `:U` was dropped: it re-chowns to root on every start, not just the first, fighting our own `chown -R` rather than cooperating with it).
- `.gitignore` at the repo root excludes `.esphome/`, `.device-builder*` (the dashboard's own state files - it doesn't gitignore these itself), and `secrets.yaml`.
- sshd listens on port 2222, not 22 - host networking puts the container in the same network namespace as the host's own sshd on port 22. Two Alpine-specific sshd fixes are baked into the Dockerfile (see design.md): the `abc` account starts password-locked (blocks *all* auth, not just password) and the base image's `sshd_config` has a conflicting default `AuthorizedKeysFile` that silently wins over ours unless commented out first.
- Claude Code is installed via npm in the Dockerfile - not version-pinned; it auto-updates itself.

**`agent-srv` builds the image, never runs it** - no local dev/test container there. Build and push to GHCR:

```bash
docker/build-and-push.sh
```

Tags `ghcr.io/matt-sullivan/esphome` as both `latest` (what gets deployed) and `<date>-<git-sha>` (a historical breadcrumb, not meant to be deployed from directly). Refuses to run on a dirty working tree, so the history tag always traces to a real commit. Prefer `podman build` directly over `docker build --load` on memory-constrained hosts - see `openspec/changes/archive/2026-09-17-esphome-container/NOTES.md`.

**Only `frigate-srv3` runs the container**, via a Quadlet unit pulling `ghcr.io/matt-sullivan/esphome:latest` - see the Migration Plan in `design.md`. Dashboard: `http://frigate-srv3:6052`. SSH: `ssh -p 2222 abc@frigate-srv3` (pubkey only; add keys to `/ssh/authorized_keys`).

Once inside the container (via SSH), use the `esphome` CLI directly against files under `/config`:

```bash
esphome compile <file>.yaml   # validate + compile only
esphome run <file>.yaml       # compile + OTA + tail logs
esphome upload <file>.yaml    # compile + flash, no log tail
```

Do not run these against a device the HA-integrated ESPHome Device Builder add-on is also managing at the same time - see the concurrency risk in `design.md`.

### Servers

- Do not modify any live server's configuration as part of development work (e.g. `agent-srv`, `frigate-srv3`) - they're managed as IaC and are rebuilt, not hand-edited, when something needs to change. Building/running/testing the `docker/` container itself is fine (that's inherently ephemeral/rebuildable); host-level changes (packages, firewall rules, system config) are not, even via passwordless `sudo` - ask first.

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
- do not include extra work that's not part of the active change
- Do not implement broad unrelated refactors inside a feature change.
- After a change is complete
    - update project documentation with new configuration and any valuable knowledge or lesssons learned to remember
    - archive with `openspec archive <change-name>`.
    - Cleanup the git history including the archive operation. Consider rebasing anything that's not pushed to origin to keep medium to large sized commits grouped by logical changes with concise messages. Don't worry about other branches, they can rebase as needed, ensure history retains logical order of operations.

## Build and Validation

There is no Home Assistant config in this repo to validate. For ESPHome config validation, use `esphome config <file>.yaml` — via the remote add-on today, or inside docker once it's deployed.
