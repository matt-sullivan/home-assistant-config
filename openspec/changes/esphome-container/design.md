## Context

See `proposal.md` - Why.

Current state: ESPHome device YAML lives in `esphome/` inside this repo, managed by the HA-integrated ESPHome Device Builder add-on (hardcoded to `/config/esphome`, HAOS-appliance-only, no arbitrary Docker containers can run alongside it on that VM). ~30 ESP devices (mix of ESP32 and ESP8266), some already on the fleet with existing OTA passwords/API keys in `esphome/secrets.yaml`.

Target host: `frigate-srv3`, a Proxmox LXC/VM on the same VLAN as Home Assistant and the ESP devices. Interim build/test iteration happens on `agent-srv` (this session's host) before promoting to `frigate-srv3`.

## Goals / Non-Goals

**Goals:**
- Fully decouple the ESPHome dashboard + its AI-editing context from the HA config tree.
- Keep a single live location for ESPHome YAML that both the dashboard and Claude Code operate on directly - no dev/prod file sync step.
- Keep ESPHome version upgrades deliberate and visible.

**Non-Goals:**
- Solving concurrent-job collision between CLI-triggered `esphome run`/`upload` and the Device Builder's internal build queue (see Risks below) - accepted as an operational-discipline problem for now.
- Migrating `esphome/` out of this repo or disabling the HA-integrated Device Builder add-on - deferred until this container is built and verified (see Migration Plan).
- Splitting Claude Code into a separate container from the dashboard - explicitly rejected; combined is an accepted tradeoff.

## Decisions

**Base image: `ghcr.io/imagegenius/esphome:ubuntu`, custom Dockerfile on top.**
Chosen over a bare `ubuntu:24.04` build (would require re-implementing PUID/PGID, TZ/UMASK handling) and over forking imagegenius's full repo/CI (unnecessary overhead for a single personal image). imagegenius's image is a straight repackaging of the upstream `esphome` pip package, so ESPHome functionality is identical either way; only the base OS/user-mapping layer differs. The Ubuntu variant is chosen over imagegenius's Alpine variant specifically because the existing ESPHome-CLI sshd setup runs in Alpine and has proven hard to configure - Ubuntu gives a more familiar base for adding and maintaining the sshd service below.

**Project location: `esphome-container/` as a subfolder of `home-assistant-config`, not a separate sibling repo.**
Alternative considered: a true sibling repo at `~/src/esphome-container`, which would more cleanly match the goal of running separate OpenSpec projects per system. Rejected for now because this repo's `esphome-main` branch has already been stripped down to ESPHome-only content (see Context), so nesting here is a much smaller compromise than it would be against a full HA config tree - the repo-level separation goal is satisfied well enough, and what actually matters (no shared files between the *deployed, active* ESPHome and HA config directories) is achieved regardless of where the container's source lives in git.

**ESPHome version: pinned exact version, bumped manually.**
Avoids surprise breakage from upstream releases. Requires the maintainer to periodically check for new releases (no automated notification is in scope for this change).

**sshd added as an s6-rc v3 longrun service, not an entrypoint wrapper.**
The base image uses s6-overlay v3; registering sshd as a proper longrun service lets s6 supervise it alongside the image's existing services with no changes to the existing `/init` entrypoint:
```dockerfile
RUN mkdir -p /etc/s6-overlay/s6-rc.d/sshd
COPY <<EOF /etc/s6-overlay/s6-rc.d/sshd/type
longrun
EOF
COPY --chmod=700 <<EOF /etc/s6-overlay/s6-rc.d/sshd/run
#!/bin/sh
mkdir -p /var/run/sshd
exec /usr/sbin/sshd -D -e
EOF
RUN touch /etc/s6-overlay/s6-rc.d/user/contents.d/sshd
```

**SSH host keys and the ESPHome config directory (including `secrets.yaml`) are both mounted volumes, not baked into the image.**
Host keys: avoids host-key-changed warnings on every rebuild. Config directory: this is the mechanism that keeps "one live location, no sync" true - the same volume the dashboard writes to is what Claude Code and the `esphome` CLI read/write.

**Networking: `--network host` (or macvlan/ipvlan as a fallback).**
mDNS-based device online/offline status and OTA discovery do not work over Docker's default bridge network. Host networking is the simplest option on a single-purpose LXC/VM. Not yet verified: `frigate-srv3`'s exact placement on the same broadcast domain as the ESP devices - confirm before relying on mDNS working end-to-end there (this is a task, not a design uncertainty - the answer doesn't change the approach, only whether extra routing/reflector work is needed).

**Claude Code runs inside the same container as the dashboard, with SSH as its access path.**
Alternative considered: separate container for Claude Code, network-mounting the config volume, to shrink the blast radius if Claude Code's environment were ever compromised (it would then have no direct path to `secrets.yaml`/API keys). Rejected - Matt is not concerned about this tradeoff and prefers the operational simplicity of one container.

**Persisted volume location: a subdirectory of `/mnt/container_data` on `frigate-srv3`.**
This is the standard location for container-managed data on that host, e.g. `/mnt/container_data/esphome-container/config` and `/mnt/container_data/esphome-container/ssh_keys`. `agent-srv`'s dev/test paths are not constrained to this convention and can use any convenient local path.

**SSH authorized keys: mirror the public keys already authorized on `agent-srv`.**
Rather than maintaining a separate key list for the container, its `authorized_keys` is populated from the same set of public keys already trusted for SSH access to `agent-srv` itself, keeping key management in one place.

## Risks / Trade-offs

- **[Risk] No software-level lock between CLI-triggered `esphome run`/`upload` and the Device Builder's internal build/install queue (ESPHome 2026.6.0+).** Both write into the same per-device `.esphome/build/<node_name>/` directory; a concurrent CLI + dashboard job against the *same device* can collide. → **Mitigation:** operational discipline only - don't target the same device from both surfaces at once. No queue API exists to coordinate them as of this writing.
- **[Risk] Collision failure mode is unverified across the whole fleet.** ESP32's dual-partition OTA only swaps images after a full successful receive, so the likely failure mode is a failed/corrupted OTA attempt rather than a bricked device - but this hasn't been confirmed for the ESP8266 boards in the fleet, which may have different OTA partitioning behavior. → **Mitigation:** avoid concurrent access (same as above) until/unless this is tested deliberately.
- **[Risk] Running two ESPHome dashboards (old HA add-on + new container) against the same devices simultaneously** could cause both to think they own a device's build state. → **Mitigation:** sequencing in the Migration Plan below - don't disable the old add-on until the new container is fully verified, and don't run both against the same live device concurrently once the new one is verified.

## Migration Plan

This sequencing exists because two dashboards must never manage the same live device at once, and because the container needs to be proven working before anything is cut over.

1. **Build & verify on `agent-srv`** - build the image, bring up the container, confirm the dashboard UI is reachable, SSH access works (pubkey only), and `esphome` CLI commands run inside the container.
2. **Promote to `frigate-srv3`** - deploy the same container there; confirm mDNS device discovery and dashboard reachability on that host specifically (this is the step that validates the VLAN/broadcast-domain assumption above).
3. **End-to-end verification against a real device** - point the new container at one real ESP device's existing YAML (read-only check first, then a real `esphome run`/OTA) and confirm it flashes successfully, without the old HA add-on touching that device at the same time.
4. **Cut over** - once verified, move the `esphome/` folder and `secrets.yaml` from `home-assistant-config` to the new container's persisted config volume, then disable/remove the HA-integrated ESPHome Device Builder add-on so only one dashboard manages the fleet.

Rollback: until step 4, the existing HA add-on setup is untouched and remains the fallback - abandoning the new container at any point before cutover has no impact on the current working setup.
