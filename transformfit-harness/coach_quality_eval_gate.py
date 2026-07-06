#!/usr/bin/env python3
"""Fail-closed gate for deterministic TransformFit coach-quality scenarios."""

from __future__ import annotations

import argparse
import json
import pathlib
import sys
from typing import Iterable


REQUIRED_RUNTIME_TOKENS = {
    "buildCoachQualityVerdict",
    "evaluateCoachSignal",
    "CoachQualityVerdict",
    "CoachQualityIssue",
    "pain_workflow",
    "pain_progression_block",
    "low_readiness_workflow",
    "low_readiness_progression",
    "coasting_workflow",
    "live_session_workflow",
    "overreach_workflow",
    "state.activeSession == null",
    "day_zero_workflow",
    "copy_safety",
}

REQUIRED_SIGNAL_TOKENS = {
    "pain_or_injury_guardrail",
    "hasReportedPain",
    "No load increase is approved",
    "Choose pain-free variation",
    "stop sharp pain",
}

REQUIRED_TEST_SCENARIOS = {
    "day_zero_activation",
    "doms_or_low_readiness",
    "active coasting",
    "active_session_with_history",
    "active_session_with_historical_overreach",
    "rapid_volume_jump",
    "reported_pain",
    "unsafe_copy",
}

REQUIRED_HARNESS_TOKENS = {
    "pain_or_injury_guardrail",
    "coach_quality_eval_gate",
    "Pain or injury notes must suppress progression",
}

REQUIRED_UI_TOKENS = {
    "signal.observationLabel",
    "signal.observation",
    "signal.nextAction",
    "Icons.arrow_forward",
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
        "runtime": repo_root / "lib/features/coaching/coach_quality_eval.dart",
        "signal": repo_root / "lib/features/coaching/coach_signal.dart",
        "tests": repo_root / "test/features/coaching/coach_quality_eval_test.dart",
        "signal_tests": repo_root / "test/features/coaching/coach_signal_test.dart",
        "ui": repo_root / "lib/features/workout/active_workout_screen.dart",
        "ui_tests": repo_root / "test/features/workout/active_workout_screen_test.dart",
        "harness": repo_root / "transformfit-harness/coaching_harness.json",
    }
    text = {name: _read(path) for name, path in paths.items()}

    for name, body in text.items():
        if not body:
            failures.append(f"missing required file: {paths[name]}")

    for token in _missing(text["runtime"], REQUIRED_RUNTIME_TOKENS):
        failures.append(f"coach_quality_eval.dart missing token: {token}")
    for token in _missing(text["signal"], REQUIRED_SIGNAL_TOKENS):
        failures.append(f"coach_signal.dart missing pain guardrail token: {token}")
    for token in _missing(text["tests"], REQUIRED_TEST_SCENARIOS):
        failures.append(f"coach_quality_eval_test.dart missing scenario: {token}")
    for token in _missing(text["harness"], REQUIRED_HARNESS_TOKENS):
        failures.append(f"coaching_harness.json missing token: {token}")
    for token in _missing(text["ui"], REQUIRED_UI_TOKENS):
        failures.append(f"active_workout_screen.dart missing visible cue token: {token}")

    if "pain_or_injury_guardrail" not in text["signal_tests"]:
        failures.append("coach_signal_test.dart missing pain workflow assertion")
    if (
        "Live set target:" not in text["ui_tests"]
        or "Log the first working set" not in text["ui_tests"]
    ):
        failures.append("active_workout_screen_test.dart missing observation/action visibility assertions")

    return {
        "schema": "transformfit.coach_quality_eval_gate.v1",
        "repo_root": str(repo_root),
        "verdict": "GREEN" if not failures else "RED",
        "failures": failures,
        "required_scenarios": sorted(REQUIRED_TEST_SCENARIOS),
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
        print(f"{result['verdict']} coach_quality_eval_gate: {result['repo_root']}")
        for failure in result["failures"]:
            print(f"  - {failure}")
    return 0 if result["verdict"] == "GREEN" else 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
