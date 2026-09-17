# Proposal

- Decouple ESPHome device management from Home Assistant by self-hosting the ESPHome dashboard in its own container.
- Give that container SSH and Claude Code access so device configs can be edited and deployed directly, with no separate dev environment.

## Why

- Stop Claude Code from loading and reasoning about both HA and ESPHome context when only one is relevant. The HA-integrated ESPHome Device Builder add-on is hardcoded to `/config/esphome`, so the ESPHome source must stay nested while that add-on is used; Claude has tools to filter files but they're fragile.
- The existing sshd used for ESPHome CLI access runs in an Alpine container that's hard to configure, making Claude Code harder to use for ESPHome work than it should be.
- Reduce/separate disk usage on the Home Assistant host - ESPHome data alone is >10GB, which is a lot to carry as an HA add-on.
- Run clearly separate OpenSpec projects for ESPHome and HA core config.
- Keep deployment simple: edit files directly on the ESPHome/HA server, with no separate dev environment requiring files to be synced. The repo itself can stay nested (`esphome-container/` as a subfolder - see `design.md`), but once deployed, neither system's *active* configuration directory contains the other's files.

## What Changes

- New custom, version-pinned Docker image for the ESPHome dashboard container - base image and sshd mechanism decided in `design.md`.
- Documented networking and deployment-target requirements needed for the dashboard to work correctly - see `design.md`.

## Capabilities

### New Capabilities
- `esphome-dashboard-hosting`: standalone containerized ESPHome Device Builder dashboard, decoupled from the HA config tree, reachable over the network with mDNS device discovery working.
- `container-remote-access`: SSH and Claude Code access into the container, and CLI-driven ESPHome compile/flash/OTA operations, without exposing HA secrets or credentials.

### Modified Capabilities
(none — this is a new standalone system; no existing specs in this repo)

## Impact

- New `esphome-container/` subfolder in this repo, with its own `AGENTS.md`/`CLAUDE.md` distinct from the HA-focused conventions at the repo root.
- This change documents design/specs only - no tasks tracked here per the user's request; sequencing (build, verify, migrate, cut over) is documented as a Migration Plan in `design.md` instead.
