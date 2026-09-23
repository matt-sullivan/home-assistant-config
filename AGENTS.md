# ESPHome Config Guidelines

This repository branch `esphome-main` is scoped to ESPHome device configuration only. The full Home Assistant config is in this repo on the main branch; this branch holds ESPHome device YAML at its root and the docker project that hosts the ESPHome dashboard, sshd, and Claude Code for ESPHome work.

- Keep changes focused and preserve existing conventions.
- Do not expose secrets from `secrets.yaml`.
- Be very concise in everything you write
- Be very thorough in any analysis, do not jump to conclusions

## Repo Structure

- Device YAML files — ESPHome device configs, live at the repo root so the whole checkout can be mounted directly into the docker container as its `/config`.
- `packages/` - Reusable ESPHome configuration files included into device-specific files in the repo root. Try to put any logic shared by multiple devices into files in this folder so it can be reused.
- `archive/` - ESPHome device configs for devices no longer in use (these could just be deleted and rely on git for history, but archive is a native ESPHome feature)
- `secrets.yaml` (gitignored) holds ESPHome secrets.
- `docker/` — standalone Docker container hosting the ESPHome dashboard, sshd, and Claude Code, decoupled from Home Assistant. See "Docker Container" below.
- `openspec/` — A specification framework to document requirements and changes. https://openspec.dev/ Used here to specify behaviour of both devices and `docker` container.

## ESPHome Usage, Build and Validation 

In most cases you're running in an environment with the `esphome` CLI available, to be run directly against device configuration files under `/config`

```bash
esphome compile <file>.yaml   # validate + compile only
esphome run <file>.yaml       # compile + OTA + tail logs
esphome upload <file>.yaml    # compile + flash, no log tail
```

Avoid running these against a device the container's own dashboard has a build/install job in flight for - there's no software-level lock between them, see the concurrency risk in `design.md`.

## OpenSpec

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
    - ensure document references are correct (especially due to archiving)
    - Cleanup the git history including the archive operation. Consider rebasing anything that's not pushed to origin to keep medium to large sized commits grouped by logical changes with concise messages. Don't worry about other branches, they can rebase as needed, ensure history retains logical order of operations.


## Docker Container
- The main development environment for esphome devices is an instance of a docker container running on `frigate-srv3`. This also hosts the esphome device builder dashboard.

- `docker/Dockerfile` builds `FROM lscr.io/linuxserver/baseimage-ubuntu:resolute` - ESPHome + `esphome-device-builder` installed via `pip`, Node.js via NodeSource's `setup_lts.x` (Ubuntu's own default `nodejs` apt package is frozen well below Claude Code's minimum). Not imagegenius's Alpine esphome image - LibreTiny/BK72xx (Beken) devices need a glibc-linked ARM toolchain that doesn't run on musl even with Alpine's `gcompat` shim (confirmed: reproduced the exact `obstack_vprintf: symbol not found` failure, tried every suggested Alpine compat package, none provide that symbol - see design.md). No version pinning anywhere in this image - every rebuild picks up whatever's current (base image, ESPHome, packages, Node LTS). Version control happens by choosing *when* to rebuild and deploy, not by pinning a version in source.
- The whole git checkout (this repo's ESPHome-only branch root, `.git` included) is mounted directly at `/config` inside the container, with no symlink or base-image script overrides needed, **and is directly readable/writable from the host shell** (see below - not a given, had to be fixed). SSH host keys and `authorized_keys` live on a separate `/ssh` volume; `abc`'s shell login home (`/home/abc` - bash history, npm/pip caches, Claude Code's own state) is a third, separate volume too - none of these three get baked into the image or mixed into `/config`'s git history. All three need `chown -R`, not just `chown`, in whatever runs at container start (they're mounted `:Z` only, no `:U` - see design.md for why `:U` was dropped: it re-chowns to root on every start, not just the first, fighting our own `chown -R` rather than cooperating with it).
- The Quadlet unit uses `UserNS=keep-id` + `User=0` (not `UserNS=host`) - this is what makes the three bind mounts above land on the host as `core:core` instead of an opaque subuid-mapped UID unreadable outside the container, which is the actual point of using bind mounts over named Podman volumes. Requires `PUID`/`PGID` to equal the deploying host user's own UID/GID (`core` = 1000 on both `agent-srv` and `frigate-srv3` - see design.md for why this is a real precondition, not incidental).
- `.gitignore` at the repo root excludes `.esphome/`, `.device-builder*` (the dashboard's own state files - it doesn't gitignore these itself), and `secrets.yaml`.
- sshd listens on port 2222, not 22 - host networking puts the container in the same network namespace as the host's own sshd on port 22.
- Claude Code is installed via npm in the Dockerfile - not version-pinned; it auto-updates itself.
- PlatformIO telemetry is disabled (`PLATFORMIO_SETTING_*` env vars, plus sshd's own `SetEnv` so it also reaches SSH sessions - a plain Dockerfile `ENV` doesn't, confirmed by testing) and `ccache`/`IDF_CCACHE_ENABLE` speed up repeat ESP-IDF compiles. A `HEALTHCHECK` hits the dashboard's `/version` endpoint - needs `docker/build-and-push.sh`'s `podman build --format docker`, since Podman's default OCI format silently drops `HEALTHCHECK`.

**`agent-srv` builds the image, never runs it** - no local dev/test container there. Build and push to GHCR:

```bash
docker/build-and-push.sh
```

Tags `ghcr.io/matt-sullivan/esphome` as both `latest` (what gets deployed) and `<date>-<git-sha>` (a historical breadcrumb, not meant to be deployed from directly). Refuses to run on a dirty working tree, so the history tag always traces to a real commit. Prefer `podman build` directly over `docker build --load` on memory-constrained hosts - see `openspec/changes/archive/2026-09-17-esphome-container/NOTES.md`.

**Only `frigate-srv3` runs the container**, via a Quadlet unit pulling `ghcr.io/matt-sullivan/esphome:latest`. Dashboard: `http://frigate-srv3:6052`. SSH: `ssh -p 2222 abc@frigate-srv3` (pubkey only).

## Servers

- Do not modify any live server's configuration as part of development work (e.g. `agent-srv`, `frigate-srv3`) - they're managed as IaC and are rebuilt, not hand-edited, when something needs to change. Building/running/testing the `docker/` container itself is fine (that's inherently ephemeral/rebuildable); host-level changes (packages, firewall rules, system config) are not, even via passwordless `sudo` - ask first.
