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
# --format docker: Podman's default OCI image format silently drops
# HEALTHCHECK. Not sufficient on its own, though - see the --format v2s2
# on push below.
podman build --format docker -t "${IMAGE_NAME}:local" .
podman tag "${IMAGE_NAME}:local" "$LATEST_TAG"
podman tag "${IMAGE_NAME}:local" "$HISTORY_TAG"

if [ ! -f "$PAT_FILE" ]; then
  echo "PAT file not found at $PAT_FILE (set GHCR_PAT_FILE to override)." >&2
  exit 1
fi

podman login "$REGISTRY" -u "$OWNER" --password-stdin < "$PAT_FILE"
# --format v2s2: podman push's own format auto-negotiation falls back to
# an OCI manifest even for a --format docker build (confirmed via
# `skopeo inspect --raw` against a real push - likely because at least
# one layer is zstd-compressed, which the Docker v2s2 schema can't
# represent) - OCI's image-spec config has no Healthcheck field at all,
# so it silently vanishes. Forcing v2s2 here makes Podman re-encode any
# such layer instead, keeping the manifest genuinely Docker-format all
# the way to the registry.
podman push --format v2s2 "$LATEST_TAG"
podman push --format v2s2 "$HISTORY_TAG"

echo ""
echo "Pushed: $LATEST_TAG"
echo "Pushed: $HISTORY_TAG"
