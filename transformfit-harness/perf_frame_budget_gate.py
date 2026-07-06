#!/usr/bin/env python3
"""Fail-closed gate for TransformFit local route frame-budget coverage."""

from __future__ import annotations

import argparse
import json
import pathlib
import sys
from typing import Iterable


REQUIRED_TEST_TOKENS = {
    "core protected routes settle inside p95 800ms frame budget",
    "const _transitionBudgetMs = 800;",
    "const _frameInterval = Duration(milliseconds: 16);",
    "const _transitionBudgetFrames = 50;",
    "_pumpUntilNoScheduledFrames",
    "tester.binding.hasScheduledFrame",
    "_percentile95",
    "lessThanOrEqualTo(_transitionBudgetMs)",
    "AuthGuardStatus.authenticatedWithProfile",
    "router.go(route.path)",
    "_RouteBudget('/', 'Today route', find.text('Today'))",
    "_RouteBudget('/workout', 'Workout route', find.text('No live session'))",
    "_RouteBudget('/proof', 'Proof route', find.text('Proof card'))",
    "_RouteBudget('/progress', 'Progress route', find.text('Progress'))",
    "'/composition',",
    "'Composition route'",
    "_RouteBudget('/coach', 'Coach command route', find.text('Coach command'))",
    "_RouteBudget('/profile', 'Profile route', find.text('Profile'))",
}

REQUIRED_APP_TOKENS = {
    "MaterialApp.router(",
    "routerConfig: router",
    "debugShowCheckedModeBanner: false",
    "initialLocation: '/'",
    "errorBuilder: (context, state) => const NotFoundScreen()",
}

REQUIRED_SHIP_TOKENS = {
    "PERF_FRAME_BUDGET_GATE",
    "perf_frame_budget_gate",
    "Tier-1 26/27: perf_frame_budget_gate",
    "Tier-1 27/27: ship_gate_non_vacuity_gate",
}

REQUIRED_BRIDGE_TOKENS = {
    '"perf_frame_budget_gate"',
    '"perf_frame_budget"',
    "deterministic_perf_frame_budget_check",
}

REQUIRED_WAR_ROOM_TOKENS = {
    '"kpi-performance-reliability"',
    '"performance_reliability_budget"',
    '"perf_frame_budget_gate"',
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
        "test": repo_root / "test/performance/frame_budget_test.dart",
        "main": repo_root / "lib/main.dart",
        "router": repo_root / "lib/navigation/app_router.dart",
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

    for token in _missing(text["test"], REQUIRED_TEST_TOKENS):
        failures.append(f"frame_budget_test.dart missing token: {token}")
    app_text = "\n".join([text["main"], text["router"]])
    for token in _missing(app_text, REQUIRED_APP_TOKENS):
        failures.append(f"router/app performance surface missing token: {token}")
    for token in _missing(text["ship_gate"], REQUIRED_SHIP_TOKENS):
        failures.append(f"ship_gate.sh missing performance token: {token}")
    for token in _missing(text["bridge"], REQUIRED_BRIDGE_TOKENS):
        failures.append(f"bridge.json missing performance token: {token}")
    for token in _missing(text["war_room"], REQUIRED_WAR_ROOM_TOKENS):
        failures.append(f"two_day_war_room.json missing performance token: {token}")
    for token in _missing(text["war_room_gate"], REQUIRED_WAR_ROOM_TOKENS):
        failures.append(f"two_day_war_room_gate.py missing performance token: {token}")
    if "perf_frame_budget_route_budget_removed" not in text["non_vacuity"]:
        failures.append(
            "ship_gate_non_vacuity_gate.py missing performance planted failure"
        )

    return {
        "schema": "transformfit.perf_frame_budget_gate.v1",
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
