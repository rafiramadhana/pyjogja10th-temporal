# When Python Jobs Fail: Moving from Retries to Durable Execution

Introduce Temporal to Python developers by starting with a two-step withdrawal and deposit process, explaining how Temporal preserves progress, and demonstrating recovery locally.

## Background

The audience is Python developers who are new to Temporal. The examples use dummy transactions of `"10000.00"` IDR and focus on making the Activities succeed, retrying failures, and recovering the Workflow.

The talk is 25 minutes, followed by 5 minutes for Q&A. The three demos use scripts to reduce setup and timing errors. Start the server before the talk so the 25-minute slot stays focused on the demo scenarios.

## Talk timing

| Part | Time |
|---|---:|
| The failure problem | 6 minutes |
| The Temporal approach and iceberg overview | 6 minutes |
| Worker crash and recovery demo | 4 minutes |
| Automatic Activity retry demo | 3 minutes |
| Exhausted retries and UI Reset demo | 6 minutes |
| Q&A | 5 minutes |

## Outlines

```text
Outlines/
├─ The failure problem/
│  ├─ A withdrawal succeeds before a deposit fails
│  ├─ Simple code becomes recovery code
│  └─ Five complexities teams must manage
├─ The Temporal approach/
│  ├─ Core Temporal concepts
│  ├─ Concepts in the Python Quickstart
│  └─ Durable Workflows and Replay
└─ Hands-on recovery/
   ├─ A Worker crashes between Activities
   ├─ An Activity retry succeeds
   └─ Retries exhaust, then an operator uses Reset
```

### Section Details

| Section | Subsection | Description |
|---|---|---|
| The failure problem | A withdrawal succeeds before a deposit fails | Introduce the two-step dummy transaction and the risk of stopping between steps. |
|  | Simple code becomes recovery code | Compare the direct sequence with a version that must track retries and completed work. |
|  | Five complexities teams must manage | Name the work required to make retries and recovery safe and observable. |
| The Temporal approach | Core Temporal concepts | Explain Workflow, Activity, Worker, Event History, and Replay in a `[Concept, What, Why]` table. |
|  | Concepts in the Python Quickstart | Show how `SayHelloWorkflow`, `greet`, the Worker, and starter map to those concepts. |
|  | Durable Workflows and Replay | Explain how Event History lets another Worker rebuild Workflow state and reuse the recorded Activity result. Use an iceberg overview to bridge into the transfer demos. |
| Hands-on recovery | A Worker crashes between Activities | Stop and restart the Worker while the Workflow waits on a timer. |
|  | An Activity retry succeeds | Simulate two retryable deposit failures and succeed on attempt three. |
|  | Retries exhaust, then an operator uses Reset | Comment out the amount-based Activity failure, restart the Worker, Reset through Temporal UI, and observe a new Run continue from preserved withdrawal progress. |

## Preparation

### The failure problem

**Action Items**
- Prepare direct Python code for `act_withdraw` followed by `act_deposit`.
- Prepare an expanded example with retries, timeouts, and duplicate-safe request identifiers; explain durable saved progress conceptually.
- Show a five-row table of recovery complexities and their meaning.

**Key Takeaways**
- A process can fail after one step has already succeeded.
- Retrying a function does not track the whole process automatically.
- Recovery logic adds application work around progress, retry rules, and visibility.

### The Temporal approach

**Action Items**
- Introduce Workflow, Activity, Worker, Event History, and Replay in the concepts table.
- Walk through the Quickstart `SayHelloWorkflow`, `greet`, Worker registration, and starter code.
- Show how Replay rebuilds Workflow state and reuses the recorded greeting result after a Worker failure.
- Use the 3/5/7 iceberg table as a brief invitation to explore more Temporal concepts.

**Key Takeaways**
- Workflows coordinate durable business logic, Activities perform work, and Workers run their code.
- Event History records progress and completed Activity results.
- Replay restores Workflow state; it does not retry a completed Activity.

### Hands-on recovery

**Action Items**
- Before the talk, start the local service with `demo/start_server.sh` and open Temporal UI at `http://localhost:8233`.
- Rehearse `demo_worker_crash.sh` (about 4 minutes including explanation), which waits 8 seconds between Activities and restarts a Worker.
- Rehearse `demo_activity_retry.sh` (about 3 minutes), which fails deposit twice and succeeds on its third attempt.
- Rehearse `demo_ui_reset.sh` (about 6 minutes), including the `"0.00"` failure, commenting out its guard, restarting the Worker, selecting the UI Reset point, and showing the changed Run ID and preserved withdrawal. Restore the guard before repeating the rehearsal.
- Use the UI to show Workflow identity/status, Activity progression, and object inputs/results.

**Key Takeaways**
- A Worker crash can recover in the same Workflow Run.
- Activity retries are separate attempts with a configured maximum of three total attempts.
- Reset creates a new Run from a chosen point while preserving earlier Workflow progress.
