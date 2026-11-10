#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/demo_lib.sh"
TEMPORAL_TASK_QUEUE="transfer-demo-crash-$$"

require_demo_tools
start_demo_worker
start_demo_workflow --pause-seconds 8
wait_for_log "$WORKER_LOG" "Withdrawal completed:"
initial_worker_log="$WORKER_LOG"
wait_for_history_event "TimerStarted"
original_run_id="$(latest_run_id)"

echo "Stopping the Worker after withdrawal while the Workflow timer is pending."
stop_demo_worker
sleep 9

echo "Restarting the Worker after the pause."
start_demo_worker
wait_for_demo_workflow
recovered_run_id="$(latest_run_id)"
echo "Run ID before Worker crash: $original_run_id"
echo "Run ID after recovery:      $recovered_run_id"
if [[ "$original_run_id" != "$recovered_run_id" ]]; then
    echo "Expected Worker recovery to continue the same Workflow Run." >&2
    exit 1
fi
echo "Initial Worker Activity log:"
grep -E 'Withdrawal completed:|Deposit completed:' "$initial_worker_log" || true
echo "Restarted Worker Activity log:"
grep -E 'Withdrawal completed:|Deposit completed:' "$WORKER_LOG" || true
if grep -Fq 'Withdrawal completed:' "$WORKER_LOG"; then
    echo "The restarted Worker unexpectedly reran withdrawal." >&2
    exit 1
fi
