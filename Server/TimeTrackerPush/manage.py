"""Server-local account bootstrap; prints a single-use pairing code once."""

import os
import sys
from pathlib import Path

from event_store import EventStore


def main() -> None:
    if len(sys.argv) != 2 or sys.argv[1] != "create-account":
        raise SystemExit("usage: python manage.py create-account")
    home = Path(os.environ["TT_PUSH_HOME"]).resolve()
    store = EventStore(home / "data")
    try:
        account, code = store.create_account()
        print(f"account={account}\npairing_code={code}\nexpires_in=600_seconds")
    finally:
        store.close()


if __name__ == "__main__":
    main()
