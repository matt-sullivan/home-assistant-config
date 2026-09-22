# syntax=docker/dockerfile:1
FROM ghcr.io/imagegenius/esphome:2026.9.0@sha256:fcdacda5421503d7a73dfc039110f015841c733bb07e4d5db946e6483db4a36f

# sshd + Claude Code's runtime (Node.js/npm), on top of imagegenius's Alpine
# ESPHome image. Alpine is actively maintained by imagegenius (unlike their
# now-abandoned Ubuntu variant - see design.md), already ships ESPHome and
# esphome-device-builder pre-wired as an s6-rc service, and ships gcompat
# (glibc compatibility shim, needed for e.g. VS Code Remote-SSH) out of the
# box. Node/npm come straight from Alpine's own package index (current
# versions - no NodeSource repo needed, unlike Ubuntu's frozen default).
# See openspec/changes/archive/2026-09-17-esphome-container/design.md.
RUN apk add --no-cache openssh-server nodejs npm && \
    rm -f /etc/ssh/ssh_host_*_key /etc/ssh/ssh_host_*_key.pub && \
    usermod -s /bin/bash -d /home/abc -p '*' abc && \
    npm install -g @anthropic-ai/claude-code && \
    git config --system --add safe.directory /config
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
    } >> /etc/ssh/sshd_config

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
