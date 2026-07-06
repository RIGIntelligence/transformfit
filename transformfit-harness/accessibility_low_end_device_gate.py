#!/usr/bin/env python3
"""Fail-closed gate for TransformFit accessibility and low-end mobile coverage."""

from __future__ import annotations

import argparse
import json
import pathlib
import sys
from typing import Iterable


REQUIRED_SCREEN_TOKENS = {
    "SafeArea(",
    "SingleChildScrollView(",
    "LayoutBuilder(",
    "Semantics(",
    "minimumSize: const Size",
    "TransformFitAI proof logo",
    "Proof card share preview",
    "Copy redacted proof text",
    "Log set",
    "Undo last set",
    "MediaQuery.supportsAnnounceOf(context)",
}

REQUIRED_TEST_TOKENS = {
    "Today iPhone controls keep app-grade touch targets",
    "active workout top bar fits a compact iPhone viewport",
    "active workout quick actions wrap inside mobile viewport",
    "proof card sharing controls survive narrow large-text viewport",
    "tester.view.physicalSize",
    "tester.view.devicePixelRatio",
    "textScale: 1.35",
    "TextScaler.linear(textScale)",
    "bySemanticsLabel('Return to Today')",
    "bySemanticsLabel('Copy redacted proof text')",
    "bySemanticsLabel('TransformFitAI proof logo')",
    "bySemanticsLabel('Proof card share preview')",
    "I reviewed this redacted proof text",
    "greaterThanOrEqualTo(44)",
    "bySemanticsLabel('Email')",
    "bySemanticsLabel('Password')",
    "bySemanticsLabel('Sign in')",
    "bySemanticsLabel('Begin onboarding')",
    "bySemanticsLabel('Sign in to existing account')",
    "bySemanticsLabel('TransformFitAI progress logo')",
}

REQUIRED_SHIP_TOKENS = {
    "ACCESSIBILITY_LOW_END_DEVICE_GATE",
    "accessibility_low_end_device_gate",
    "Tier-1 25/27: accessibility_low_end_device_gate",
    "Tier-1 27/27: ship_gate_non_vacuity_gate",
}

REQUIRED_BRIDGE_TOKENS = {
    '"accessibility_low_end_device_gate"',
    '"accessibility_low_end_device"',
    "deterministic_accessibility_low_end_device_check",
}

REQUIRED_WAR_ROOM_TOKENS = {
    '"kpi-accessibility-low-end-device"',
    '"accessibility_and_low_end_device"',
    '"accessibility_low_end_device_gate"',
}

APP_BANNED_TERMS = {
    "before and after",
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
        "today": repo_root / "lib/screens/today_screen.dart",
        "workout": repo_root / "lib/features/workout/active_workout_screen.dart",
        "proof": repo_root / "lib/features/proof/proof_card_screen.dart",
        "progress": repo_root / "lib/features/progress/progress_screen.dart",
        "auth": repo_root / "lib/screens/auth_screen.dart",
        "landing": repo_root / "lib/features/onboarding/landing_screen.dart",
        "today_tests": repo_root / "test/today_screen_test.dart",
        "workout_tests": repo_root
        / "test/features/workout/active_workout_screen_test.dart",
        "proof_tests": repo_root / "test/features/proof/proof_card_screen_test.dart",
        "progress_tests": repo_root / "test/features/progress/progress_screen_test.dart",
        "auth_tests": repo_root / "test/features/auth/auth_screen_test.dart",
        "landing_tests": repo_root
        / "test/features/onboarding/landing_screen_test.dart",
        "router_tests": repo_root / "test/navigation/app_router_test.dart",
        "ship_gate": repo_root / "transformfit-harness/ship_gate.sh",
        "bridge": repo_root / "transformfit-harness/bridge.json",
        "war_room": repo_root / "transformfit-harness/two_day_war_room.json",
        "war_room_gate": repo_root / "transformfit-harness/two_day_war_room_gate.py",
        "non_vacuity": repo_root
        / "transformfit-harness/ship_gate_non_vacuity_gate.py",
    }
    text = {name: _read(path) for name, path in paths.items()}

    for name, body in text.items():
        if not body:
            failures.append(f"missing required file: {paths[name]}")

    screen_text = "\n".join(
        [
            text["today"],
            text["workout"],
            text["proof"],
            text["progress"],
            text["auth"],
            text["landing"],
        ]
    )
    test_text = "\n".join(
        [
            text["today_tests"],
            text["workout_tests"],
            text["proof_tests"],
            text["progress_tests"],
            text["auth_tests"],
            text["landing_tests"],
            text["router_tests"],
        ]
    )

    for token in _missing(screen_text, REQUIRED_SCREEN_TOKENS):
        failures.append(f"accessible screen surface missing token: {token}")
    for token in _missing(test_text, REQUIRED_TEST_TOKENS):
        failures.append(f"accessibility/low-end tests missing token: {token}")
    for token in _missing(text["ship_gate"], REQUIRED_SHIP_TOKENS):
        failures.append(f"ship_gate.sh missing accessibility token: {token}")
    for token in _missing(text["bridge"], REQUIRED_BRIDGE_TOKENS):
        failures.append(f"bridge.json missing accessibility token: {token}")
    for token in _missing(text["war_room"], REQUIRED_WAR_ROOM_TOKENS):
        failures.append(f"two_day_war_room.json missing accessibility token: {token}")
    for token in _missing(text["war_room_gate"], REQUIRED_WAR_ROOM_TOKENS):
        failures.append(f"two_day_war_room_gate.py missing accessibility token: {token}")
    if "accessibility_low_end_proof_large_text_removed" not in text["non_vacuity"]:
        failures.append(
            "ship_gate_non_vacuity_gate.py missing accessibility planted failure"
        )

    visible_app_text = screen_text.lower()
    for banned in sorted(APP_BANNED_TERMS):
        if banned in visible_app_text:
            failures.append(f"visible accessibility surface contains banned term: {banned}")

    return {
        "schema": "transformfit.accessibility_low_end_device_gate.v1",
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
    print(json.dumps(result, indent=2, sort_keys=True))
    return 0 if result["verdict"] == "GREEN" else 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
