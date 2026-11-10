#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/demo_lib.sh"
TEMPORAL_TASK_QUEUE="transfer-demo-reset-$$"

require_demo_tools

start_demo_worker
start_demo_workflow --amount "0.00"

workflow_status=0
wait_for_demo_workflow || workflow_status=$?
if [[ "$workflow_status" -eq 0 ]]; then
    echo "Expected the simulated deposit to exhaust its retries, but the Workflow succeeded." >&2
    exit 1
fi
failed_run_id="$(latest_run_id)"

echo "The Workflow failed after one initial deposit attempt and two retries."
echo "Open http://localhost:8233 and locate Workflow ID: $WORKFLOW_ID"
echo "Verify withdrawal completed and deposit retries are exhausted."
echo
stop_demo_worker
echo "Worker stopped so it can reload the edited Activity code."
read -r -p "Comment out the DEMO_FAULT_START zero-amount guard in activities.py, save, then press Enter... "
start_demo_worker
echo "The restarted Worker has loaded the fix. The UI Reset can now resume deposit successfully."
echo "In the Workflow UI, choose Reset and select Event ID 10 (WorkflowTaskCompleted), after withdrawal and before deposit. Add a reason and confirm."
read -r -p "Press Enter after Reset completes and the new Run starts... "

echo "Waiting for the reset Run to complete..."
timeout 90 temporal workflow result --workflow-id "$WORKFLOW_ID"
reset_run_id="$(latest_run_id)"
echo "Failed Run ID: $failed_run_id"
echo "Reset Run ID:  $reset_run_id"
if [[ "$failed_run_id" == "$reset_run_id" ]]; then
    echo "Expected Reset to create a new Workflow Run." >&2
    exit 1
fi
