#!/usr/bin/env python3
"""Fail-closed gate for TransformFit's v25 coach command center."""

from __future__ import annotations

import argparse
import json
import pathlib
import sys
from typing import Iterable


REQUIRED_MODEL_TOKENS = {
    "coachCommandCenterSourceIds",
    "class CoachCommandCenter",
    "class CoachCommandLane",
    "buildCoachCommandCenter",
    "DateTime? now",
    "buildBehavioralRepairLoop(state, now: now)",
    "coachCommandCenterCopyIsGateSafe",
    "lane-dai-command",
    "lane-wearable-readiness",
    "lane-readiness-entry",
    "lane-training-ledger",
    "lane-nutrition",
    "lane-safety",
    "Coach handoff:",
    "next24Hours",
    "sourceTraceLabel",
}

REQUIRED_SCREEN_TOKENS = {
    "class CoachCommandScreen",
    "class _CoachPanelHeader",
    "required this.icon",
    "required this.label",
    "required this.headline",
    "this.trailing",
    "this.prominent",
    "Coach command",
    "Daily command",
    "Coach handoff",
    "Next 24 hours",
    "TransformFitAI coach logo",
    "Open live workout logger",
    "Open composition trust",
}

REQUIRED_LANE_LABEL_TOKENS = {
    "DAI command",
    "Wearable readiness",
    "Training ledger",
    "Nutrition",
    "Safety",
}

REQUIRED_PROVIDER_TOKENS = {
    "coachCommandCenterProvider",
    "buildCoachCommandCenter",
}

REQUIRED_ROUTER_TOKENS = {
    "CoachCommandScreen",
    "path: '/coach'",
    "name: 'coach-command'",
}

REQUIRED_TODAY_TOKENS = {
    "context.go('/coach')",
    "Open coach command",
    "Coach",
}

REQUIRED_TEST_TOKENS = {
    "empty state creates first command and required lanes",
    "connected wearable and nutrition produce full coach review context",
    "now: DateTime(2026, 7, 2, 8)",
    "pain review overrides the command center risk label",
    "coach command screen renders empty command center",
    "coach command screen renders wearable and training context",
    "Authenticated users can access the coach command route",
    "Open coach command",
    "coach command screen shared panel header keeps labels and headlines visible",
}

REQUIRED_SHIP_TOKENS = {
    "COACH_COMMAND_CENTER_GATE",
    "coach_command_center_gate",
    "Tier-1 14/27: coach_command_center_gate",
}

APP_BANNED_TERMS = {
    "burn fat",
    "diagnose",
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
        "model": repo_root / "lib/features/coaching/coach_command_center.dart",
        "screen": repo_root / "lib/features/coaching/coach_command_screen.dart",
        "providers": repo_root / "lib/app_providers.dart",
        "router": repo_root / "lib/navigation/app_router.dart",
        "today": repo_root / "lib/screens/today_screen.dart",
        "model_tests": repo_root / "test/features/coaching/coach_command_center_test.dart",
        "screen_tests": repo_root / "test/features/coaching/coach_command_screen_test.dart",
        "router_tests": repo_root / "test/navigation/app_router_test.dart",
        "today_tests": repo_root / "test/today_screen_test.dart",
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
        failures.append(f"coach_command_center.dart missing token: {token}")
    for token in _missing(text["screen"], REQUIRED_SCREEN_TOKENS):
        failures.append(f"coach_command_screen.dart missing token: {token}")
    if text["screen"].count("_CoachPanelHeader(") < 5:
        failures.append(
            "coach_command_screen.dart must reuse _CoachPanelHeader across the command, behavior, emotion, review, and systems panels"
        )
    lane_label_text = "\n".join([text["model"], text["screen"], text["screen_tests"]])
    for token in _missing(lane_label_text, REQUIRED_LANE_LABEL_TOKENS):
        failures.append(f"coach command lane label missing from model/screen/test surface: {token}")
    for token in _missing(text["providers"], REQUIRED_PROVIDER_TOKENS):
        failures.append(f"app_providers.dart missing token: {token}")
    for token in _missing(text["router"], REQUIRED_ROUTER_TOKENS):
        failures.append(f"app_router.dart missing coach route token: {token}")
    for token in _missing(text["today"], REQUIRED_TODAY_TOKENS):
        failures.append(f"today_screen.dart missing coach discovery token: {token}")

    tests_text = "\n".join(
        [
            text["model_tests"],
            text["screen_tests"],
            text["router_tests"],
            text["today_tests"],
        ]
    )
    for token in _missing(tests_text, REQUIRED_TEST_TOKENS):
        failures.append(f"coach command tests missing token: {token}")

    for token in _missing(text["ship_gate"], REQUIRED_SHIP_TOKENS):
        failures.append(f"ship_gate.sh missing coach command gate token: {token}")
    if "coach_command_center_gate" not in text["bridge"]:
        failures.append("bridge.json missing coach_command_center_gate routing")
    if '"coach_command_center"' not in text["bridge"]:
        failures.append("bridge.json missing coach_command_center artifact type")
    if "coach_command_center_gate" not in text["war_room"]:
        failures.append("two_day_war_room.json missing coach_command_center_gate")
    if "kpi-coach-command-center" not in text["war_room"]:
        failures.append("two_day_war_room.json missing coach command KPI")
    if "coach_command_center" not in text["war_room"]:
        failures.append("two_day_war_room.json missing coach command lane")
    if '"coach_command_center_gate"' not in text["war_room_gate"]:
        failures.append("two_day_war_room_gate.py missing coach_command_center_gate")
    if '"kpi-coach-command-center"' not in text["war_room_gate"]:
        failures.append("two_day_war_room_gate.py missing coach command KPI")
    if '"coach_command_center"' not in text["war_room_gate"]:
        failures.append("two_day_war_room_gate.py missing coach command lane")

    visible_app_text = "\n".join([text["screen"], text["today"]]).lower()
    for banned in sorted(APP_BANNED_TERMS):
        if banned in visible_app_text:
            failures.append(f"visible coach command surface contains banned term: {banned}")

    return {
        "schema": "transformfit.coach_command_center_gate.v1",
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
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args(argv)

    result = run(args.repo_root.resolve())
    if args.json:
        print(json.dumps(result, indent=2, sort_keys=True))
    else:
        print(json.dumps(result, indent=2, sort_keys=True))
    return 0 if result["verdict"] == "GREEN" else 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
