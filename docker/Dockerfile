# syntax=docker/dockerfile:1
FROM lscr.io/linuxserver/baseimage-ubuntu:noble

# ESPHome, sshd + Claude Code's runtime (Node.js/npm). ESPHome is pinned
# deliberately (bump manually) and installed as a plain pip package on top
# of LinuxServer.io's own actively-maintained Ubuntu+s6-overlay baseimage -
# not imagegenius's esphome image, which is itself built FROM this same
# base but stopped publishing Ubuntu builds after ESPHome 2026.4.5.
# See openspec/changes/archive/2026-09-17-esphome-container/design.md.
ARG ESPHOME_VERSION=2026.9.0
ARG DEVICE_BUILDER_VERSION=1.14.9
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      python3 python3-pip python3-venv \
      openssh-server git ca-certificates curl gnupg && \
    pip install --break-system-packages --no-cache-dir \
      "esphome==${ESPHOME_VERSION}" \
      "esphome-device-builder==${DEVICE_BUILDER_VERSION}" && \
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    rm -rf /var/lib/apt/lists/* && \
    rm -f /etc/ssh/ssh_host_*_key /etc/ssh/ssh_host_*_key.pub && \
    usermod -s /bin/bash abc && \
    npm install -g @anthropic-ai/claude-code && \
    git config --system --add safe.directory /config

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
    } >> /etc/ssh/sshd_config

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
mkdir -p /var/run/sshd
exec /usr/sbin/sshd -D -e
EOF
RUN touch /etc/s6-overlay/s6-rc.d/user/contents.d/sshd
