# When Python Jobs Fail: Moving from Retries to Durable Execution

## 1.1: A withdrawal can succeed before a deposit

A simple transaction has two steps: withdraw, then deposit. These function calls strip away Temporal and object models to show the business sequence. If the Worker stops after withdrawal, the process must remember that the first step succeeded before it can safely continue.

```python
# The simple version assumes both calls return normally.
withdrawal_id = act_withdraw(amount="10000.00", currency="IDR")
deposit_id = act_deposit(amount="10000.00", currency="IDR")
```

The sequence is short, but the process can stop between the calls. After restart, ordinary Python memory does not tell the application whether withdrawal completed.

## 1.2: Recovery adds application code

Teams may add retries, saved progress, and idempotency keys so a restarted process can continue. Each mechanism helps, but the application must keep them consistent.

```python
from time import monotonic, sleep


def run_transfer(request_id):
    deadline = monotonic() + 30
    for attempt in range(3):
        try:
            # A stable key helps the service recognize a repeated request.
            withdrawal_id = act_withdraw(
                amount="10000.00",
                currency="IDR",
                idempotency_key=request_id,
                timeout=5,
            )
            break
        except TimeoutError:
            if attempt == 2 or monotonic() >= deadline:
                raise
            sleep(min(2**attempt, deadline - monotonic()))

    # The app must also decide how to safely retry and track this next step.
    deposit_id = act_deposit(
        amount="10000.00",
        currency="IDR",
        idempotency_key=request_id,
        timeout=5,
    )
```

The snippet adds retry limits, delays, per-call timeouts, an overall deadline, and stable request keys. It still needs durable progress storage so a restart can tell whether withdrawal already completed.

## 1.3: Five recovery complexities

| Complexity | Description |
|---|---|
| Safe retries | Decide which failures can be retried and when to stop. |
| Saved progress | Record completed steps so recovery can continue at the right point. |
| Duplicate protection | Make repeated requests safe when a timeout leaves the outcome uncertain. |
| Time limits | Choose deadlines for each attempt and the overall process. |
| Troubleshooting | See what completed and give an operator a safe recovery point. |

These concerns grow as a process gains steps and external systems. Temporal provides durable Workflow state and Activity retry behavior so application code can focus on the business sequence.

## 2.1: Temporal concepts

| Concept | What | Why |
|---|---|---|
| Workflow | Code that defines and coordinates a durable process. | Temporal can preserve progress and resume it after a Worker failure. |
| Activity | A function that performs work outside the Workflow. | External work can fail and be retried independently. |
| Worker | An application process that runs Workflow and Activity code. | Temporal Service schedules work while Workers execute it. |
| Event History | The recorded events and results for a Workflow Execution. | It preserves the source of truth for progress. |
| Replay | Re-running Workflow code against its recorded Event History. | It rebuilds Workflow state and reuses completed Activity results. |

Durable Workflow execution is the combined behavior: Temporal stores progress in Event History, and a Worker uses Replay to reconstruct the Workflow after a failure.

## 2.2: The concepts in Quickstart code

The Quickstart keeps each role small. `greet` is the Activity, `SayHelloWorkflow` calls it, the Worker registers both, and the starter launches the Workflow.

```python
# activities.py: the Activity does the greeting work.
from temporalio import activity


@activity.defn
async def greet(name: str) -> str:
    return f"Hello {name}"
```

```python
# workflows.py: the Workflow coordinates the Activity.
from datetime import timedelta
from temporalio import workflow

with workflow.unsafe.imports_passed_through():
    from activities import greet


@workflow.defn
class SayHelloWorkflow:
    @workflow.run
    async def run(self, name: str) -> str:
        return await workflow.execute_activity(
            greet,
            name,
            schedule_to_close_timeout=timedelta(seconds=10),
        )
```

```python
# worker.py: register the code that this Worker can run.
import asyncio

from temporalio import workflow
from temporalio.client import Client
from temporalio.worker import Worker

with workflow.unsafe.imports_passed_through():
    from activities import greet
    from workflows import SayHelloWorkflow


async def main() -> None:
    client = await Client.connect("localhost:7233")
    worker = Worker(
        client,
        task_queue="my-task-queue",
        workflows=[SayHelloWorkflow],
        activities=[greet],
    )
    await worker.run()


if __name__ == "__main__":
    asyncio.run(main())
```

```python
# starter.py: start the Workflow and wait for its result.
import asyncio
import uuid

from temporalio.client import Client

from workflows import SayHelloWorkflow


async def main() -> None:
    client = await Client.connect("localhost:7233")
    result = await client.execute_workflow(
        SayHelloWorkflow.run,
        "Temporal",
        id=f"say-hello-workflow-{uuid.uuid4()}",
        task_queue="my-task-queue",
    )
    print("Workflow result:", result)


if __name__ == "__main__":
    asyncio.run(main())
```

The Workflow and Worker must use the same Task Queue name. The greeting is intentionally simple so the roles are easy to see before the transfer demo adds real recovery scenarios.

## 2.3: Replay makes Workflows durable

If a Worker stops after `greet` completes but before the Workflow finishes, Temporal still has the Activity result in Event History. Another Worker replays the Workflow code, uses the recorded greeting, and completes the Workflow without calling `greet` again.

```mermaid
sequenceDiagram
    autonumber
    actor User
    participant Server as Temporal Server
    participant Worker
    User->>Server: Start SayHelloWorkflow("Temporal")
    Worker->>Server: Poll for Workflow Task
    Server-->>Worker: Workflow Task
    Worker->>Server: Schedule greet Activity
    Worker->>Server: Poll for Activity Task
    Server-->>Worker: Activity Task for greet
    Worker->>Worker: Run greet("Temporal")
    Worker->>Server: Report "Hello Temporal"
    Note over Server: Record Activity result in Event History
    Note over Worker: Worker stops before Workflow completion
    Worker->>Server: New Worker polls for Workflow Task
    Server-->>Worker: Workflow Task with Event History
    Note over Worker: Replay rebuilds state and reuses "Hello Temporal"
    Note over Worker: greet does not run a second time
    Worker->>Server: Complete SayHelloWorkflow with recorded result
    Server-->>User: Return "Hello Temporal"
```

Replay is not retry. Replay rebuilds Workflow state from history; an Activity retry runs the Activity again after a failed attempt. Section 3 applies durable Workflow recovery to the withdrawal and deposit process.

Temporal has more concepts beneath this introduction. This iceberg is a quick map for later exploration, not a section we will explain in detail.

| Level | Concepts | Description |
|---|---|---|
| Upper — 3 | Workflow, Activity, Worker | The application pieces introduced in this talk. |
| Middle — 5 | Event History, Replay, Task Queue, Retry Policy, Timeout | How Temporal records progress, dispatches work, and handles failures. |
| Lower — 7 | Workflow Task, Activity Task, Command, Event, Timer, Signal, Workflow Run ID | Execution and history details to explore after the talk. |

Use the iceberg as a bridge from the basic concepts to the hands-on transfer demos.

## 3.1: Crash the Worker between Activities

Start the Temporal Service before the talk with `./demo/start_server.sh`. It uses the persistent `demo/temporal.db` file and serves the UI at `http://localhost:8233`.

```text
demo/
├── start_server.sh                  # Start Temporal Service and UI
└── transfer/
    ├── activities.py                # Dummy withdrawal and deposit Activities
    ├── workflows.py                 # WfTransfer sequence and retry settings
    ├── worker.py                    # Registers the Workflow and Activities
    ├── starter.py                   # Starts a uniquely identified Workflow
    ├── demo_lib.sh                  # Shared process and log helpers
    ├── demo_worker_crash.sh         # Stops and restarts the Worker
    ├── demo_activity_retry.sh       # Fails deposit twice, then succeeds
    ├── demo_ui_reset.sh             # Exhausts retries and guides UI Reset
    └── README.md                    # Script instructions and timing
```

Run `./demo/transfer/demo_worker_crash.sh`. The script starts a Workflow with an 8-second pause after withdrawal, stops its Worker, waits through the timer, and starts a new Worker. The same Workflow Run should complete with deposit, reusing the recorded withdrawal result.

## 3.2: Let an Activity retry and succeed

Run `./demo/transfer/demo_activity_retry.sh`. The script creates a temporary failure marker that causes the deposit Activity to fail twice; the third attempt succeeds because `maximum_attempts=3` includes the initial attempt.

| Scope | Demo setting | What it means |
|---|---|---|
| Workflow retry | Disabled | A failed Workflow does not automatically start another Run. |
| Workflow Task timeout | 10 seconds | Temporal reschedules a Workflow Task if its Worker does not respond in time. |
| Workflow Execution timeout | 1 hour | The overall Workflow Execution has a one-hour deadline. |
| Activity retry | Maximum 3 attempts | Each Activity can run once, then retry up to two times. |
| Activity timeout | 30-second Start-To-Close | Each Activity attempt has up to 30 seconds to finish. |

Point out the three attempts in the UI and the final Activity result. The script prints the Workflow ID and clears its temporary marker and logs when it exits.

## 3.3: Fix the Activity code and Reset

Run `./demo/transfer/demo_ui_reset.sh`. It starts the Workflow with amount `"0.00"`, which triggers a marked guard in `act_deposit`. All three attempts fail, so the Workflow closes as Failed because its code does not handle the exhausted Activity failure.

The script stops its Worker and prompts you to comment out the `if request.amount == "0.00":` guard and its `raise ApplicationError` block. After you save the edit, the script restarts the Worker to load the fixed Activity code. In Temporal UI, choose Reset and select Event ID `10` (`WorkflowTaskCompleted`), after withdrawal completed and before deposit ran.

Add a reason and confirm Reset, then press Enter in the terminal. The new Run preserves the completed withdrawal and retries deposit using the updated Activity code. Show the changed Run ID and completed deposit result. Restore the guard before rehearsing this scenario again.
