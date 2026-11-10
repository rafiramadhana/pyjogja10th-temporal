import argparse
import asyncio
import os
from datetime import timedelta

import ulid
from temporalio.client import Client, WorkflowFailureError

from workflows import TransferInput, WfTransfer


async def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--pause-seconds",
        type=int,
        default=0,
        help="Wait between withdrawal and deposit for the Worker recovery demo",
    )
    parser.add_argument(
        "--failure-marker",
        help="Temporary file controlling simulated retryable deposit failures",
    )
    parser.add_argument(
        "--amount",
        default="10000.00",
        help="Dummy transaction amount, kept as a decimal string",
    )
    args = parser.parse_args()
    if args.pause_seconds < 0:
        parser.error("--pause-seconds must be zero or greater")

    request_id = str(ulid.new())
    workflow_id = f"Transfer-{request_id}"
    client = await Client.connect(os.environ.get("TEMPORAL_ADDRESS", "localhost:7233"))
    handle = await client.start_workflow(
        WfTransfer.run,
        TransferInput(
            request_id=request_id,
            amount=args.amount,
            currency="IDR",
            pause_seconds=args.pause_seconds,
            failure_marker=args.failure_marker,
        ),
        id=workflow_id,
        task_queue=os.environ.get("TEMPORAL_TASK_QUEUE", "transfer-task-queue"),
        task_timeout=timedelta(seconds=10),
        run_timeout=None,
        execution_timeout=timedelta(hours=1),
        retry_policy=None,
    )
    print(f"Workflow ID: {handle.id}", flush=True)
    try:
        result = await handle.result()
    except WorkflowFailureError as error:
        print(f"Workflow failed: {error}")
        return 1
    print(f"Withdrawal ID: {result.withdrawal_id}")
    print(f"Deposit ID: {result.deposit_id}")
    print(f"Amount: {result.amount} {result.currency}")
    print(f"Status: {result.status}")
    return 0


if __name__ == "__main__":
    raise SystemExit(asyncio.run(main()))
