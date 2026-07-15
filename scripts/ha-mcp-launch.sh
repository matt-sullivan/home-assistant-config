#!/usr/bin/env sh
set -eu

ENV_FILE="${HA_MCP_ENV_FILE:-$HOME/.config/ha-mcp.env}"

if [ -f "$ENV_FILE" ]; then
  # shellcheck source=/dev/null
  . "$ENV_FILE"
fi

if [ -z "${HOMEASSISTANT_URL:-}" ]; then
  echo "HOMEASSISTANT_URL is not set. Expected in $ENV_FILE" >&2
  exit 1
fi

if [ -z "${HOMEASSISTANT_TOKEN:-}" ]; then
  echo "HOMEASSISTANT_TOKEN is not set. Expected in $ENV_FILE" >&2
  exit 1
fi

export HOMEASSISTANT_URL
export HOMEASSISTANT_TOKEN

exec uvx ha-mcp "$@"
