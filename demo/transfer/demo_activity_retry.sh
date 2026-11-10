#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/demo_lib.sh"
TEMPORAL_TASK_QUEUE="transfer-demo-retry-$$"

require_demo_tools
failure_marker="$DEMO_TEMP_DIR/deposit-failures"
printf '2' >"$failure_marker"

start_demo_worker
start_demo_workflow --failure-marker "$failure_marker"
wait_for_demo_workflow

echo "Deposit attempts observed by the Worker:"
grep -n -E 'Simulated retryable deposit failure|Deposit completed:' "$WORKER_LOG"
