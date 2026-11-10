# Temporal documentation lookup

- Check `docs-temporal/` first for information relevant to the task.
- For Python SDK setup and a getting-started example, check `docs-temporal/develop/python_sdk/quickstart.md`.
- If the local documents do not contain enough information to answer, consult the official Temporal documentation at <https://docs.temporal.io/>.
- Preserve `demo/env/` and `demo/temporal.db` when working on the demo, since they hold its Python environment and local Temporal state.

# Talk materials

- `deck_plan.md` contains the talk's purpose, background, outline, preparation notes, and demo timing.
- `deck.md` is concise, article-like rehearsal material with one heading per planned slide. Keep section planning and preparation notes in `deck_plan.md`.
- Slides construction is managed manually by the user. Do not create or update `slides.md`.
- In `deck.md`, use concise sentences and keep each paragraph to 1–3 sentences. Lists, tables, and simple text trees are allowed when they help explain the material.
- Supporting media in `deck.md` may include Mermaid flowcharts, Mermaid sequence diagrams, and Python code snippets. Do not use images, other Mermaid diagram types, or pseudocode.
- Use Mermaid's `autonumber` directive in sequence diagrams in `deck.md`.
- Do not use semicolons (`;`) in Mermaid diagrams because they can break rendering.
- Keep the transfer example aligned across `deck.md` and `demo/transfer/`: `act_withdraw` runs before `act_deposit`, and recovery behavior matches the executable demo.
- Structure Section 2 from Temporal concepts to Quickstart code to durable Workflow recovery with Replay. Use `demo/quickstart/` naming and keep the transfer implementation for Section 3.
- Keep retry and timeout values aligned across `deck.md`, demo READMEs, `demo/retry-and-timeout.md`, and the transfer demo code.
- Document every `.sh` file in the README nearest to it, including its purpose, how to run it, expected behavior, and cleanup.

# Demo conventions

- Keep each demo's application code in `activities.py`, `workflows.py`, `worker.py`, and `starter.py`. Supporting READMEs and validation files may sit alongside these modules.
- In the transfer demo, name Workflow classes `Wf<WorkflowName>` and Activity functions `act_<activity_name>`.
- Keep `demo/quickstart/` aligned with Temporal's Python Quickstart naming and structure.
- Use `demo/retry-and-timeout.md` as the reference for Python and Go retry and timeout configuration and for the transfer demo's exact settings.
- The transfer demo uses dummy transactions only. Its Activities use a maximum of 3 attempts, and Workflow retries are disabled.
