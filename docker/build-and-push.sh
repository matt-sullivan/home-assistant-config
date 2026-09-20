#!/usr/bin/env bash
# Build the ESPHome container image and push it to GHCR as both `latest`
# (what frigate-srv3 deploys) and a `<date>-<git-sha>` tag (a historical
# breadcrumb, not meant to be deployed from directly).
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

REGISTRY="ghcr.io"
OWNER="matt-sullivan"
IMAGE_NAME="esphome"
PAT_FILE="${GHCR_PAT_FILE:-$HOME/.ghcr_pat}"

if [ -n "$(git status --porcelain)" ]; then
  echo "Uncommitted changes present - commit first so the history tag traces to a real commit." >&2
  exit 1
fi

HISTORY_TAG="${REGISTRY}/${OWNER}/${IMAGE_NAME}:$(date +%Y-%m-%d)-$(git rev-parse --short HEAD)"
LATEST_TAG="${REGISTRY}/${OWNER}/${IMAGE_NAME}:latest"

echo "Building ${IMAGE_NAME}:local (also tagging ${LATEST_TAG} and ${HISTORY_TAG})..."
podman build -t "${IMAGE_NAME}:local" .
podman tag "${IMAGE_NAME}:local" "$LATEST_TAG"
podman tag "${IMAGE_NAME}:local" "$HISTORY_TAG"

if [ ! -f "$PAT_FILE" ]; then
  echo "PAT file not found at $PAT_FILE (set GHCR_PAT_FILE to override)." >&2
  exit 1
fi

podman login "$REGISTRY" -u "$OWNER" --password-stdin < "$PAT_FILE"
podman push "$LATEST_TAG"
podman push "$HISTORY_TAG"

echo ""
echo "Pushed: $LATEST_TAG"
echo "Pushed: $HISTORY_TAG"
