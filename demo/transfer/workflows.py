from dataclasses import dataclass
from datetime import timedelta

from temporalio import workflow
from temporalio.common import RetryPolicy

with workflow.unsafe.imports_passed_through():
    from activities import (
        DepositInput,
        DepositResult,
        WithdrawalInput,
        WithdrawalResult,
        act_deposit,
        act_withdraw,
    )


@dataclass
class TransferInput:
    request_id: str
    amount: str = "10000.00"
    currency: str = "IDR"
    pause_seconds: int = 0
    failure_marker: str | None = None


@dataclass
class TransferResult:
    withdrawal_id: str
    deposit_id: str
    amount: str
    currency: str
    status: str


@workflow.defn
class WfTransfer:
    @workflow.run
    async def run(self, transfer: TransferInput) -> TransferResult:
        withdrawal: WithdrawalResult = await workflow.execute_activity(
            act_withdraw,
            WithdrawalInput(
                request_id=transfer.request_id,
                amount=transfer.amount,
                currency=transfer.currency,
            ),
            start_to_close_timeout=timedelta(seconds=30),
            retry_policy=RetryPolicy(maximum_attempts=3),
        )

        if transfer.pause_seconds > 0:
            await workflow.sleep(transfer.pause_seconds)

        deposit: DepositResult = await workflow.execute_activity(
            act_deposit,
            DepositInput(
                request_id=transfer.request_id,
                amount=transfer.amount,
                currency=transfer.currency,
                failure_marker=transfer.failure_marker,
            ),
            start_to_close_timeout=timedelta(seconds=30),
            retry_policy=RetryPolicy(maximum_attempts=3),
        )

        return TransferResult(
            withdrawal_id=withdrawal.withdrawal_id,
            deposit_id=deposit.deposit_id,
            amount=deposit.amount,
            currency=deposit.currency,
            status=deposit.status,
        )
