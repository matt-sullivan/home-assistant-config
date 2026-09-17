# syntax=docker/dockerfile:1
FROM ghcr.io/imagegenius/esphome:ubuntu-2026.4.5-ig147

# sshd + Claude Code's runtime (Node.js/npm), on top of the imagegenius ESPHome image.
# See openspec/changes/esphome-container/design.md for the rationale behind each decision below.
RUN apt-get update && \
    apt-get install -y --no-install-recommends openssh-server nodejs npm git python3-venv && \
    rm -rf /var/lib/apt/lists/* && \
    rm -f /etc/ssh/ssh_host_*_key /etc/ssh/ssh_host_*_key.pub && \
    usermod -s /bin/bash abc && \
    npm install -g @anthropic-ai/claude-code && \
    git config --system --add safe.directory /config

# The repo's ESPHome-only branch keeps device YAML at the branch root (not in
# an `esphome/` subdirectory), so the git checkout - `.git` included - is
# mounted directly at /config: one mount, matching the base image's own
# `VOLUME /config` declaration exactly and Git operates on
# /config natively since it's the real repo root.

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

# Register sshd as an s6-rc v3 longrun service, alongside the image's existing
# services - no changes needed to its /init entrypoint.
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
