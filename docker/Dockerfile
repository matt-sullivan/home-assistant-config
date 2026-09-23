# syntax=docker/dockerfile:1
FROM lscr.io/linuxserver/baseimage-ubuntu:resolute

LABEL org.opencontainers.image.title="ESPHome" \
      org.opencontainers.image.description="ESPHome Device Builder dashboard + sshd + Claude Code, for standalone ESPHome device management" \
      org.opencontainers.image.source="https://github.com/matt-sullivan/home-assistant-config"

# Disable PlatformIO's telemetry and self-update-nag check. get_setting()'s
# real check (platformio/app.py) reads a PLATFORMIO_SETTING_<NAME> env var
# first, before any per-user settings file - confirmed by reading that
# source - so this covers both runtime HOME contexts below (the dashboard
# service's HOME=/config, and SSH sessions' HOME=/home/abc) with one setting.
ENV PLATFORMIO_SETTING_ENABLE_TELEMETRY=No
ENV PLATFORMIO_SETTING_CHECK_PLATFORMIO_INTERVAL=1000000
# ESP-IDF's own build system has documented ccache support gated on this
# var. Only confirmed to help ESP-IDF-framework compiles (our ESP32
# devices) - Arduino/LibreTiny use PlatformIO's own SCons build instead,
# where ccache benefit isn't confirmed.
ENV IDF_CCACHE_ENABLE=1

# ESPHome, sshd, ccache + Claude Code's runtime (Node.js/npm), on top of
# LinuxServer.io's own actively-maintained Ubuntu+s6-overlay baseimage -
# not imagegenius's esphome image (itself built FROM this same base, but
# stopped publishing Ubuntu builds after ESPHome 2026.4.5 - see design.md).
# No version pins anywhere here - every rebuild picks up whatever's
# currently latest/stable (base image, ESPHome, packages, Node LTS).
# Version control happens by choosing when to rebuild and push
# (docker/build-and-push.sh is already a manual, deliberate action), not
# by pinning a version in source.
# Package list beyond the obvious (python3/openssh-server/git/curl/ccache)
# borrowed from upstream esphome/docker-base's own Debian image - a
# proven-working list rather than rediscovering missing build deps one
# `esphome compile` failure at a time (already happened twice in this
# project's history - see NOTES.md): build-essential (C-extension pip
# installs, native build tools), libusb-1.0-0 (USB/serial flashing, e.g.
# a device's first flash before it has OTA credentials), libcairo2
# (font/display-rendering components), libmagic1t64 (the dashboard's
# upload MIME-type detection), patch (some external PlatformIO libraries
# apply patches during their build), openssh-client + iputils-ping
# (git+ssh remotes, basic network debugging), nano (editing files directly
# in an SSH session).
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      python3 python3-pip python3-venv \
      openssh-server openssh-client git ca-certificates curl gnupg \
      ccache build-essential libusb-1.0-0 libcairo2 libmagic1t64 \
      patch iputils-ping nano && \
    pip install --break-system-packages --no-cache-dir \
      esphome esphome-device-builder && \
    curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    rm -rf /var/lib/apt/lists/* && \
    rm -f /etc/ssh/ssh_host_*_key /etc/ssh/ssh_host_*_key.pub && \
    usermod -s /bin/bash -d /home/abc abc && \
    npm install -g @anthropic-ai/claude-code && \
    git config --system --add safe.directory /config && \
    git config --system advice.detachedHead false
# usermod -d /home/abc abc: abc's default home is /config (the ESPHome
# checkout) - shell/tool dotfiles (bash history, npm/pip caches, Claude
# Code's own state) would otherwise land directly in that git-tracked tree.
# /home/abc is its own dedicated, persisted volume (mounted at runtime) -
# same "container-operational data, not ESPHome device-config data"
# principle as /ssh below. The dashboard service's own `export HOME=/config`
# below is unrelated to this - that's ESPHome's own convention for
# persisting its PlatformIO toolchain cache, not the shell user's home.
# advice.detachedHead false: the dashboard's version-history feature checks
# out old revisions internally, which would otherwise print a detached-HEAD
# warning into its logs on every such checkout.

# Register the ESPHome dashboard as an s6-rc v3 longrun service. The base
# image has no VOLUME /config declaration (that was imagegenius's addition,
# specific to their esphome image), so there's no anonymous-volume-shadowing
# risk here - the checkout mounted at /config is exactly what this reads.
RUN mkdir -p /etc/s6-overlay/s6-rc.d/svc-esphome/dependencies.d && \
    touch /etc/s6-overlay/s6-rc.d/svc-esphome/dependencies.d/init-services
COPY <<'EOF' /etc/s6-overlay/s6-rc.d/svc-esphome/type
longrun
EOF
COPY --chmod=755 <<'EOF' /etc/s6-overlay/s6-rc.d/svc-esphome/run
#!/usr/bin/with-contenv bash
export HOME=/config
exec s6-setuidgid abc esphome-device-builder /config
EOF
RUN touch /etc/s6-overlay/s6-rc.d/user/contents.d/svc-esphome

# Pubkey-only auth. Host keys and authorized_keys live on their own dedicated
# /ssh volume (mounted at runtime), deliberately separate from /config -
# they're container-operational data, not part of the ESPHome device-config
# git history, and must not risk being committed into it.
RUN { \
      echo ''; \
      echo 'Port 2222'; \
      echo 'PasswordAuthentication no'; \
      echo 'PermitRootLogin no'; \
      echo 'KbdInteractiveAuthentication no'; \
      echo 'HostKey /ssh/ssh_host_rsa_key'; \
      echo 'HostKey /ssh/ssh_host_ed25519_key'; \
      echo 'AuthorizedKeysFile /ssh/authorized_keys'; \
      echo 'SetEnv PLATFORMIO_SETTING_ENABLE_TELEMETRY=No PLATFORMIO_SETTING_CHECK_PLATFORMIO_INTERVAL=1000000'; \
    } >> /etc/ssh/sshd_config
# SetEnv (not a Dockerfile ENV): sshd never forwards the container's own
# process environment to login/exec sessions it spawns (PAM-style session
# isolation, confirmed by testing - a Docker/Podman -e var is invisible in
# an actual SSH session even though the same var reaches the dashboard
# process fine, since that one's a direct child of the container's own
# init). SetEnv (OpenSSH 8.7+) is sshd's own mechanism for this and applies
# to every session, interactive or a single `ssh host cmd`.

# Register sshd as an s6-rc v3 longrun service, alongside the ESPHome
# dashboard service above - no changes needed to the base image's /init.
RUN mkdir -p /etc/s6-overlay/s6-rc.d/sshd/dependencies.d && \
    touch /etc/s6-overlay/s6-rc.d/sshd/dependencies.d/init-services
COPY <<'EOF' /etc/s6-overlay/s6-rc.d/sshd/type
longrun
EOF
COPY --chmod=700 <<'EOF' /etc/s6-overlay/s6-rc.d/sshd/run
#!/usr/bin/with-contenv bash
mkdir -p /ssh
for t in rsa ed25519; do
  key="/ssh/ssh_host_${t}_key"
  [ -f "$key" ] || ssh-keygen -t "$t" -f "$key" -N '' -q
done
touch /ssh/authorized_keys
chown -R abc:abc /ssh
chmod 700 /ssh
chmod 600 /ssh/authorized_keys /ssh/ssh_host_*_key
mkdir -p /home/abc
chown -R abc:abc /home/abc
mkdir -p /var/run/sshd
exec /usr/sbin/sshd -D -e
EOF
RUN touch /etc/s6-overlay/s6-rc.d/user/contents.d/sshd

# HEALTHCHECK needs `podman push --format v2s2`, not just `--format docker`
# at build time, to actually survive to GHCR - see docker/build-and-push.sh.
# `podman push`'s own format auto-negotiation otherwise falls back to an
# OCI manifest (confirmed via `skopeo inspect --raw` against the published
# image - likely because at least one layer is zstd-compressed, which the
# Docker v2s2 schema can't represent), and OCI's image-spec config has no
# Healthcheck field at all - not lost, structurally impossible to carry in
# that manifest type. Forcing v2s2 on push makes Podman re-encode any such
# layer instead (confirmed working via a local `dir:` transport push).
HEALTHCHECK --interval=30s --timeout=10s \
    CMD curl --fail http://localhost:6052/version -A "HealthCheck" || exit 1
