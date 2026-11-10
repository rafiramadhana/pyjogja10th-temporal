import asyncio
import tempfile
import unittest
from pathlib import Path

from temporalio.exceptions import ApplicationError

from activities import (
    DepositInput,
    WithdrawalInput,
    act_deposit,
    act_withdraw,
)


class TransferActivityTests(unittest.TestCase):
    def test_withdrawal_returns_a_stable_transaction_id(self) -> None:
        request = WithdrawalInput("request-1", "10000.00", "IDR")
        first = asyncio.run(act_withdraw(request))
        repeated = asyncio.run(act_withdraw(request))

        self.assertEqual(first.withdrawal_id, repeated.withdrawal_id)

    def test_zero_amount_triggers_reset_demo_failure(self) -> None:
        with self.assertRaises(ApplicationError):
            asyncio.run(act_deposit(DepositInput("request-zero", "0.00", "IDR")))

    def test_regular_amount_deposit_succeeds_without_failure_marker(self) -> None:
        result = asyncio.run(
            act_deposit(DepositInput("request-normal", "10000.00", "IDR"))
        )

        self.assertEqual(result.status, "COMPLETED")

    def test_deposit_fails_configured_number_of_times_then_succeeds(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            marker = Path(directory) / "deposit-failures"
            marker.write_text("2")
            request = DepositInput("request-1", "10000.00", "IDR", str(marker))

            for _ in range(2):
                with self.assertRaises(ApplicationError):
                    asyncio.run(act_deposit(request))

            result = asyncio.run(act_deposit(request))

        self.assertEqual(result.status, "COMPLETED")

    def test_removing_failure_marker_repairs_exhausted_deposit(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            marker = Path(directory) / "deposit-failures"
            marker.write_text("always")
            request = DepositInput("request-2", "10000.00", "IDR", str(marker))

            with self.assertRaises(ApplicationError):
                asyncio.run(act_deposit(request))

            marker.unlink()
            result = asyncio.run(act_deposit(request))

        self.assertEqual(result.status, "COMPLETED")


if __name__ == "__main__":
    unittest.main()
