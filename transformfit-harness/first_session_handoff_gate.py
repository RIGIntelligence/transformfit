#!/usr/bin/env python3
"""Fail-closed gate for TransformFit's local-first first-session handoff."""

from __future__ import annotations

import argparse
import json
import pathlib
import sys
from typing import Iterable


REQUIRED_SCREEN_TOKENS = {
    "import 'dart:async';",
    "authControllerProvider",
    "authGuardStateProvider",
    "AuthGuardStatus.authenticatedWithProfile",
    "plan_reveal_controller.dart",
    "_clearPendingOnboardingProviders(ref);",
    "void _clearPendingOnboardingProviders(WidgetRef ref)",
    "ref.read(pendingIntakeProvider.notifier).clear();",
    "ref.read(userWhyNowProvider.notifier).clear();",
    "context.go('/workout', extra: workoutPrefill);",
    "unawaited(",
    "_completeRemoteOnboarding(",
    "Future<void> _completeRemoteOnboarding",
    "completeOnboarding(userId)",
    "authController.refresh()",
    "first-session handoff completion sync failed",
    "sorenessMap: const []",
    "Limitations shape exercise selection; they are not",
}

REQUIRED_TEST_TOKENS = {
    "handoff enters workout before remote onboarding completion resolves",
    "completeOnboardingGate",
    "expect(harness.profileFacade.onboardingCompleted, isFalse);",
    "AuthGuardStatus.authenticatedWithProfile",
    "expect(find.text('WORKOUT_SCREEN'), findsOneWidget);",
    "PLAN_QUEUE:",
    "profileGate.complete();",
    "expect(harness.profileFacade.onboardingCompleted, isTrue);",
    "handoff does not turn limitations into soreness",
    "limitations: ['knee', 'shoulder']",
    "expect(sessionState.readinessEntry!.sorenessMap, isEmpty);",
    "handoff clears pending intake and why-now after starting session",
    "pendingIntake: dumbbellsIntake",
    "pendingWhyNow: 'I want this to stick.'",
    "expect(harness.container.read(pendingIntakeProvider), isNull);",
    "expect(harness.container.read(userWhyNowProvider), isNull);",
}

REQUIRED_SHIP_TOKENS = {
    "FIRST_SESSION_HANDOFF_GATE",
    "first_session_handoff_gate",
    "Tier-1 24/27: first_session_handoff_gate",
    "Tier-1 27/27: ship_gate_non_vacuity_gate",
}

REQUIRED_BRIDGE_TOKENS = {
    '"first_session_handoff_gate"',
    '"first_session_handoff"',
    "deterministic_first_session_handoff_check",
}

REQUIRED_WAR_ROOM_TOKENS = {
    '"kpi-first-session-handoff"',
    '"first_session_handoff"',
    '"first_session_handoff_gate"',
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


def _read(path: pathlib.Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except FileNotFoundError:
        return ""


def _missing(text: str, tokens: Iterable[str]) -> list[str]:
    return [token for token in tokens if token not in text]


def _index_or_negative(text: str, token: str) -> int:
    return text.find(token)


def run(repo_root: pathlib.Path) -> dict[str, object]:
    failures: list[str] = []
    paths = {
        "screen": repo_root / "lib/features/onboarding/first_session_handoff_screen.dart",
        "screen_tests": repo_root
        / "test/features/onboarding/first_session_handoff_test.dart",
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

    for token in _missing(text["screen"], REQUIRED_SCREEN_TOKENS):
        failures.append(f"first_session_handoff_screen.dart missing token: {token}")
    for token in _missing(text["screen_tests"], REQUIRED_TEST_TOKENS):
        failures.append(f"first_session_handoff_test.dart missing token: {token}")
    for token in _missing(text["ship_gate"], REQUIRED_SHIP_TOKENS):
        failures.append(f"ship_gate.sh missing first-session handoff token: {token}")
    for token in _missing(text["bridge"], REQUIRED_BRIDGE_TOKENS):
        failures.append(f"bridge.json missing first-session handoff token: {token}")
    for token in _missing(text["war_room"], REQUIRED_WAR_ROOM_TOKENS):
        failures.append(f"two_day_war_room.json missing first-session handoff token: {token}")
    for token in _missing(text["war_room_gate"], REQUIRED_WAR_ROOM_TOKENS):
        failures.append(
            f"two_day_war_room_gate.py missing first-session handoff token: {token}"
        )
    if "first_session_handoff_remote_completion_block_removed" not in text["non_vacuity"]:
        failures.append(
            "ship_gate_non_vacuity_gate.py missing first-session handoff planted failure"
        )
    if "first_session_handoff_limitations_as_soreness_planted" not in text["non_vacuity"]:
        failures.append(
            "ship_gate_non_vacuity_gate.py missing limitations-as-soreness planted failure"
        )
    if "first_session_handoff_pending_onboarding_clear_removed" not in text["non_vacuity"]:
        failures.append(
            "ship_gate_non_vacuity_gate.py missing pending-onboarding-clear planted failure"
        )

    guard_index = _index_or_negative(
        text["screen"], "AuthGuardStatus.authenticatedWithProfile"
    )
    nav_index = _index_or_negative(
        text["screen"], "context.go('/workout', extra: workoutPrefill);"
    )
    sync_index = _index_or_negative(text["screen"], "unawaited(")
    clear_index = _index_or_negative(text["screen"], "_clearPendingOnboardingProviders(ref);")
    user_id_index = _index_or_negative(text["screen"], "currentUserId()")
    if guard_index < 0 or nav_index < 0 or sync_index < 0 or clear_index < 0:
        failures.append("first-session handoff order tokens are incomplete")
    else:
        if user_id_index >= 0 and clear_index > user_id_index:
            failures.append(
                "pending onboarding providers must clear before authenticated/no-user navigation branching"
            )
        if clear_index > nav_index:
            failures.append("pending onboarding providers must clear before workout navigation")
        if guard_index > nav_index:
            failures.append("auth guard must be promoted before workout navigation")
        if nav_index > sync_index:
            failures.append("workout navigation must happen before remote completion sync")

    visible_app_text = text["screen"].lower()
    for banned in sorted(APP_BANNED_TERMS):
        if banned in visible_app_text:
            failures.append(f"visible first-session handoff surface contains banned term: {banned}")
    for forbidden in [
        "sorenessMap: intake.limitations",
        "const ['first-session']",
    ]:
        if forbidden in text["screen"]:
            failures.append(
                f"first-session handoff fabricates soreness from non-soreness input: {forbidden}"
            )

    return {
        "schema": "transformfit.first_session_handoff_gate.v1",
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
