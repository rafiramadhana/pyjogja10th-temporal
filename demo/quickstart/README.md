# Quickstart Demo

This folder contains the Python SDK Quickstart Hello World application. It starts `SayHelloWorkflow`, which runs the `greet` Activity and returns `Hello Temporal`.

## Files

```text
quickstart/
├── activities.py  # greet Activity
├── workflows.py   # SayHelloWorkflow
├── worker.py      # Registers the Workflow and Activity
├── starter.py     # Starts the Workflow and prints its result
└── README.md      # Instructions for this demo
```

## How to run

Make sure the shared Temporal Service is running at `localhost:7233`. Open one terminal in `demo/quickstart/` and start the Worker:

```bash
source ../env/bin/activate
python worker.py
```

Open another terminal in `demo/quickstart/` and start the Workflow:

```bash
source ../env/bin/activate
python starter.py
```

The starter prints `Workflow result: Hello Temporal`. View the execution in the Temporal Web UI at <http://localhost:8233>. Press Ctrl+C in the Worker terminal when finished.
