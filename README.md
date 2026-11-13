# PyJogja 10th: Durable Execution with Temporal

[Google Slides](https://docs.google.com/presentation/d/1Fy9t_RGluFqHhAerZJHrRPW4GBOuvcoe3m5b52Tw0uo/edit?usp=sharing)

## Background

This talk introduces Temporal to Python developers through a withdrawal and deposit example. It starts with the recovery problems that arise when a process fails between steps, then demonstrates how Temporal records progress and supports recovery.

- Workflows coordinate durable processes, while Activities perform external work.
- Event History and Replay let a Workflow recover after a Worker crash.
- Activity retries and Workflow Reset demonstrate different ways to handle failures.

## Repository map

```text
pyjogja10th-temporal/
├── AGENTS.md                # Agent instructions and Temporal documentation lookup order
├── README.md                # Talk overview and repository map
├── deck_plan.md             # Talk outline, preparation, and timing
├── deck.md                  # Article-like rehearsal material
├── demo/
│   ├── README.md            # Demo setup and run instructions
│   ├── quickstart/          # Python SDK Hello World example
│   ├── transfer/            # Withdrawal/deposit recovery demos
│   ├── start_server.sh      # Start the local Temporal Service
│   ├── requirements.txt     # Shared Python dependencies
│   ├── retry-and-timeout.md # Python and Go configuration reference
│   ├── env/                 # Local Python virtual environment
│   └── temporal.db          # Local Temporal persistence
└── docs-temporal/
    ├── README.md            # Local documentation map
    ├── develop/             # SDK development guides
    ├── encyclopedia/        # Temporal concepts and architecture
    └── evaluate/            # Benefits, features, and use cases
```

`docs-temporal/` is an optional local reference and is excluded from Git. If it is absent, use the [official Temporal documentation](https://docs.temporal.io/).
