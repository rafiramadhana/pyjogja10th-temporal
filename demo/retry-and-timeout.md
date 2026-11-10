# Temporal Retry and Timeout Reference

This reference shows how to configure Workflow retries, Workflow timeouts, Activity retries, and Activity timeouts in the Python and Go SDKs. The code samples are configuration examples; the exact transfer demo configuration is listed afterward.

## Configuration examples

| SDK | Topic | Code |
|---|---|---|
| Python | Workflow retry | `from datetime import timedelta`<br>`from temporalio.common import RetryPolicy`<br>`retry_policy=RetryPolicy(initial_interval=timedelta(seconds=1), backoff_coefficient=2.0, maximum_interval=timedelta(seconds=10), maximum_attempts=3)` |
| Python | Workflow timeout | `from datetime import timedelta`<br>`task_timeout=timedelta(seconds=10)`<br>`run_timeout=timedelta(minutes=10)`<br>`execution_timeout=timedelta(hours=1)` |
| Python | Activity retry | `from datetime import timedelta`<br>`from temporalio.common import RetryPolicy`<br>`retry_policy=RetryPolicy(initial_interval=timedelta(seconds=1), backoff_coefficient=2.0, maximum_interval=timedelta(seconds=10), maximum_attempts=3)` |
| Python | Activity timeout | `from datetime import timedelta`<br>`start_to_close_timeout=timedelta(seconds=30)`<br>`schedule_to_close_timeout=timedelta(minutes=2)` |
| Go | Workflow retry | `RetryPolicy: &temporal.RetryPolicy{InitialInterval: time.Second, BackoffCoefficient: 2.0, MaximumInterval: 10 * time.Second, MaximumAttempts: 3}` |
| Go | Workflow timeout | `WorkflowTaskTimeout: 10 * time.Second`<br>`WorkflowRunTimeout: 10 * time.Minute`<br>`WorkflowExecutionTimeout: time.Hour` |
| Go | Activity retry | `RetryPolicy: &temporal.RetryPolicy{InitialInterval: time.Second, BackoffCoefficient: 2.0, MaximumInterval: 10 * time.Second, MaximumAttempts: 3}` |
| Go | Activity timeout | `StartToCloseTimeout: 30 * time.Second`<br>`ScheduleToCloseTimeout: 2 * time.Minute` |

Python examples use `datetime.timedelta` and `temporalio.common.RetryPolicy`. Go examples use `time` and `go.temporal.io/sdk/temporal`; Workflow timeout fields belong to `client.StartWorkflowOptions`, while Activity settings belong to `workflow.ActivityOptions`.

## Retry Policy type and scope

Each SDK uses the same Retry Policy type for Workflows and Activities: Python uses `temporalio.common.RetryPolicy`, and Go uses `temporal.RetryPolicy`. The type describes retry behavior, but each policy is attached separately at the scope it should control.

| SDK | Workflow policy location | Activity policy location |
|---|---|---|
| Python | `retry_policy` argument to `Client.start_workflow()` or `Client.execute_workflow()` | `retry_policy` argument to `workflow.execute_activity()` |
| Go | `RetryPolicy` field in `client.StartWorkflowOptions` | `RetryPolicy` field in `workflow.ActivityOptions`, applied with `workflow.WithActivityOptions()` |

Workflow and Activity timeouts follow the same scope split: Workflow timeouts are set when starting the Workflow, while Activity timeouts are set with the Activity options. Workflow executions have no retry policy by default; Activities use a default retry policy unless one is supplied. The default Activity policy starts with a 1-second delay, doubles the delay up to 100 seconds, and allows unlimited attempts.

## Starting a Workflow and waiting for its result

Python's `start_workflow()` returns a handle after Temporal accepts the start request. `handle.result()` waits for completion, while `execute_workflow()` combines starting and waiting and returns the result directly.

| Intent | Python | Go |
|---|---|---|
| Start and get a handle | `handle = await client.start_workflow(...)` | `run, err := client.ExecuteWorkflow(ctx, options, WfTransfer, input)` |
| Wait for the result | `result = await handle.result()` | `err := run.Get(ctx, &result)` |
| Start and wait in one call | `result = await client.execute_workflow(...)` | Call `ExecuteWorkflow(...)`, then `run.Get(ctx, &result)` |

Despite its name, Go's `ExecuteWorkflow()` starts the Workflow and returns a `WorkflowRun`; it does not wait for the final result. The later `Get()` call waits, similar to Python's `handle.result()`. Python's `execute_workflow()` is the method that combines both steps.

## What each setting limits

| Setting | What it limits |
|---|---|
| Workflow Retry Policy | Whether a failed Workflow Run starts another Run. Workflows have no retry policy by default. |
| Workflow Task Timeout | How long a Worker may execute one Workflow Task before Temporal times it out and schedules the task again. The default is 10 seconds. |
| Workflow Run Timeout | How long one Workflow Run may remain open. If unset, it follows the Workflow Execution Timeout. |
| Workflow Execution Timeout | How long the overall Workflow Execution may remain open, including Workflow retries and Continue-As-New. If unset, it is unlimited. |
| Activity Start-To-Close Timeout | How long one Activity attempt may run after a Worker starts it. |
| Activity Schedule-To-Close Timeout | The total time allowed for an Activity Execution, including queueing, attempts, and retry delays. |
| Activity Retry Policy | Which Activity failures are retried, how long to wait between attempts, and when to stop. |

An Activity needs a Start-To-Close or Schedule-To-Close timeout. Setting both gives each attempt a limit and gives the entire Activity Execution a total deadline. The number of maximum attempts includes the initial attempt; `maximum_attempts=3` allows one initial attempt and up to two retries.

## Workflow Task failures and Workflow failures

A Workflow Task is a short piece of orchestration work. If a Worker crashes while processing one, or cannot process the task, Temporal retries that Workflow Task in the same Run; this is separate from a Workflow Retry Policy.

| Situation | Temporal behavior | Workflow outcome |
|---|---|---|
| Worker crashes during a Workflow Task | The task times out and Temporal schedules it again. | The Workflow Execution stays open in the same Run. |
| Worker receives an unregistered Workflow type | The Worker reports that it cannot handle the Workflow Task, so Temporal retries the task. | The Workflow stays open while compatible code is unavailable, unless an overall timeout or external action closes it. |
| Worker crashes during an Activity attempt | A configured Activity timeout detects the lost attempt; the Activity Retry Policy determines whether another attempt starts. | The Workflow stays open while the Activity is pending or retrying. |
| Worker receives an unregistered Activity type | The Activity attempt fails on a Worker without that implementation; the Activity Retry Policy controls further attempts. | If the Activity ultimately fails and Workflow code does not catch the error, the Workflow Run fails. |
| Workflow code raises Python `ApplicationError` | The SDK reports a Workflow Execution failure. | The Workflow Run becomes Failed. A Workflow Retry Policy can start another Run. |
| Workflow code raises an ordinary Python exception | By default, the Workflow Task fails and Temporal retries it. | The Workflow usually remains open while the code issue persists. Python failure configuration can change this behavior. |
| A configured Workflow Run or Execution deadline expires | Temporal closes the execution because its time limit elapsed. | The status is Timed Out, not Failed. |
| A cancellation request is accepted or an operator terminates the execution | Temporal closes the execution according to that action. | The status is Canceled or Terminated, respectively. |

An Activity failure is one possible cause of a Workflow failure, not the only cause. In the transfer demo, an Activity failure that escapes the Workflow is the main application failure path; the Workflow has no Retry Policy, but its 1-hour Execution Timeout can close it as Timed Out.

## Activity heartbeats

Heartbeats belong to Activity execution. The Workflow sets a Heartbeat Timeout in that Activity's options, Activity code explicitly reports progress through the Worker SDK, and the SDK sends those heartbeats to the Temporal Service; the Service does not poll the Worker.

| SDK | Set the timeout when scheduling the Activity | Send a heartbeat inside Activity code |
|---|---|---|
| Python | `heartbeat_timeout=timedelta(seconds=15)` in `workflow.execute_activity()` | `activity.heartbeat(details)` |
| Go | `HeartbeatTimeout: 15 * time.Second` in `workflow.ActivityOptions` | `activity.RecordHeartbeat(ctx, details)` |

Python Activity implementation:

```python
import asyncio
from temporalio import activity

@activity.defn
async def act_process_records(count: int) -> int:
    for index in range(count):
        # Report progress through the Worker SDK.
        activity.heartbeat(index)
        await asyncio.sleep(5)
    return count
```

Python Workflow configuration:

```python
from datetime import timedelta
from temporalio import workflow

with workflow.unsafe.imports_passed_through():
    from activities import act_process_records

@workflow.defn
class WfProcessRecords:
    @workflow.run
    async def run(self, count: int) -> int:
        return await workflow.execute_activity(
            act_process_records,
            count,
            start_to_close_timeout=timedelta(minutes=10),
            heartbeat_timeout=timedelta(seconds=15),
        )
```

Go example:

```go
import (
    "context"
    "time"

    "go.temporal.io/sdk/activity"
    "go.temporal.io/sdk/workflow"
)

func ActProcessRecords(ctx context.Context, count int) error {
    for index := 0; index < count; index++ {
        // Process the record, then report progress through the Worker SDK.
        activity.RecordHeartbeat(ctx, index)
    }
    return nil
}

func WfProcessRecords(ctx workflow.Context, count int) error {
    options := workflow.ActivityOptions{
        StartToCloseTimeout: 10 * time.Minute,
        HeartbeatTimeout:    15 * time.Second,
    }
    ctx = workflow.WithActivityOptions(ctx, options)
    return workflow.ExecuteActivity(ctx, ActProcessRecords, count).Get(ctx, nil)
}
```

If the Service receives no heartbeat within the configured interval, it times out that Activity attempt and may schedule another attempt according to the Activity Retry Policy. The Worker SDK can throttle heartbeat requests, so every heartbeat call does not necessarily become a separate network request.

Heartbeat details can preserve a progress marker for a retry. The Activity must read those details and use them to resume; otherwise a retry starts the Activity code again from its beginning. Heartbeats are useful for long-running Activities and are not needed for ordinary Workflow Task recovery.

## Transfer demo configuration

The transfer demo uses the following settings:

| Scope | Setting |
|---|---|
| Workflow retry | `None`; a terminal Workflow failure does not automatically start a new Run. |
| Workflow Task timeout | 10 seconds, set in `demo/transfer/starter.py`. |
| Workflow Run timeout | Unset. |
| Workflow Execution timeout | 1 hour from start, including timers and time waiting for a Worker. |
| Activity retry | `RetryPolicy(maximum_attempts=3)` for `act_withdraw` and `act_deposit`: one initial attempt plus up to two retries, with Temporal's default 1-second initial delay and exponential backoff. |
| Activity Start-To-Close timeout | 30 seconds per attempt. |
| Activity Schedule-To-Close timeout | Unset; retries have no overall Activity deadline. |

The explicit three-attempt Activity policy applies to `act_withdraw` and `act_deposit`. A Worker restart during the Workflow's durable pause does not invoke the Activity retry policy: the Workflow stays in the same Run, replays its recorded withdrawal result, and continues to deposit. If deposit exhausts its retries, the uncaught failure closes the Workflow Run as Failed. The demo leaves Workflow retries disabled so the operator can repair the mock service and use Workflow Reset from Temporal UI.

The transfer demo does not configure or send Activity heartbeats.

For detailed SDK guidance, see Temporal's [Python Workflow timeouts and retries](https://docs.temporal.io/develop/python/workflows/timeouts), [Python Activity timeouts, retries, and heartbeats](https://docs.temporal.io/develop/python/activities/timeouts), [Go Workflow timeouts and retries](https://docs.temporal.io/develop/go/workflows/timeouts), [Go Activity timeouts, retries, and heartbeats](https://docs.temporal.io/develop/go/activities/timeouts), [Workflow Task failure behavior](https://docs.temporal.io/tasks#workflow-task-failures-vs-workflow-execution-failures), and [Retry Policy defaults](https://docs.temporal.io/encyclopedia/retry-policies).
