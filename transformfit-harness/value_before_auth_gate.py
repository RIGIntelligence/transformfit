#!/usr/bin/env python3
"""Fail-closed gate for TransformFit's value-before-auth first-open corridor."""

from __future__ import annotations

import argparse
import json
import pathlib
import sys
from typing import Iterable


REQUIRED_ROUTER_TOKENS = {
    "isPublicFirstValueRoute",
    "location == '/auth' || inOnboarding",
    "status == AuthGuardStatus.unauthenticated",
    "return '/onboarding';",
    "return '/auth';",
}

REQUIRED_LANDING_TOKENS = {
    "Coach value claim",
    "Readiness preview",
    "Begin onboarding",
    "Sign in to existing account",
    "context.go('/onboarding/welcome')",
    "context.go('/auth')",
    "A coach who already noticed you",
}

REQUIRED_TEST_TOKENS = {
    "Unauthenticated first open lands on value before auth",
    "Unauthenticated users can continue public onboarding",
    "Unauthenticated protected routes still redirect to auth",
    "App mounts value-before-auth landing when unauthenticated",
    "Landing keeps sign-in available without making it the first ask",
    "Coach value claim",
    "Begin onboarding",
    "Sign in to existing account",
    "Welcome back",
}

REQUIRED_SHIP_TOKENS = {
    "VALUE_BEFORE_AUTH_GATE",
    "value_before_auth_gate",
    "Tier-1 23/27: value_before_auth_gate",
    "Tier-1 27/27: ship_gate_non_vacuity_gate",
}

REQUIRED_BRIDGE_TOKENS = {
    '"value_before_auth_gate"',
    '"value_before_auth"',
    "deterministic_value_before_auth_check",
}

REQUIRED_WAR_ROOM_TOKENS = {
    '"kpi-value-before-auth"',
    '"value_before_auth"',
    '"value_before_auth_gate"',
}

APP_BANNED_TERMS = {
    "before and after",
    "burn fat",
    "checkout",
    "diagnose",
    "no excuses",
    "pricing",
    "punish",
    "shame",
    "subscribe",
    "weight loss",
}

STALE_ONBOARDING_SCREEN = pathlib.Path("lib/screens/onboarding_screen.dart")


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
        "router": repo_root / "lib/navigation/app_router.dart",
        "landing": repo_root / "lib/features/onboarding/landing_screen.dart",
        "router_tests": repo_root / "test/navigation/app_router_test.dart",
        "widget_tests": repo_root / "test/widget_test.dart",
        "landing_tests": repo_root / "test/features/onboarding/landing_screen_test.dart",
        "ship_gate": repo_root / "transformfit-harness/ship_gate.sh",
        "bridge": repo_root / "transformfit-harness/bridge.json",
        "war_room": repo_root / "transformfit-harness/two_day_war_room.json",
        "war_room_gate": repo_root / "transformfit-harness/two_day_war_room_gate.py",
        "non_vacuity": repo_root / "transformfit-harness/ship_gate_non_vacuity_gate.py",
    }
    text = {name: _read(path) for name, path in paths.items()}
    stale_screen = repo_root / STALE_ONBOARDING_SCREEN

    for name, body in text.items():
        if not body:
            failures.append(f"missing required file: {paths[name]}")

    if stale_screen.exists():
        failures.append(
            "stale M1 onboarding screen must be removed or dev-only gated: "
            f"{STALE_ONBOARDING_SCREEN}"
        )

    for token in _missing(text["router"], REQUIRED_ROUTER_TOKENS):
        failures.append(f"app_router.dart missing value-before-auth token: {token}")
    for token in _missing(text["landing"], REQUIRED_LANDING_TOKENS):
        failures.append(f"landing_screen.dart missing value-before-auth token: {token}")

    tests_text = "\n".join(
        [text["router_tests"], text["widget_tests"], text["landing_tests"]]
    )
    for token in _missing(tests_text, REQUIRED_TEST_TOKENS):
        failures.append(f"value-before-auth tests missing token: {token}")

    for token in _missing(text["ship_gate"], REQUIRED_SHIP_TOKENS):
        failures.append(f"ship_gate.sh missing value-before-auth token: {token}")
    for token in _missing(text["bridge"], REQUIRED_BRIDGE_TOKENS):
        failures.append(f"bridge.json missing value-before-auth token: {token}")
    for token in _missing(text["war_room"], REQUIRED_WAR_ROOM_TOKENS):
        failures.append(f"two_day_war_room.json missing value-before-auth token: {token}")
    for token in _missing(text["war_room_gate"], REQUIRED_WAR_ROOM_TOKENS):
        failures.append(f"two_day_war_room_gate.py missing value-before-auth token: {token}")
    if "value_before_auth_first_open_redirect_removed" not in text["non_vacuity"]:
        failures.append("ship_gate_non_vacuity_gate.py missing value-before-auth planted failure")

    visible_app_text = text["landing"].lower()
    for banned in sorted(APP_BANNED_TERMS):
        if banned in visible_app_text:
            failures.append(f"visible value-before-auth surface contains banned term: {banned}")

    return {
        "schema": "transformfit.value_before_auth_gate.v1",
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
