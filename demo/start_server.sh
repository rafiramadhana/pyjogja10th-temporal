#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TEMPORAL_ADDRESS="${TEMPORAL_ADDRESS:-localhost:7233}"
TEMPORAL_DB_FILE="${TEMPORAL_DB_FILE:-$SCRIPT_DIR/temporal.db}"
TEMPORAL_PORT="${TEMPORAL_PORT:-7233}"
TEMPORAL_UI_PORT="${TEMPORAL_UI_PORT:-8233}"

if ! command -v temporal >/dev/null 2>&1; then
    echo "Temporal CLI is required. Install it using the local Quickstart instructions." >&2
    exit 1
fi

if temporal operator cluster health --address "$TEMPORAL_ADDRESS" >/dev/null 2>&1; then
    echo "Temporal is already reachable at $TEMPORAL_ADDRESS."
    echo "Web UI: http://localhost:$TEMPORAL_UI_PORT"
    exit 0
fi

mkdir -p "$(dirname -- "$TEMPORAL_DB_FILE")"
server_args=(server start-dev --db-filename "$TEMPORAL_DB_FILE" --port "$TEMPORAL_PORT" --ui-port "$TEMPORAL_UI_PORT")
if [[ -n "${TEMPORAL_METRICS_PORT:-}" ]]; then
    server_args+=(--metrics-port "$TEMPORAL_METRICS_PORT")
fi

echo "Starting Temporal at $TEMPORAL_ADDRESS with persistence in $TEMPORAL_DB_FILE."
echo "Web UI: http://localhost:$TEMPORAL_UI_PORT"
exec temporal "${server_args[@]}"
