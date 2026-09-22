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
Real gotcha, only found by testing an actual restart rather than trusting first-boot success: Podman's `:U` mount flag re-chowns the volume to the container's own top-level UID (root, since no Dockerfile `USER` is set) on *every* container start, not just the first. A non-recursive `chown abc:abc /home/abc` only fixed the directory itself each time, leaving files created during the previous session reset to root after every restart - reproduced twice before concluding it was real, not a fluke.
Root cause, confirmed by a research pass reading Podman's own source (`libpod/container_internal_common.go`): `:U`'s doc comment ("chown on initial creation") is misleading - it actually runs a cheap top-level-only ownership check on *every* start, and falls through to a full recursive chown to the container's configured UID (root here) whenever that check fails, which it always does once our own start script has legitimately changed ownership to `abc` in a prior run. So `:U` and our own `chown -R` were fighting each other every restart, not cooperating.
Fix: drop `:U` from the mount flags entirely, keep only `:Z` (SELinux relabel) - our own `chown -R abc:abc` in `sshd/run` (`docker/Dockerfile`) is then the only ownership mechanism and runs uncontested. `:U`'s bootstrap role (first-run chown from root-owned host dir) isn't needed either: verified directly by mounting a virgin, host-`core`-owned directory with `:Z` only - no permission error, ownership lands correctly. Also verified across two separate `podman restart` cycles with all three volumes (`/config`, `/ssh`, `/home/abc`) mounted `:Z`-only: ownership stayed `abc:users` throughout, no regression. This relies on `UserNS=host` (Quadlet)/`--userns=host` (CLI) being set, which this project always does - see the Quadlet unit in the Migration Plan below.
Kernel ID-mapped mounts (`idmap`) were also considered as a cleaner alternative to both `:U` and manual `chown -R` - confirmed rootful-Podman-only via the same research pass, not usable here since this deploys rootless. No reason to reconsider rootful for this.

**Superseded: `UserNS=host` (above) defeats the actual reason these are bind mounts, not Podman volumes - fixed by switching to `UserNS=keep-id` + `User=0`.**
The `:Z`-only fix above was verified from *inside* the container, but `UserNS=host`'s default rootless mapping sends container UID 1000 (`abc`) to a **subuid-range host UID** (e.g. `525287`, not `core`'s own UID) - so once the container starts even once, the host user (`core`) can no longer read or write `/config`, `/ssh`, or `/home/abc` directly at all (`Permission denied` on a plain host-side `ls`/edit/`rm`). That silently broke the actual point of bind-mounting the git checkout instead of using a named volume: a human editing YAML, running `git log`, or managing SSH keys straight from the host shell. Caught by re-reading the original goal, not by a new bug report.
Root cause and fix, from a second research pass plus direct verification: Podman's rootless `keep-id` userns mode maps the *invoking host user's own UID* 1:1 into the container (`core`=1000 ↔ container UID 1000), which is exactly what's needed - but by design it also runs the container's PID1 *as* that mapped UID instead of as root, which breaks s6-overlay's root-requiring init entirely (it checks the literal running UID, not `/etc/passwd`, and disables all custom longrun services - sshd, the dashboard - with "You are running this container as a non-root user"). This is LinuxServer.io's own stated reason rootless Podman is unsupported by their images at all (confirmed via their support forum), not something specific to this project's setup, and it's confirmed as the documented (if not formally named) Podman answer via `containers/podman#24934`: pair `UserNS=keep-id` with an explicit `User=0` override, so PID1 stays real root (s6-overlay inits normally) while keep-id's mapping table still lands container UID 1000 on host `core`.
Verified end-to-end, including the one failure mode specific to this deployment path that a general test wouldn't catch: a Quadlet-generated systemd unit (`containers/podman#25395`) has been reported to fail `UserNS=keep-id` containers with an overlay-permission error on some Podman versions, when a plain hand-run `podman run` with the same flags works fine - since this project deploys exclusively via Quadlet/systemd (`Network=host`, never `docker-compose`/manual `podman run`), that specific path was tested directly: cold `systemctl --user start` (not just `podman restart`) from fresh volumes, a `systemctl --user restart`, and a full `stop`+`start` cycle (simulating a host reboot) - all clean on Podman 5.8.4, no overlay error, correct `core:core` host ownership and a working host-side direct file write throughout. `loginctl show-user core` shows `Linger=yes` on both `agent-srv` and `frigate-srv3` already (a prerequisite for a rootless Podman systemd unit to start at boot), so nothing further needed there.
This scheme has one real precondition worth stating explicitly, since it isn't obvious from `keep-id`'s name alone: **`PUID`/`PGID` must equal the UID/GID of whichever host user actually runs the Quadlet unit** (verified `core` = UID/GID 1000 on both `agent-srv` and `frigate-srv3`, same `/etc/subuid`/`/etc/subgid` range `524288:65536`) - keep-id only passes through the *invoking user's own* UID 1:1; if `PUID`/`PGID` were ever set to a different value than that user's real UID, `abc` would fall back to a subuid-offset host UID and silently reintroduce this exact problem. Not currently a risk (both hosts use `core`, UID 1000) but a fragile assumption to keep in mind if either host's deploy user ever changes.
The `:Z`-only conclusion itself is unaffected (SELinux relabeling and userns UID mapping are orthogonal mechanisms) - only `UserNS=` and `User=` change. The base image's own recursive `/config` chown and this project's `chown -R abc:abc` in `sshd/run` are also unchanged in behavior - what changes is only which host UID `abc:abc` now resolves to.

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

**Claude Code installed via `apk add nodejs npm`, then `npm install -g @anthropic-ai/claude-code` - superseded by the Alpine base-image switch, keeping the historical record below.**
~~Claude Code installed via Ubuntu 24.04's default `nodejs`/`npm` apt packages, then `npm install -g @anthropic-ai/claude-code`.~~ The base image ships neither Node.js nor Claude Code. Ubuntu 24.04's default `nodejs` apt package was tried first (avoids trusting an extra external apt repository) but freezes at Node 18.x for the life of the release - below Claude Code's declared minimum (>=22.0.0), confirmed via an `EBADENGINE` warning on install. Switched to NodeSource's setup script for Node 22.x, the standard way to get a current Node on Debian/Ubuntu when the distro's own package is too old.
Moot once the base image switched to imagegenius's Alpine variant (see the base-image Decision above): Alpine's own `apk` package index ships current Node/npm versions directly (no frozen-release problem, no NodeSource-equivalent needed) - `RUN apk add --no-cache openssh-server nodejs npm` in `docker/Dockerfile`. Claude Code itself is still not version-pinned - unlike ESPHome, letting it self-update is acceptable.

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

### Deployment reference (Quadlet unit)

```ini
[Unit]
Description=ESPHome dashboard + sshd + Claude Code

[Container]
Image=ghcr.io/matt-sullivan/esphome:latest
ContainerName=esphome
Network=host
UserNS=keep-id
User=0
Environment=PUID=1000
Environment=PGID=1000
Volume=/mnt/container_data/esphome/config:/config:Z
Volume=/mnt/container_data/esphome/ssh_keys:/ssh:Z
Volume=/mnt/container_data/esphome/home-abc:/home/abc:Z

[Service]
Restart=on-failure

[Install]
WantedBy=default.target
```

Place at `~/.config/containers/systemd/esphome.container` (rootless, user `core`) on `frigate-srv3`, then `systemctl --user daemon-reload && systemctl --user start esphome.service`. `loginctl show-user core` must show `Linger=yes` for the unit to also start at boot (already the case on both `agent-srv` and `frigate-srv3` - see the `keep-id` Decision above).

`PUID`/`PGID` must equal the UID/GID of whatever user actually runs this Quadlet unit (`core`=1000 on both hosts currently) - not a fixed value, see the `keep-id` Decision above for why.

Before first start: create the three host directories (`mkdir -p`, no chown/relabel needed - see below) and, at `/mnt/container_data/esphome/config`, either an empty directory (`esphome-device-builder` will initialize it) or a real `git clone` of this repo with `secrets.yaml` copied in (gitignored, not part of history). Optionally seed `/mnt/container_data/esphome/ssh_keys/authorized_keys` with a pubkey before the very first start (see below for why only before, not after).

Connecting once running: dashboard at `http://frigate-srv3:6052`; SSH at `ssh -p 2222 abc@frigate-srv3` (pubkey only).

### Bind-mount ownership findings (read before touching the three volumes above)

All three volumes (`/config`, `/ssh`, `/home/abc`) are plain host directories, not named Podman volumes, specifically so a human can read/edit them directly from the host shell - not just from inside the container. Getting that right took several iterations; only the final state matters operationally, but the reasoning is worth knowing before changing any mount flag:

- **Mount flags: `:Z` only, never `:U`.** `:U` re-chowns the mount to the container's UID on *every* start (not just the first), fighting the ownership this project's own scripts already establish. `:Z` (SELinux relabel) is still required and is applied automatically by Podman on each start - no manual relabeling needed.
- **`UserNS=keep-id` + `User=0` is required together, not either alone.** `UserNS=host` (Podman's rootless default) works internally but sends the container's `abc` user to an opaque subuid-range host UID (e.g. `525287`), not `core` - the host user then can't read or write these directories at all. Plain `keep-id` fixes that UID mapping but also runs the container's PID1 as the mapped non-root UID, which breaks the base image's s6-overlay init (it disables all custom services - sshd, the dashboard - when it isn't run as real root). `User=0` forces PID1 back to real root under `keep-id`, so both properties hold at once.
- **No manual chown/chmod/relabel is needed when provisioning the three directories for the first time.** `mkdir -p` (or a plain `git clone` for `/config`) as the host user that runs the Quadlet unit is sufficient. Ownership is established recursively on every start - by the base image's own init for `/config`, and by this project's own `chown -R abc:abc` in `docker/Dockerfile`'s `sshd/run` for `/ssh` and `/home/abc` - confirmed to correctly re-own an entire pre-existing tree (tested against a real populated `git clone`, not just an empty directory), and confirmed to survive repeated restarts, including cold starts via the actual Quadlet/systemd path (not just `podman run`/`podman restart`).
- **After the container's first start, the three directories are still directly host-editable** (that's the entire point of `keep-id`+`User=0` over the earlier, rejected `UserNS=host` approach) - a host-side `cat`/edit/`git` command against `/mnt/container_data/esphome/config` works the same before and after the container has run, unlike the earlier `UserNS=host` state where it stopped working after first start. This includes `authorized_keys` (`chmod 600`'d by the container's own `sshd/run` script, but owned by `core`, so `core` can read/write it directly at any time, not just before the container's first start) - confirmed by directly appending a key from the host shell to a running container's `authorized_keys` and seeing the change take effect. No need to route key rotation through `podman exec`.
- Full reasoning, source citations (Podman docs/source, GitHub issues, LinuxServer.io's own stance on rootless Podman), and the empirical tests that proved each step are in the Decisions section above (`/home/abc` entry) and `NOTES.md`'s dated session-notes entries for 2026-09-22.
