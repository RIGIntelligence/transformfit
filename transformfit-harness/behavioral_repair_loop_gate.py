#!/usr/bin/env python3
"""Fail-closed gate for TransformFit's behavioral repair loop."""

from __future__ import annotations

import argparse
import json
import pathlib
import sys
from typing import Iterable


REQUIRED_MODEL_TOKENS = {
    "behavioralRepairSourceIds",
    "enum BehavioralRepairMode",
    "class BehavioralRepairLoop",
    "buildBehavioralRepairLoop",
    "behavioralRepairCopyIsGateSafe",
    "Day-zero activation",
    "Checked-in comeback",
    "Recovery kept promise",
    "Pain safety repair",
    "Missed-day comeback",
    "Live-session closure",
    "Nutrition bridge",
    "Proof recommitment",
    "Belong before performance",
    "Do not add missed volume back into today",
}

REQUIRED_PROVIDER_TOKENS = {
    "behavioralRepairLoopProvider",
    "buildBehavioralRepairLoop",
}

REQUIRED_TODAY_TOKENS = {
    "BehavioralRepairLoop",
    "_BehaviorRepairPanel",
    "Behavior repair",
    "Next repair",
    "Proof",
    "Boundary",
}

REQUIRED_COMMAND_TOKENS = {
    "lane-behavior-repair",
    "Behavior repair",
    "_BehaviorRepairPanel",
    "Next repair",
}

REQUIRED_TEST_TOKENS = {
    "empty state routes to day-zero activation",
    "stale first check-in routes to comeback reset",
    "low readiness routes to recovery kept promise",
    "reported pain routes to pain safety repair",
    "missed day routes to comeback without catch-up volume",
    "Make starting feel safe",
    "Save the day without pretending",
    "Day-zero activation",
}

REQUIRED_SHIP_TOKENS = {
    "BEHAVIORAL_REPAIR_LOOP_GATE",
    "behavioral_repair_loop_gate",
    "Tier-1 15/27: behavioral_repair_loop_gate",
}

APP_BANNED_TERMS = {
    "beast mode",
    "burn fat",
    "diagnose",
    "guilt",
    "lazy",
    "no excuses",
    "punish",
    "shame",
    "weight loss",
}


def _read(path: pathlib.Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except FileNotFoundError:
        return ""


def _missing(text: str, tokens: Iterable[str]) -> list[str]:
    return [token for token in tokens if token not in text]


def run(repo_root: pathlib.Path) -> dict[str, object]:
    failures: list[str] = []
    paths = {
        "model": repo_root / "lib/features/behavior/behavioral_repair_loop.dart",
        "providers": repo_root / "lib/app_providers.dart",
        "today": repo_root / "lib/screens/today_screen.dart",
        "command_model": repo_root / "lib/features/coaching/coach_command_center.dart",
        "command_screen": repo_root / "lib/features/coaching/coach_command_screen.dart",
        "model_tests": repo_root / "test/features/behavior/behavioral_repair_loop_test.dart",
        "today_tests": repo_root / "test/today_screen_test.dart",
        "command_tests": repo_root / "test/features/coaching/coach_command_screen_test.dart",
        "center_tests": repo_root / "test/features/coaching/coach_command_center_test.dart",
        "ship_gate": repo_root / "transformfit-harness/ship_gate.sh",
        "bridge": repo_root / "transformfit-harness/bridge.json",
        "war_room": repo_root / "transformfit-harness/two_day_war_room.json",
        "war_room_gate": repo_root / "transformfit-harness/two_day_war_room_gate.py",
    }
    text = {name: _read(path) for name, path in paths.items()}

    for name, body in text.items():
        if not body:
            failures.append(f"missing required file: {paths[name]}")

    for token in _missing(text["model"], REQUIRED_MODEL_TOKENS):
        failures.append(f"behavioral_repair_loop.dart missing token: {token}")
    for token in _missing(text["providers"], REQUIRED_PROVIDER_TOKENS):
        failures.append(f"app_providers.dart missing token: {token}")
    for token in _missing(text["today"], REQUIRED_TODAY_TOKENS):
        failures.append(f"today_screen.dart missing behavior repair token: {token}")

    command_text = "\n".join([text["command_model"], text["command_screen"]])
    for token in _missing(command_text, REQUIRED_COMMAND_TOKENS):
        failures.append(f"coach command surface missing behavior repair token: {token}")

    tests_text = "\n".join(
        [
            text["model_tests"],
            text["today_tests"],
            text["command_tests"],
            text["center_tests"],
        ]
    )
    for token in _missing(tests_text, REQUIRED_TEST_TOKENS):
        failures.append(f"behavioral repair tests missing token: {token}")

    for token in _missing(text["ship_gate"], REQUIRED_SHIP_TOKENS):
        failures.append(f"ship_gate.sh missing behavioral repair gate token: {token}")
    if "behavioral_repair_loop_gate" not in text["bridge"]:
        failures.append("bridge.json missing behavioral_repair_loop_gate routing")
    if '"behavioral_repair_loop"' not in text["bridge"]:
        failures.append("bridge.json missing behavioral_repair_loop artifact type")
    if "behavioral_repair_loop_gate" not in text["war_room"]:
        failures.append("two_day_war_room.json missing behavioral_repair_loop_gate")
    if "kpi-behavioral-repair-loop" not in text["war_room"]:
        failures.append("two_day_war_room.json missing behavioral repair KPI")
    if '"behavioral_repair_flows"' not in text["war_room"]:
        failures.append("two_day_war_room.json missing behavioral repair lane")
    if '"behavioral_repair_loop_gate"' not in text["war_room_gate"]:
        failures.append("two_day_war_room_gate.py missing behavioral_repair_loop_gate")
    if '"kpi-behavioral-repair-loop"' not in text["war_room_gate"]:
        failures.append("two_day_war_room_gate.py missing behavioral repair KPI")

    visible_app_text = "\n".join([text["today"], text["command_screen"]]).lower()
    for banned in sorted(APP_BANNED_TERMS):
        if banned in visible_app_text:
            failures.append(f"visible behavioral repair surface contains banned term: {banned}")

    return {
        "schema": "transformfit.behavioral_repair_loop_gate.v1",
        "repo_root": str(repo_root),
        "verdict": "GREEN" if not failures else "RED",
        "failures": failures,
    }


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--repo-root",
        type=pathlib.Path,
        default=pathlib.Path("."),
        help="TransformFit Flutter repo root",
    )
    args = parser.parse_args(argv)

    result = run(args.repo_root.resolve())
    print(json.dumps(result, indent=2, sort_keys=True))
    return 0 if result["verdict"] == "GREEN" else 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
