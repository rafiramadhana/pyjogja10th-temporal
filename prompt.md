# Historical planning notes

These notes preserve earlier requests and decisions. See [deck_plan.md](deck_plan.md) for the current talk plan, preparation notes, and timing.

- Remove slides.md. For now, slides construction will be managed by me manually. Just focus more to the deck_plan.md and deck.md
- For section 1, can we have 5 complexity that we need to manage? Write in table of [Complexity, Description]. Also, can have the plain code and the code with that additional complexity, but for this additional complexity can just put 3 of the 5 mentioned complexity
- For section 1, what if we have the usecase of doing withdrawal, then do a deposit action. It is more concise to show the complexity of managing states. So there will be 2 activities of act_withdraw and act_deposit
- For section 2, also include the concept of "Replay"
- Considering the concept of "just tip of the iceberg", can you write the Temporal version for that. Mention 3 concepts on upper, 5 concepts on middle part, 7 concepts on the lower levels. Write in table of [Level, Concepts, Description]
- And for section 3, what if we make it more pratical, by having 3 demos of:
  - Worker crashes
  - Retry of a process (simulate a retryable failures in one of the activities)
  - Exhausted retry which needs manual intervention from Temporal UI (simulate an oncall activity of retrying that temporal)
- For each of those scenario, let's each have a bash script to minimize human error during my demo
