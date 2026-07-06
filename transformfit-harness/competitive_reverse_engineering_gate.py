#!/usr/bin/env python3
"""Audit/complete gate for the TransformFit competitive reverse-engineering ledger."""

from __future__ import annotations

import argparse
import json
import pathlib
import sys
from typing import Any


def _load_json(path: pathlib.Path) -> dict[str, Any]:
    with path.open(encoding="utf-8") as handle:
        data = json.load(handle)
    if not isinstance(data, dict):
        raise ValueError("ledger root must be an object")
    return data


def _audit(data: dict[str, Any], require_complete: bool) -> list[str]:
    failures: list[str] = []
    if data.get("schema") != "transformfit.competitive_reverse_engineering.v1":
        failures.append("schema must be transformfit.competitive_reverse_engineering.v1")
    target = int(data.get("target_app_count", 0))
    if target != 100:
        failures.append(f"target_app_count must be 100; got {target}")
    status = str(data.get("status", ""))
    apps = data.get("apps_logged")
    if not isinstance(apps, list):
        failures.append("apps_logged must be a list")
        apps = []

    names = set()
    urls = set()
    for index, app in enumerate(apps):
        if not isinstance(app, dict):
            failures.append(f"app record {index} must be an object")
            continue
        name = str(app.get("name", "")).strip()
        url = str(app.get("source_url", "")).strip()
        mechanism = str(app.get("mechanism", "")).strip()
        if not name:
            failures.append(f"app record {index} missing name")
        if not url.startswith("http"):
            failures.append(f"app record {name or index} missing http source_url")
        if not mechanism:
            failures.append(f"app record {name or index} missing mechanism")
        if name in names:
            failures.append(f"duplicate app name: {name}")
        names.add(name)
        urls.add(url)

    macro = data.get("macrofactor_status")
    if not isinstance(macro, dict):
        failures.append("macrofactor_status must be present")
    else:
        patterns = macro.get("patterns_observed")
        missing = macro.get("missing_for_complete_reverse_engineering")
        if not isinstance(patterns, list) or len(patterns) < 6:
            failures.append("macrofactor_status must include at least six observed patterns")
        if not isinstance(missing, list) or not missing:
            failures.append("macrofactor_status must state what is missing")
        if "partial" not in str(macro.get("status", "")).lower():
            failures.append("macrofactor_status must honestly mark current work as partial")

    honest = str(data.get("honest_statement", "")).lower()
    if "not complete" not in honest and "not_complete" not in status:
        failures.append("ledger must honestly state that 100-app reverse engineering is not complete")

    if require_complete:
        if len(apps) < target:
            failures.append(f"complete mode requires >=100 app records; got {len(apps)}")
        screen_evidence = [
            app
            for app in apps
            if str(app.get("evidence_level", "")).lower()
            in {"screenshot_packet", "screen_state_capture", "first_party_capture"}
        ]
        if len(screen_evidence) < 20:
            failures.append(f"complete mode requires >=20 screen-state records; got {len(screen_evidence)}")
        if "complete" not in status:
            failures.append("complete mode requires status to include complete")
    return failures


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate competitive reverse-engineering ledger")
    parser.add_argument("ledger", type=pathlib.Path)
    parser.add_argument("--require-complete", action="store_true")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    try:
        data = _load_json(args.ledger)
        failures = _audit(data, args.require_complete)
    except Exception as exc:  # noqa: BLE001 - fail closed with useful message.
        data = {}
        failures = [str(exc)]

    result = {
        "schema": "transformfit.competitive_reverse_engineering_gate.v1",
        "ledger": str(args.ledger),
        "mode": "complete" if args.require_complete else "audit",
        "target_app_count": data.get("target_app_count"),
        "apps_logged": len(data.get("apps_logged", [])) if isinstance(data.get("apps_logged"), list) else 0,
        "verdict": "GREEN" if not failures else "RED",
        "failures": failures,
    }
    if args.json:
        print(json.dumps(result, indent=2, sort_keys=True))
    else:
        print(f"{result['verdict']} competitive_reverse_engineering_gate: {args.ledger}")
        for failure in failures:
            print(f"  - {failure}")
    return 0 if not failures else 1


if __name__ == "__main__":
    sys.exit(main())
