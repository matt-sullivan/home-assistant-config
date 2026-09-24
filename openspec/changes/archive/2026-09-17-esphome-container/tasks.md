## 1. Container image

- [x] 1.1 Write the Dockerfile `FROM ghcr.io/imagegenius/esphome:ubuntu`, pinned to a specific ESPHome version, and verify `docker build` succeeds and the resulting image reports that exact ESPHome version.
- [x] 1.2 Add sshd as an s6-rc v3 longrun service per `design.md`, and verify sshd is running inside a started container.
- [x] 1.3 Configure sshd for pubkey-only authentication and verify a password login attempt is rejected.
- [x] 1.4 Install Node.js (Ubuntu 24.04 default `nodejs`/`npm` packages) and the Claude Code CLI (`npm install -g @anthropic-ai/claude-code`); verify `claude --version` runs successfully inside a started container.

## 2. Persistent volumes and networking (on `agent-srv`)

- [x] 2.1 Create host directories for the ESPHome config volume and the SSH host-key volume, and mount them in the container run/compose config; verify a container restart does not change the SSH host key fingerprint.
- [x] 2.2 Authorize Matt's SSH public key in the container's `authorized_keys` (see `design.md` - `agent-srv` turned out to have no keys to mirror); key is in place and validates correctly.
- [x] 2.3 Run the container with host networking (`--network host` or macvlan/ipvlan) and verify the dashboard UI is reachable via HTTP from another machine on the same network.

## 3. Capability verification (test config, not the production fleet)

- [x] 3.1 Point the container at a test ESPHome YAML config and verify the dashboard shows a real device on the network as online via mDNS.
- [x] 3.2 Run `esphome run <test>.yaml` from inside the container over SSH and verify it compiles and completes successfully.
- [x] 3.3 Edit the test YAML file via Claude Code inside the container and verify a subsequent `esphome run`/`upload` picks up the change with no separate sync step.

## 4. Documentation

- [x] 4.1 Add `esphome-container/AGENTS.md`/`CLAUDE.md` scoped to container/infra conventions, distinct from the HA-focused conventions at the repo root, and verify it's present alongside the Dockerfile.
- [x] 4.2 Update the repo-root `AGENTS.md` and `README.md` to drop the stale full-HA-config description and reflect this branch's ESPHome-only scope, noting the new `esphome-container/` subfolder; verify by re-reading both files.
