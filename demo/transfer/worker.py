import asyncio
import os
import secrets

from temporalio import workflow
from temporalio.client import Client
from temporalio.worker import Worker

ADJECTIVES = ("happy", "brave", "sleepy", "clever", "swift")
ANIMALS = ("otter", "panda", "fox", "koala", "penguin")

with workflow.unsafe.imports_passed_through():
    from activities import act_deposit, act_withdraw
    from workflows import WfTransfer


async def main() -> None:
    client = await Client.connect(os.environ.get("TEMPORAL_ADDRESS", "localhost:7233"))
    task_queue = os.environ.get("TEMPORAL_TASK_QUEUE", "transfer-task-queue")
    identity = (
        f"{secrets.choice(ADJECTIVES)}-"
        f"{secrets.choice(ANIMALS)}-"
        f"{secrets.randbelow(1000):03d}"
    )
    worker = Worker(
        client,
        task_queue=task_queue,
        workflows=[WfTransfer],
        activities=[act_withdraw, act_deposit],
        identity=identity,
    )
    print(f"Transfer Worker started with identity: {identity} on {task_queue}")
    await worker.run()


if __name__ == "__main__":
    asyncio.run(main())
