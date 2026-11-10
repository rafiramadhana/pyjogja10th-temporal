from dataclasses import dataclass
from pathlib import Path

from temporalio import activity
from temporalio.exceptions import ApplicationError


@dataclass
class WithdrawalInput:
    request_id: str
    amount: str
    currency: str


@dataclass
class WithdrawalResult:
    withdrawal_id: str
    amount: str
    currency: str


@dataclass
class DepositInput:
    request_id: str
    amount: str
    currency: str
    failure_marker: str | None = None


@dataclass
class DepositResult:
    deposit_id: str
    amount: str
    currency: str
    status: str


def _should_simulate_failure(marker_path: str | None) -> bool:
    if marker_path is None:
        return False

    marker = Path(marker_path)
    try:
        remaining = marker.read_text().strip()
    except FileNotFoundError:
        return False

    if remaining == "always":
        return True

    failures_left = int(remaining)
    if failures_left <= 0:
        return False

    marker.write_text(str(failures_left - 1))
    return True


@activity.defn
async def act_withdraw(request: WithdrawalInput) -> WithdrawalResult:
    withdrawal_id = f"withdrawal-{request.request_id}"
    print(
        f"Withdrawal completed: {request.amount} {request.currency} ({withdrawal_id})",
        flush=True,
    )
    return WithdrawalResult(
        withdrawal_id=withdrawal_id,
        amount=request.amount,
        currency=request.currency,
    )


@activity.defn
async def act_deposit(request: DepositInput) -> DepositResult:
    # DEMO_FAULT_START: comment out this guard to repair the Reset scenario.
    if request.amount == "0.00":
        raise ApplicationError(
            "Simulated zero-amount deposit failure",
            type="SimulatedDepositFailure",
            non_retryable=False,
        )

    if _should_simulate_failure(request.failure_marker):
        print("Simulated retryable deposit failure", flush=True)
        raise ApplicationError(
            "Simulated deposit service failure",
            type="SimulatedDepositFailure",
            non_retryable=False,
        )

    deposit_id = f"deposit-{request.request_id}"
    print(
        f"Deposit completed: {request.amount} {request.currency} ({deposit_id})",
        flush=True,
    )
    return DepositResult(
        deposit_id=deposit_id,
        amount=request.amount,
        currency=request.currency,
        status="COMPLETED",
    )
