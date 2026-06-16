#!/usr/bin/env python3
"""
specbuddy_notify.py — CLI helper for notifying the SpecBuddy IDE plugin.

Scans the fixed port range 63340-63360 to locate a running SpecBuddy server,
then POSTs a session lifecycle event to its /notify endpoint.

Usage:
  python3 specbuddy_notify.py session_start <spec_path> --mode RUN_STEP --step-name "### Step 1: ..."
  python3 specbuddy_notify.py session_end   <spec_path>
  python3 specbuddy_notify.py session_cancel <spec_path>
"""

import argparse
import json
import sys
import urllib.error
import urllib.request

PORT_RANGE = range(63340, 63361)
PING_MARKER = b"specbuddy"


def find_server() -> int | None:
    for port in PORT_RANGE:
        try:
            req = urllib.request.Request(
                f"http://localhost:{port}/ping", method="GET"
            )
            with urllib.request.urlopen(req, timeout=1) as resp:
                if PING_MARKER in resp.read():
                    return port
        except Exception:
            pass
    return None


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Notify the SpecBuddy IDE plugin about a session lifecycle event."
    )
    parser.add_argument(
        "event",
        choices=["session_start", "session_end", "session_cancel"],
        help="Lifecycle event to fire.",
    )
    parser.add_argument(
        "spec_path",
        help="Absolute path to the spec file.",
    )
    parser.add_argument(
        "--mode",
        choices=["RUN_STEP", "EXPLODE_FIX_PLAN"],
        help="Required for session_start: operation mode.",
    )
    parser.add_argument(
        "--step-name",
        metavar="STEP_NAME",
        help="Required for session_start: exact step heading text, or 'plan' / 'explode'.",
    )
    parser.add_argument(
        "--run-all",
        action="store_true",
        help="session_start only: auto-launch each subsequent step after Accept.",
    )
    args = parser.parse_args()

    if args.event == "session_start":
        if not args.mode:
            parser.error("--mode is required for session_start")
        if not args.step_name:
            parser.error("--step-name is required for session_start")

    port = find_server()
    if port is None:
        print("specbuddy_notify: SpecBuddy server not found in port range "
              f"{PORT_RANGE.start}-{PORT_RANGE.stop - 1}", file=sys.stderr)
        sys.exit(1)

    payload: dict = {"event": args.event, "spec_path": args.spec_path}
    if args.mode:
        payload["mode"] = args.mode
    if args.step_name:
        payload["step_name"] = args.step_name
    if args.run_all:
        payload["run_all"] = "true"

    data = json.dumps(payload, ensure_ascii=False).encode("utf-8")
    req = urllib.request.Request(
        f"http://localhost:{port}/notify",
        data=data,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    timeout = None if args.event == "session_start" else 5
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            body = resp.read().decode()
            if body:
                print(body)
    except urllib.error.HTTPError as e:
        print(f"specbuddy_notify: server returned {e.code}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
