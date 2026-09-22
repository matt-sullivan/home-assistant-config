## Context

See `proposal.md` - Why.

Current state: ESPHome device YAML lives at this repo's root (flattened from an earlier `esphome/` subdirectory - see the Decisions entry below), managed by the HA-integrated ESPHome Device Builder add-on (hardcoded to `/config/esphome` on the HA side, HAOS-appliance-only, no arbitrary Docker containers can run alongside it on that VM). ~30 ESP devices (mix of ESP32 and ESP8266), some already on the fleet with existing OTA passwords/API keys in `secrets.yaml` (not yet present in this repo - gitignored, lives only on the HA appliance today).

Target host: `frigate-srv3`, a Proxmox LXC/VM on the same VLAN as Home Assistant and the ESP devices. Interim build/test iteration happens on `agent-srv` (this session's host) before promoting to `frigate-srv3`.

## Goals / Non-Goals

**Goals:**
- Fully decouple the ESPHome dashboard + its AI-editing context from the HA config tree.
- Keep a single live location for ESPHome YAML that both the dashboard and Claude Code operate on directly - no dev/prod file sync step.
- Keep ESPHome version upgrades deliberate and visible.

**Non-Goals:**
- Solving concurrent-job collision between CLI-triggered `esphome run`/`upload` and the Device Builder's internal build queue (see Risks below) - accepted as an operational-discipline problem for now.
- Copying `secrets.yaml` into this repo's checkout or disabling the HA-integrated Device Builder add-on - deferred until this container is built and verified (see Migration Plan).
- Splitting Claude Code into a separate container from the dashboard - explicitly rejected; combined is an accepted tradeoff.

## Decisions

**Base image: `ghcr.io/imagegenius/esphome`, pinned to the `2026.9.0` digest - their Alpine variant, not Ubuntu.**
imagegenius stopped publishing Ubuntu-variant builds after ESPHome 2026.4.5 (`ig147`, ~May 2026) - confirmed via the registry, their `ubuntu` tag never moved again, while their only actively-maintained builds since are Alpine-based (`2026.9.0`'s `/etc/os-release` is Alpine 3.24.1).
Two alternatives were tried and rejected in favor of going back to imagegenius's image directly:
- *Stay on the frozen Ubuntu build* - permanently stuck on ESPHome 2026.4.5, no path forward.
- *`lscr.io/linuxserver/baseimage-ubuntu:noble` + install ESPHome ourselves* (imagegenius's esphome image was itself always just this LinuxServer.io baseimage with ESPHome layered on, confirmed via image labels) - built and fully verified working this way first. Reverted after reconsidering: the original reasons to avoid Alpine (musl/sshd pain, untested PlatformIO/ESP-IDF toolchain compatibility) were re-tested directly against imagegenius's *current* Alpine image and didn't hold up - a full ESP32 compile succeeded with no musl errors, and imagegenius has already done the `esphome-device-builder` migration work (their `svc-esphome` service already execs it, correctly wired). Given that, "someone else maintains the ESPHome version bump" outweighs the self-install approach's main advantage (version independence), which turned out to be a smaller win than expected - a Dockerfile `ARG` bump is about as much effort as a base image tag bump either way.
Pinned by digest (`@sha256:...`), not just the `2026.9.0` tag, for full reproducibility - matches the "pin deliberately" philosophy used for the tag-only Ubuntu pin before, one step more rigorous since bare tags are technically mutable.
Rootful-vs-rootless and other multi-service-container init systems (runit/phusion, supervisord) were considered and rejected regardless of this back-and-forth: none of our rootless-Podman friction (SELinux, `userns=keep-id`) is base-image-dependent, and s6-overlay already works via our own sshd service.

**`/home/abc` is its own dedicated, persisted volume - separate from `/config`, same principle as `/ssh`.**
`abc`'s default home is `/config` (the base image's own convention, for the dashboard's PlatformIO cache - untouched, see below). Left as the shell login home too, every interactive-session tool would write its dotfiles/caches directly into the git-tracked ESPHome checkout: bash history, npm/pip caches, and notably Claude Code's own `.claude/` state. `usermod -d /home/abc abc` gives SSH sessions a separate home; the dashboard's own `svc-esphome/run` still hardcodes `export HOME=/config` regardless of the passwd entry, so its toolchain-cache persistence is unaffected.
Considered seeding `/home/abc` with default dotfiles from `/etc/skel/` on first boot (advice from another session, modeled on a Debian/Ubuntu-style setup) - doesn't apply here: `/etc/skel/` doesn't exist on this Alpine image at all, confirmed by checking rather than assuming. An empty home with bare bash defaults is fine for this container's purpose; not seeding anything.
Real gotcha, only found by testing an actual restart rather than trusting first-boot success: Podman's `:U` mount flag re-chowns the volume to the container's own top-level UID (root, since no Dockerfile `USER` is set) on *every* container start, not just the first. A non-recursive `chown abc:abc /home/abc` only fixed the directory itself each time, leaving files created during the previous session reset to root after every restart - reproduced twice before concluding it was real, not a fluke. Fixed by making it `chown -R`, matching the pattern `/ssh` already used (and needed, for the same reason).

**Two Alpine-specific sshd gotchas, found by testing actual login rather than trusting `docker build` succeeding.**
1. Alpine's `abc` account starts password-locked (`!` in `/etc/shadow`) - OpenSSH refuses *all* authentication for a locked account, pubkey included, regardless of `PasswordAuthentication no`. Fixed with `usermod -p '*' abc` (no valid password, but not locked).
2. The base image's `sshd_config` already has an uncommented default `AuthorizedKeysFile .ssh/authorized_keys`. OpenSSH uses first-occurrence-wins for this directive, so our appended `AuthorizedKeysFile /ssh/authorized_keys` was silently ignored - confirmed via `sshd -T` showing the wrong effective value, not by guessing. Fixed by `sed`-commenting the existing line before appending ours.
Neither surfaced from `podman build` succeeding or the dashboard coming up - both needed an actual SSH login attempt (and for #2, `sshd -T` specifically) to catch. Likely explains the "sshd hard to configure in Alpine" experience that originally ruled Alpine out.

**ESPHome 2026.9.0 removed the built-in `esphome dashboard` command - it's now the separate `esphome-device-builder` package/CLI.**
Discovered by testing: `esphome dashboard /config` (what worked on 2026.4.5) fails outright on 2026.9.0 with an explicit removal notice pointing at `esphome-device-builder`. Its CLI takes the config directory as a plain positional argument (`esphome-device-builder /config`) and already defaults to `--host 0.0.0.0 --port 6052`, so the service definition otherwise looks the same as the old `esphome dashboard` invocation.
It creates its own state files directly in the config directory - `.device-builder-peer-link-key.bin`, `.device-builder-preferences.json`, `.device-builder.json(.lock)` - none of which it gitignores itself (it only auto-writes a starter `.gitignore` when none exists at all, and even that starter only covers `.esphome/`/`secrets.yaml`). Root `.gitignore` now has `.device-builder*` to catch these. (imagegenius's current Alpine image already has `esphome-device-builder` wired up as its `svc-esphome` service, so this migration itself is now their concern, not ours - the gitignore gap remains relevant regardless.)

**Project location: ESPHome device YAML at the repo root, `docker/` as its only subfolder - not a separate sibling repo, not a nested `esphome/` subdirectory either.**
Matt wants ESPHome and Home Assistant config kept in the same git repo, on unrelated branches, each branch deleting the other topic's content, so the branches can be merged back together later if desired. Alternative considered: a true sibling repo at `~/src/esphome-container` - rejected for the same reason as before (this repo's `esphome-main` branch is already ESPHome-only content, so the separation goal is satisfied without a second repo). Alternative considered: keep device YAML nested under an `esphome/` subdirectory with `docker/` (then `esphome-container/`) as its sibling - this was the original layout, but it forced the container to either double-mount the same host directory at two container paths, or symlink `/config` into a subdirectory of a larger mount (which broke - see the container mount decision below). Flattening device YAML to the repo root removes the mismatch entirely: the whole checkout mounts directly at `/config`, matching exactly what the base image expects.

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

**Container sshd listens on port 2222, not the default 22.**
Host networking puts the container's sshd in the same network namespace as the host's own sshd, which already occupies port 22 (confirmed on `agent-srv`; Proxmox LXCs commonly run their own management sshd too, so `frigate-srv3` should be assumed to have the same conflict until checked). Binding to 2222 avoids the collision without giving up host networking.

**Container mount: the whole git checkout is mounted directly at `/config`.**
Tried mounting device YAML nested one level down (`esphome/` subdirectory) first, which needed either a double mount (the same host directory at two container paths - confusing) or a `/config -> .../esphome` symlink baked into the image. The symlink looked clean but didn't work: the base image declares `VOLUME /config`, so Docker/Podman auto-mounts a fresh anonymous volume there at container start, resolving through the symlink and silently shadowing the real content underneath it - files present in the git checkout appeared to "vanish" inside the container (still present on the host, confirmed via direct inspection) and `git status` reported them as deleted. Working around that meant overriding two base-image scripts (`svc-esphome/run`, `init-config-esphome/run`) to point at the nested path directly - functional, but real added complexity.
Flattening device YAML to the repo root (see the project-location decision above) removes the problem at its source: the whole checkout - `.git` included - mounts directly at `/config`, matching the base image's own declared `VOLUME /config` exactly. No anonymous-volume shadowing, no symlink, no base-image script overrides needed. Git (and Claude Code) operate on `/config` natively since it's the real repo root.
`.gitignore` at the repo root must exclude `.esphome/` (ESPHome's own build-cache/PlatformIO directory - large, not meant to be tracked) and `secrets.yaml`.

**SSH host keys and `authorized_keys` live on their own dedicated `/ssh` volume, separate from `/config`.**
They're container-operational data, not part of the ESPHome device-config git history, and must not risk being committed into it - keeping them on a distinct mount makes that structurally impossible rather than just a convention to remember. `git config --system --add safe.directory /config` is also needed in the image - git refuses to operate on a bind-mounted repo whose ownership doesn't match the running user ("dubious ownership") otherwise.

**Claude Code runs inside the same container as the dashboard, with SSH as its access path.**
Alternative considered: separate container for Claude Code, network-mounting the config volume, to shrink the blast radius if Claude Code's environment were ever compromised (it would then have no direct path to `secrets.yaml`/API keys). Rejected - Matt is not concerned about this tradeoff and prefers the operational simplicity of one container.

**Persisted volume location: a subdirectory of `/mnt/container_data` on `frigate-srv3`.**
This is the standard location for container-managed data on that host, e.g. `/mnt/container_data/esphome/config` (the real repo checkout) and `/mnt/container_data/esphome/ssh_keys`. `agent-srv`'s dev/test paths are not constrained to this convention and can use any convenient local path.

**SSH authorized keys: supplied directly by the user, not mirrored from `agent-srv`.**
The original plan was to mirror the public keys already authorized on `agent-srv` itself, but the host has an unusual sshd config and they were too hard to find. The container's `authorized_keys` is populated with keys Matt provides directly instead.

**Claude Code installed via Ubuntu 24.04's default `nodejs`/`npm` apt packages, then `npm install -g @anthropic-ai/claude-code`.**
The base image ships neither Node.js nor Claude Code. Ubuntu 24.04's default `nodejs` apt package was tried first (avoids trusting an extra external apt repository) but freezes at Node 18.x for the life of the release - below Claude Code's declared minimum (>=22.0.0), confirmed via an `EBADENGINE` warning on install. Switched to NodeSource's setup script for Node 22.x, the standard way to get a current Node on Debian/Ubuntu when the distro's own package is too old. Claude Code itself is still not version-pinned - unlike ESPHome, letting it self-update is acceptable.

## Risks / Trade-offs

- **[Risk] No software-level lock between CLI-triggered `esphome run`/`upload` and the Device Builder's internal build/install queue (ESPHome 2026.6.0+).** Both write into the same per-device `.esphome/build/<node_name>/` directory; a concurrent CLI + dashboard job against the *same device* can collide. → **Mitigation:** operational discipline only - don't target the same device from both surfaces at once. No queue API exists to coordinate them as of this writing.
- **[Risk] Collision failure mode is unverified across the whole fleet.** ESP32's dual-partition OTA only swaps images after a full successful receive, so the likely failure mode is a failed/corrupted OTA attempt rather than a bricked device - but this hasn't been confirmed for the ESP8266 boards in the fleet, which may have different OTA partitioning behavior. → **Mitigation:** avoid concurrent access (same as above) until/unless this is tested deliberately.
- **[Risk] Running two ESPHome dashboards (old HA add-on + new container) against the same devices simultaneously** could cause both to think they own a device's build state. → **Mitigation:** sequencing in the Migration Plan below - don't disable the old add-on until the new container is fully verified, and don't run both against the same live device concurrently once the new one is verified.

## Migration Plan

This sequencing exists because two dashboards must never manage the same live device at once, and because the container needs to be proven working before anything is cut over.

1. **Build & verify on `agent-srv`** - build the image, bring up the container, confirm the dashboard UI is reachable, SSH access works (pubkey only), and `esphome` CLI commands run inside the container.
2. **Promote to `frigate-srv3`** - deploy the same container there; confirm mDNS device discovery and dashboard reachability on that host specifically (this is the step that validates the VLAN/broadcast-domain assumption above). On `agent-srv`, mDNS discovery initially found 0 devices despite being on the same subnet as the fleet - the cause was `firewalld`'s active zone not permitting the `mdns` service (interface-level multicast group membership alone isn't enough). Fixed there with `firewall-cmd --permanent --add-service=mdns --zone=<zone> && firewall-cmd --reload`; The `frigate-srv3` IaC config may need updating to allow this.
3. **End-to-end verification against a real device** - point the new container at one real ESP device's existing YAML (read-only check first, then a real `esphome run`/OTA) and confirm it flashes successfully, without the old HA add-on touching that device at the same time.
4. **Cut over** - once verified, check out this repo (ESPHome-only branch) at the container's persisted config volume on `frigate-srv3` and copy `secrets.yaml` in (gitignored, not part of history), then disable/remove the HA-integrated ESPHome Device Builder add-on so only one dashboard manages the fleet.

Rollback: until step 4, the existing HA add-on setup is untouched and remains the fallback - abandoning the new container at any point before cutover has no impact on the current working setup.
