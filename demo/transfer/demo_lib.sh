#!/usr/bin/env bash

DEMO_TRANSFER_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DEMO_DIR="$(cd -- "$DEMO_TRANSFER_DIR/.." && pwd)"
DEMO_PYTHON="${DEMO_PYTHON:-$DEMO_DIR/env/bin/python}"
TEMPORAL_ADDRESS="${TEMPORAL_ADDRESS:-localhost:7233}"
TEMPORAL_TASK_QUEUE="${TEMPORAL_TASK_QUEUE:-transfer-task-queue}"
DEMO_TEMP_DIR="$(mktemp -d)"
WORKER_PID=""
STARTER_PID=""
WORKER_COUNT=0
WORKER_LOG=""
STARTER_LOG="$DEMO_TEMP_DIR/starter.log"

cleanup_demo() {
    if [[ -n "$STARTER_PID" ]] && kill -0 "$STARTER_PID" 2>/dev/null; then
        kill -TERM "$STARTER_PID" 2>/dev/null || true
        wait "$STARTER_PID" 2>/dev/null || true
    fi
    if [[ -n "$WORKER_PID" ]] && kill -0 "$WORKER_PID" 2>/dev/null; then
        kill -TERM "$WORKER_PID" 2>/dev/null || true
        wait "$WORKER_PID" 2>/dev/null || true
    fi
    rm -rf -- "$DEMO_TEMP_DIR"
}

trap cleanup_demo EXIT
trap 'exit 130' INT TERM

require_demo_tools() {
    command -v temporal >/dev/null 2>&1 || {
        echo "Temporal CLI is required." >&2
        return 1
    }
    [[ -x "$DEMO_PYTHON" ]] || {
        echo "Demo Python environment not found at $DEMO_PYTHON." >&2
        echo "See demo/README.md for setup." >&2
        return 1
    }
    temporal operator cluster health --address "$TEMPORAL_ADDRESS" >/dev/null || {
        echo "Cannot reach Temporal at $TEMPORAL_ADDRESS. Start it with demo/start_server.sh." >&2
        return 1
    }
}

wait_for_log() {
    local log_file="$1"
    local expected="$2"
    local attempts="${3:-300}"

    for ((index = 0; index < attempts; index++)); do
        if grep -Fq -- "$expected" "$log_file" 2>/dev/null; then
            return 0
        fi
        if [[ -n "$STARTER_PID" ]] && ! kill -0 "$STARTER_PID" 2>/dev/null && [[ "$log_file" == "$STARTER_LOG" ]]; then
            cat "$log_file" >&2
            return 1
        fi
        if [[ -n "$WORKER_PID" ]] && ! kill -0 "$WORKER_PID" 2>/dev/null && [[ "$log_file" == "$WORKER_LOG" ]]; then
            cat "$log_file" >&2
            return 1
        fi
        sleep 0.2
    done

    echo "Timed out waiting for '$expected' in $log_file." >&2
    cat "$log_file" >&2 || true
    return 1
}

start_demo_worker() {
    WORKER_COUNT=$((WORKER_COUNT + 1))
    WORKER_LOG="$DEMO_TEMP_DIR/worker-$WORKER_COUNT.log"
    TEMPORAL_ADDRESS="$TEMPORAL_ADDRESS" TEMPORAL_TASK_QUEUE="$TEMPORAL_TASK_QUEUE" PYTHONUNBUFFERED=1 "$DEMO_PYTHON" "$DEMO_TRANSFER_DIR/worker.py" >"$WORKER_LOG" 2>&1 &
    WORKER_PID=$!
    wait_for_log "$WORKER_LOG" "Transfer Worker started with identity:"
    sed -n '1p' "$WORKER_LOG"
}

start_demo_workflow() {
    TEMPORAL_ADDRESS="$TEMPORAL_ADDRESS" TEMPORAL_TASK_QUEUE="$TEMPORAL_TASK_QUEUE" PYTHONUNBUFFERED=1 "$DEMO_PYTHON" "$DEMO_TRANSFER_DIR/starter.py" "$@" >"$STARTER_LOG" 2>&1 &
    STARTER_PID=$!
    wait_for_log "$STARTER_LOG" "Workflow ID:"
    WORKFLOW_ID="$(sed -n 's/^Workflow ID: //p' "$STARTER_LOG" | head -n 1)"
    echo "Workflow ID: $WORKFLOW_ID"
}

stop_demo_worker() {
    if [[ -n "$WORKER_PID" ]] && kill -0 "$WORKER_PID" 2>/dev/null; then
        kill -KILL "$WORKER_PID" 2>/dev/null || true
        wait "$WORKER_PID" 2>/dev/null || true
    fi
    WORKER_PID=""
}

wait_for_history_event() {
    local event="$1"
    local attempts="${2:-100}"

    for ((index = 0; index < attempts; index++)); do
        if temporal workflow show --workflow-id "$WORKFLOW_ID" 2>/dev/null | grep -Fq -- "$event"; then
            return 0
        fi
        sleep 0.2
    done

    echo "Timed out waiting for Event History event '$event'." >&2
    temporal workflow show --workflow-id "$WORKFLOW_ID" >&2 || true
    return 1
}

latest_run_id() {
    temporal workflow describe --workflow-id "$WORKFLOW_ID" | awk '$1 == "RunId" { print $2 }'
}

wait_for_demo_workflow() {
    local status=0
    wait "$STARTER_PID" || status=$?
    STARTER_PID=""
    cat "$STARTER_LOG"
    return "$status"
}
