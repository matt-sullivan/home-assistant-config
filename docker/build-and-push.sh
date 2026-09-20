#!/usr/bin/env bash
# Build the ESPHome container image and push it to GHCR, tagged by git
# commit SHA (not `latest`) so every deployed image traces back to an
# exact, reproducible commit - consistent with this project's pinned-
# version convention for ESPHome/Node.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

REGISTRY="ghcr.io"
OWNER="matt-sullivan"
IMAGE_NAME="esphome"
PAT_FILE="${GHCR_PAT_FILE:-$HOME/.ghcr_pat}"

if [ -n "$(git status --porcelain)" ]; then
  echo "Uncommitted changes present - commit first so the image tag traces to a real commit." >&2
  exit 1
fi

SHA="$(git rev-parse --short HEAD)"
REMOTE_TAG="${REGISTRY}/${OWNER}/${IMAGE_NAME}:${SHA}"

echo "Building ${IMAGE_NAME}:local (also tagging ${REMOTE_TAG})..."
podman build -t "${IMAGE_NAME}:local" .
podman tag "${IMAGE_NAME}:local" "$REMOTE_TAG"

if [ ! -f "$PAT_FILE" ]; then
  echo "PAT file not found at $PAT_FILE (set GHCR_PAT_FILE to override)." >&2
  exit 1
fi

podman login "$REGISTRY" -u "$OWNER" --password-stdin < "$PAT_FILE"
podman push "$REMOTE_TAG"

echo ""
echo "Pushed: $REMOTE_TAG"
