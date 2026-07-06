#!/usr/bin/env python3
"""Validate that the coaching harness is embedded in runtime product surfaces."""

from __future__ import annotations

import argparse
import json
import pathlib
import sys
from typing import Iterable


REQUIRED_WORKFLOWS = {
    "day_0_activation",
    "doms_or_low_readiness",
    "live_session_guidance",
    "progress_interpretation",
    "coasting_or_overreaching",
    "pain_or_injury_guardrail",
}

REQUIRED_SOURCE_IDS = {
    "src_cal_ai_app_store_preview",
    "src_ladder_app_store_preview",
    "src_nike_run_club_app_store_preview",
    "src_calm_health_app_store_preview",
    "src_garmin_app_store_preview",
    "src_macrofactor_workouts_google_play",
    "src_hevy_app_store_preview",
    "src_strava_app_store_preview",
    "src_macrofactor_workouts_product",
    "src_liftoff_app_store_preview",
    "src_fitbod_app_store_preview",
}
REQUIRED_EFFORT_CLASSIFIER_TOKENS = {
    "enum _EffortRiskKind { none, coasting, overreaching }",
    "class _EffortRiskClassification",
    "_classifyEffortRisk({",
    "required List<LoggedSet> loggedSets",
    "currentVolume > priorVolume * 1.6",
    "classification.kind == _EffortRiskKind.coasting",
    "switch (classification.kind)",
}
REQUIRED_EFFORT_CLASSIFIER_TEST_TOKENS = {
    "shared effort classifier keeps live and historical coasting thresholds aligned",
    "session-live-coasting",
    "session-latest-coasting",
    "expect(liveSignal.observation, contains('5/10 RPE'));",
    "expect(historicalSignal.observation, contains('5/10 RPE'));",
}


def _read(path: pathlib.Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except FileNotFoundError:
        return ""


def _missing_tokens(text: str, tokens: Iterable[str]) -> list[str]:
    return [token for token in tokens if token not in text]


def _find_failures(repo_root: pathlib.Path) -> list[str]:
    failures: list[str] = []
    coach_signal = repo_root / "lib/features/coaching/coach_signal.dart"
    app_providers = repo_root / "lib/app_providers.dart"
    today_screen = repo_root / "lib/screens/today_screen.dart"
    workout_screen = repo_root / "lib/features/workout/active_workout_screen.dart"
    coach_tests = repo_root / "test/features/coaching/coach_signal_test.dart"
    coach_quality_eval = repo_root / "lib/features/coaching/coach_quality_eval.dart"
    coach_quality_tests = repo_root / "test/features/coaching/coach_quality_eval_test.dart"
    today_tests = repo_root / "test/today_screen_test.dart"
    workout_tests = repo_root / "test/features/workout/active_workout_screen_test.dart"

    signal_text = _read(coach_signal)
    provider_text = _read(app_providers)
    today_text = _read(today_screen)
    workout_text = _read(workout_screen)
    coach_test_text = _read(coach_tests)
    coach_quality_text = _read(coach_quality_eval)
    coach_quality_test_text = _read(coach_quality_tests)
    today_test_text = _read(today_tests)
    workout_test_text = _read(workout_tests)

    for path, text in [
        (coach_signal, signal_text),
        (app_providers, provider_text),
        (today_screen, today_text),
        (workout_screen, workout_text),
        (coach_tests, coach_test_text),
        (coach_quality_eval, coach_quality_text),
        (coach_quality_tests, coach_quality_test_text),
    ]:
        if not text:
            failures.append(f"missing required file: {path}")

    missing_workflows = _missing_tokens(signal_text, REQUIRED_WORKFLOWS)
    if missing_workflows:
        failures.append(f"coach_signal.dart missing workflows: {missing_workflows}")

    missing_sources = _missing_tokens(signal_text, REQUIRED_SOURCE_IDS)
    if missing_sources:
        failures.append(f"coach_signal.dart missing source trace ids: {missing_sources}")

    for token in [
        "class CoachSignal",
        "CoachSignal buildCoachSignal(SessionState state)",
        "_activeSessionRiskSignal",
        "_historicalRiskSignal",
        "coachSignalCopyIsGateSafe",
        "semanticLabel",
        "confidenceLabel",
        "sourceTraceLabel",
    ]:
        if token not in signal_text:
            failures.append(f"coach_signal.dart missing runtime contract token: {token}")

    for token in [
        "final coachSignalProvider = Provider<CoachSignal>",
        "buildCoachSignal(ref.watch(sessionStateProvider))",
        "coachNoteProvider",
        "ref.watch(coachSignalProvider).coachNote",
    ]:
        if token not in provider_text:
            failures.append(f"app_providers.dart missing provider wiring token: {token}")

    for token in [
        "_TodayHeader(",
        "coachSignal: coachSignal",
        "final CoachSignal coachSignal",
        "coachSignal.semanticLabel",
        "_CoachTracePill",
        "coachSignal.observation",
    ]:
        if token not in today_text:
            failures.append(f"today_screen.dart missing embedded coach token: {token}")

    for token in [
        "import 'package:transformfit/features/coaching/coach_signal.dart'",
        "final coachSignal = buildCoachSignal(state)",
        "required this.coachSignal",
        "_WorkoutCoachCue(signal: coachSignal)",
        "signal.semanticLabel",
    ]:
        if token not in workout_text:
            failures.append(f"active_workout_screen.dart missing embedded coach token: {token}")

    for workflow in REQUIRED_WORKFLOWS:
        if workflow not in coach_test_text:
            failures.append(f"coach_signal_test.dart missing workflow assertion: {workflow}")

    try:
        active_branch_index = signal_text.index("if (state.activeSession != null)")
        historical_branch_index = signal_text.index("final historicalRiskSignal = _historicalRiskSignal(state)")
        progress_branch_index = signal_text.index("return _progressInterpretation(state)")
        if not active_branch_index < historical_branch_index < progress_branch_index:
            failures.append(
                "coach_signal.dart must keep active-session guidance before historical risk/progress interpretation"
            )
    except ValueError:
        failures.append("coach_signal.dart missing active-session ordering proof tokens")

    for token in [
        "active session ignores historical overreach and stays live",
        "Hold volume steady next time",
        "isNot(contains('Volume jumped'))",
    ]:
        if token not in coach_test_text:
            failures.append(f"coach_signal_test.dart missing active-session precedence proof: {token}")

    for token in REQUIRED_EFFORT_CLASSIFIER_TOKENS:
        if token not in signal_text:
            failures.append(f"coach_signal.dart missing shared effort classifier token: {token}")

    for token in REQUIRED_EFFORT_CLASSIFIER_TEST_TOKENS:
        if token not in coach_test_text:
            failures.append(f"coach_signal_test.dart missing shared effort classifier proof: {token}")

    for token in [
        "buildCoachQualityVerdict",
        "evaluateCoachSignal",
        "pain_workflow",
        "low_readiness_workflow",
        "coasting_workflow",
        "overreach_workflow",
        "copy_safety",
    ]:
        if token not in coach_quality_text:
            failures.append(f"coach_quality_eval.dart missing eval token: {token}")

    for token in [
        "reported_pain",
        "doms_or_low_readiness",
        "active coasting",
        "rapid_volume_jump",
        "unsafe_copy",
    ]:
        if token not in coach_quality_test_text:
            failures.append(f"coach_quality_eval_test.dart missing scenario token: {token}")

    if "Motivator" not in today_test_text or "3 sources" not in today_test_text:
        failures.append("today_screen_test.dart missing visible coach trace assertions")

    if (
        "Workout command center" not in workout_test_text
        or "active workout" not in workout_test_text
        or "Live set target:" not in workout_test_text
    ):
        failures.append("active_workout_screen_test.dart missing workout surface coverage")

    return failures


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--repo-root",
        type=pathlib.Path,
        default=pathlib.Path("."),
        help="TransformFit Flutter repo root",
    )
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    repo_root = args.repo_root.resolve()
    failures = _find_failures(repo_root)
    result = {
        "schema": "transformfit.coaching_runtime_gate.v1",
        "repo_root": str(repo_root),
        "verdict": "RED" if failures else "GREEN",
        "failures": failures,
        "required_workflows": sorted(REQUIRED_WORKFLOWS),
    }
    if args.json:
        print(json.dumps(result, indent=2))
    else:
        print(f"{result['verdict']} coaching_runtime_gate: {repo_root}")
        for failure in failures:
            print(f"  - {failure}")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
