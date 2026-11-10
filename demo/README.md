# Temporal Python Demos

This folder contains the Python SDK Quickstart and the withdrawal/deposit demo used in the talk. Both use the shared Python environment and local Temporal development service.

## Files

```text
demo/
├── start_server.sh       # Start or check the local Temporal Service and UI
├── quickstart/           # Python SDK Quickstart example
├── transfer/             # Talk demo and three recovery scripts
├── retry-and-timeout.md   # Python and Go retry/timeout reference
├── requirements.txt       # Shared Python dependencies
├── temporal.db            # Persistent local Temporal state
└── env/                   # Shared Python virtual environment
```

See [Quickstart](quickstart/README.md) or [Transfer demo](transfer/README.md) for instructions. The transfer README documents every script in that subfolder, including presenter actions and estimated time. The [retry and timeout reference](retry-and-timeout.md) lists the exact demo settings.

## Start the local Temporal Service

From the project root, run:

```bash
./demo/start_server.sh
```

The script checks whether Temporal is reachable at `localhost:7233`. If it is, the script reports that and exits. Otherwise, it starts the development service in the foreground with persistent state in `demo/temporal.db`; press Ctrl+C in that terminal to stop it. The UI is at <http://localhost:8233>.

The script also accepts `TEMPORAL_DB_FILE`, `TEMPORAL_PORT`, `TEMPORAL_UI_PORT`, and `TEMPORAL_METRICS_PORT` for an alternate local server configuration. For example, use a temporary database and alternate ports when testing startup:

```bash
test_server_dir="$(mktemp -d)"
TEMPORAL_DB_FILE="$test_server_dir/temporal.db" \
TEMPORAL_PORT=17233 \
TEMPORAL_UI_PORT=18233 \
TEMPORAL_ADDRESS=localhost:17233 \
./demo/start_server.sh
```

Stop the test server with Ctrl+C, then remove its temporary directory with `rm -r "$test_server_dir"`. The script itself does not delete the database file.

## Shared Python setup

The existing `env/` is the shared Python virtual environment. On a fresh clone, create it only if it is missing, then activate it from `demo/` and install dependencies:

```bash
if [ ! -d env ]; then python3 -m venv env; fi
source env/bin/activate
python -m pip install -r requirements.txt
```

Install the Temporal CLI by following the [official Python SDK Quickstart](https://docs.temporal.io/develop/python/set-up-your-local-python#install-temporal-cli). The [local Quickstart copy](../docs-temporal/develop/python_sdk/quickstart.md#install-temporal-cli) is also available when `docs-temporal/` is present.
