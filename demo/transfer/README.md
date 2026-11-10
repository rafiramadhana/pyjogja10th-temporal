# Withdrawal and Deposit Demo

This demo runs a dummy withdrawal followed by a dummy deposit. It performs no real banking operations. The Workflow and Activity payloads are dataclasses displayed as JSON objects in Temporal UI. Regular scenarios use amount `"10000.00"` in `"IDR"`; the Reset scenario uses `"0.00"` to trigger a code-level failure.

## Files

```text
transfer/
├── activities.py                 # Dummy act_withdraw and act_deposit Activities
├── workflows.py                  # WfTransfer, object payloads, and retry settings
├── worker.py                     # Registers WfTransfer and both Activities
├── starter.py                    # Starts a uniquely identified Workflow
├── test_activities.py            # Checks success and simulated failures
├── demo_lib.sh                   # Shared script helpers and cleanup
├── demo_worker_crash.sh          # Stops and restarts a Worker between Activities
├── demo_activity_retry.sh        # Fails deposit twice, then succeeds
├── demo_ui_reset.sh              # Fails on 0.00, reloads fixed code, then resets
└── README.md                     # Runbook for the demo and scripts
```

## Requirements and configuration

Start the local Temporal Service with [`../start_server.sh`](../README.md#start-the-local-temporal-service) and open <http://localhost:8233>. The scripts use `localhost:7233` by default. They also require the Temporal CLI, the shared `../env/` Python environment, Bash, and the standard `timeout` command for the UI Reset walkthrough.

The Workflow has no Retry Policy, a 10-second Workflow Task timeout, no Workflow Run timeout, and a 1-hour Workflow Execution timeout. Both Activities use `RetryPolicy(maximum_attempts=3)` and a 30-second Start-To-Close timeout. Three maximum attempts means one initial attempt and up to two retries. No Activity Schedule-To-Close timeout is set. See the [retry and timeout reference](../retry-and-timeout.md) for details.

## Run the regular demo

In one terminal, start the Worker:

```bash
cd demo/transfer
../env/bin/python worker.py
```

In another terminal, start a Workflow:

```bash
../env/bin/python starter.py
```

The starter prints its Workflow ID before waiting for the result. In Temporal UI, inspect the Workflow and Run IDs, the completed withdrawal followed by deposit, and the object inputs and results. The Worker prints a new random identity each time it starts.

## Talk scenario scripts

Run each script from the project root. Each script starts its own Worker and Workflow, stores its marker and logs in a temporary directory, and removes the temporary files and any Worker it started when it exits. Start the Temporal Service once before running the scenarios.

| Script | Purpose | Command | Approximate talk time |
|---|---|---|---:|
| `demo_worker_crash.sh` | Stop the Worker after withdrawal and restart it after the pause. | `./demo/transfer/demo_worker_crash.sh` | 4 minutes |
| `demo_activity_retry.sh` | Fail deposit twice, then show success on the third attempt. | `./demo/transfer/demo_activity_retry.sh` | 3 minutes |
| `demo_ui_reset.sh` | Exhaust retries on `0.00`, comment out the guard, restart the Worker, then Reset in Temporal UI. | `./demo/transfer/demo_ui_reset.sh` | 6 minutes |
| `demo_lib.sh` | Shared helper sourced by the three scripts; manages processes, logs, and temporary cleanup. | Do not run directly. | Included above |

### Worker crash and recovery

1. Run `./demo/transfer/demo_worker_crash.sh` and show the printed Workflow ID.
2. The script waits until withdrawal completes, stops its Worker, waits through the 8-second Workflow timer, and starts another Worker.
3. Show that the Workflow completes in the same Run and that the withdrawal Activity did not execute again during replay.

Expected duration is about 4 minutes including explanation. The script itself usually takes around 20 seconds.

### Automatic Activity retry

1. Run `./demo/transfer/demo_activity_retry.sh` and locate the new Workflow in Temporal UI.
2. Point out two failed deposit attempts followed by a successful third attempt.
3. Show the final deposit result and the Workflow's completed status.

Expected duration is about 3 minutes including explanation. The script itself usually takes several seconds.

### Exhausted retries and manual UI Reset

1. Run `./demo/transfer/demo_ui_reset.sh`. It starts the Workflow with amount `"0.00"`; the marked guard makes deposit fail on all three attempts.
2. Find the printed Workflow ID in Temporal UI. Show the completed withdrawal and the exhausted deposit failure.
3. The script stops its Worker. At the terminal prompt, comment out the marked `if request.amount == "0.00":` guard and its `raise ApplicationError` block in `activities.py`, then save the file.
4. Press Enter. The script restarts the Worker so it loads the fix.
5. In the Workflow details page, choose **Reset**. For this demo, select Event ID `10` (`WorkflowTaskCompleted`), after withdrawal completed and before deposit ran. Confirm the event and surrounding history, add a reason such as `Fix zero-amount deposit handling`, then submit Reset.
6. Press Enter in the terminal. The script waits for the reset Run to complete and prints its result.
7. Show that the Workflow ID is the same, the Run ID changed, withdrawal progress was preserved, and deposit completed in the new Run.

The fault is the `if request.amount == "0.00":` guard block marked `DEMO_FAULT_START` in `activities.py`. Comment out the `if` and its `raise ApplicationError` block, then restart the Worker. Reset copies history up to the selected point into a new Run; Event ID `10` is the Workflow Task completion at the withdrawal-to-deposit transition. Inspect the event label and surrounding history before confirming so the new Run preserves the completed withdrawal and schedules deposit again.

Expected duration is about 6 minutes including the code edit, Worker restart, UI navigation, and explanation. Restore the zero-amount guard before rehearsing this scenario again. The script remains running during the manual steps; press Ctrl+C to abort.

## Run activity checks

From `demo/`, run the focused Activity checks:

```bash
env/bin/python -m unittest discover -s transfer -p 'test_*.py'
```
