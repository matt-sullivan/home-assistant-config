# syntax=docker/dockerfile:1
FROM ghcr.io/imagegenius/esphome:latest

LABEL org.opencontainers.image.title="ESPHome" \
      org.opencontainers.image.description="ESPHome Device Builder dashboard + sshd + Claude Code, for standalone ESPHome device management" \
      org.opencontainers.image.source="https://github.com/matt-sullivan/home-assistant-config"

# Disable PlatformIO's telemetry and self-update-nag check (adopted from
# upstream esphome/docker-base, which does this via `platformio settings
# set` at build time - doesn't work for us since that writes to the
# *build-time* root user's ~/.platformio, but our actual runtime compiles
# happen as a different user/HOME - abc via SSH, or HOME=/config for the
# dashboard service. get_setting()'s real check (platformio/app.py) reads
# a PLATFORMIO_SETTING_<NAME> env var first, before the per-user file -
# confirmed by reading that source - so this env var covers both without
# needing to touch either runtime HOME.
ENV PLATFORMIO_SETTING_ENABLE_TELEMETRY=No
ENV PLATFORMIO_SETTING_CHECK_PLATFORMIO_INTERVAL=1000000
# ESP-IDF's own build system has documented ccache support gated on this
# var. Only confirmed to help ESP-IDF-framework compiles (our ESP32
# devices) - Arduino/LibreTiny use PlatformIO's own SCons build instead,
# where ccache benefit isn't confirmed.
ENV IDF_CCACHE_ENABLE=1

# sshd + ccache + Claude Code's runtime (Node.js/npm), on top of
# imagegenius's Alpine ESPHome image. Alpine is actively maintained by
# imagegenius (unlike their now-abandoned Ubuntu variant - see design.md),
# already ships ESPHome and esphome-device-builder pre-wired as an s6-rc
# service, and ships gcompat (glibc compatibility shim, needed for e.g.
# VS Code Remote-SSH) out of the box. Node/npm come straight from Alpine's
# own package index (current versions - no NodeSource repo needed, unlike
# Ubuntu's frozen default).
# See openspec/changes/archive/2026-09-17-esphome-container/design.md.
RUN apk add --no-cache openssh-server nodejs npm ccache && \
    rm -f /etc/ssh/ssh_host_*_key /etc/ssh/ssh_host_*_key.pub && \
    usermod -s /bin/bash -d /home/abc -p '*' abc && \
    npm install -g @anthropic-ai/claude-code && \
    git config --system --add safe.directory /config && \
    git config --system advice.detachedHead false
# advice.detachedHead false (adopted from upstream esphome/esphome's own
# Dockerfile): the dashboard's version-history feature checks out old
# revisions internally, which would otherwise print a detached-HEAD
# warning into its logs on every such checkout.
# usermod -p '*' abc: Alpine's abc account starts password-locked ("!" in
# /etc/shadow), which OpenSSH refuses to authenticate at all - even via
# pubkey. "*" means no valid password (not locked), consistent with
# PasswordAuthentication no below.
# usermod -d /home/abc abc: abc's default home is /config (the ESPHome
# checkout) - shell/tool dotfiles (bash history, npm/pip caches, Claude
# Code's own state) would otherwise land directly in that git-tracked tree.
# /home/abc is its own dedicated, persisted volume (mounted at runtime) -
# same "container-operational data, not ESPHome device-config data"
# principle as /ssh below. The ESPHome dashboard service's own
# `export HOME=/config` (in svc-esphome/run, untouched) is unrelated to
# this - that's ESPHome's own convention for persisting its PlatformIO
# toolchain cache, not the shell user's home.

# Pubkey-only auth. Host keys and authorized_keys live on their own dedicated
# /ssh volume (mounted at runtime), deliberately separate from /config -
# they're container-operational data, not part of the ESPHome device-config
# git history, and must not risk being committed into it.
# The base image's sshd_config already has an uncommented default
# AuthorizedKeysFile - OpenSSH uses first-occurrence-wins for this directive,
# so appending our own below would otherwise be silently ignored (confirmed
# via `sshd -T`). Comment out the existing one so ours is the only, and thus
# effective, occurrence.
RUN sed -i 's/^AuthorizedKeysFile[[:space:]].*/#&/' /etc/ssh/sshd_config && \
    { \
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

# Register sshd as an s6-rc v3 longrun service, alongside the image's own
# esphome-device-builder service - no changes needed to its /init entrypoint.
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

HEALTHCHECK --interval=30s --timeout=10s \
    CMD curl --fail http://localhost:6052/version -A "HealthCheck" || exit 1
