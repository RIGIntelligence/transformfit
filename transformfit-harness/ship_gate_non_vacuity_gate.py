#!/usr/bin/env python3
"""Fail-closed non-vacuity gate for TransformFit Tier-1 ship gates.

The gate proves representative ship-gate members are not fake-green by:
1. copying only the required artifact files into a temporary repo root,
2. confirming the clean copied artifact passes its deterministic gate,
3. planting a targeted failure in the copy,
4. confirming the same gate turns RED.

The real repo is never mutated by this gate.
"""

from __future__ import annotations

import argparse
import json
import pathlib
import shutil
import subprocess
import sys
import tempfile
from dataclasses import dataclass
from typing import Callable


COMMON_ROUTE_FILES = [
    "transformfit-harness/ship_gate.sh",
    "transformfit-harness/bridge.json",
    "transformfit-harness/two_day_war_room.json",
    "transformfit-harness/two_day_war_room_gate.py",
]

REQUIRED_SHIP_TOKENS = {
    "VALUE_BEFORE_AUTH_GATE",
    "FIRST_SESSION_HANDOFF_GATE",
    "SHIP_GATE_NON_VACUITY_GATE",
    "Tier-1 23/27: value_before_auth_gate",
    "Tier-1 24/27: first_session_handoff_gate",
    "ACCESSIBILITY_LOW_END_DEVICE_GATE",
    "accessibility_low_end_device_gate",
    "Tier-1 25/27: accessibility_low_end_device_gate",
    "PERF_FRAME_BUDGET_GATE",
    "perf_frame_budget_gate",
    "Tier-1 26/27: perf_frame_budget_gate",
    "ship_gate_non_vacuity_gate",
    "Tier-1 27/27: ship_gate_non_vacuity_gate",
}

REQUIRED_BRIDGE_TOKENS = {
    '"value_before_auth_gate"',
    '"first_session_handoff_gate"',
    '"accessibility_low_end_device_gate"',
    '"perf_frame_budget_gate"',
    '"ship_gate_non_vacuity_gate"',
    '"value_before_auth"',
    '"first_session_handoff"',
    '"accessibility_low_end_device"',
    '"perf_frame_budget"',
    '"ship_gate_non_vacuity"',
    "deterministic_first_session_handoff_check",
    "deterministic_accessibility_low_end_device_check",
    "deterministic_perf_frame_budget_check",
    "deterministic_ship_gate_non_vacuity_check",
}

REQUIRED_WAR_ROOM_TOKENS = {
    '"kpi-value-before-auth"',
    '"kpi-first-session-handoff"',
    '"kpi-accessibility-low-end-device"',
    '"kpi-performance-reliability"',
    '"kpi-ship-gate-non-vacuity"',
    '"value_before_auth"',
    '"first_session_handoff"',
    '"accessibility_and_low_end_device"',
    '"performance_reliability_budget"',
    '"ship_gate_non_vacuity"',
    '"value_before_auth_gate"',
    '"first_session_handoff_gate"',
    '"accessibility_low_end_device_gate"',
    '"perf_frame_budget_gate"',
    '"ship_gate_non_vacuity_gate"',
}

REQUIRED_WAR_ROOM_GATE_TOKENS = {
    '"kpi-value-before-auth"',
    '"kpi-first-session-handoff"',
    '"kpi-accessibility-low-end-device"',
    '"kpi-performance-reliability"',
    '"kpi-ship-gate-non-vacuity"',
    '"value_before_auth"',
    '"first_session_handoff"',
    '"accessibility_and_low_end_device"',
    '"performance_reliability_budget"',
    '"ship_gate_non_vacuity"',
    '"value_before_auth_gate"',
    '"first_session_handoff_gate"',
    '"accessibility_low_end_device_gate"',
    '"perf_frame_budget_gate"',
    '"ship_gate_non_vacuity_gate"',
}


@dataclass(frozen=True)
class NonVacuityScenario:
    scenario_id: str
    gate_script: str
    gate_args: tuple[str, ...]
    copy_paths: tuple[str, ...]
    mutation_path: str
    mutation: Callable[[pathlib.Path], None]
    expected_failure_fragment: str


def _read(path: pathlib.Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except FileNotFoundError:
        return ""


def _copy_paths(repo_root: pathlib.Path, temp_root: pathlib.Path, paths: tuple[str, ...]) -> list[str]:
    missing: list[str] = []
    for rel_path in paths:
        source = repo_root / rel_path
        target = temp_root / rel_path
        if not source.exists():
            missing.append(rel_path)
            continue
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)
    return missing


def _replace_required(path: pathlib.Path, token: str, replacement: str) -> None:
    text = path.read_text(encoding="utf-8")
    if token not in text:
        raise ValueError(f"{path} does not contain mutation token: {token}")
    path.write_text(text.replace(token, replacement), encoding="utf-8")


def _write_required(path: pathlib.Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def _remove_required_gate(path: pathlib.Path, gate_id: str) -> None:
    data = json.loads(path.read_text(encoding="utf-8"))
    gates = data.get("required_gates", [])
    if gate_id not in gates:
        raise ValueError(f"{path} does not contain required gate: {gate_id}")
    data["required_gates"] = [gate for gate in gates if gate != gate_id]
    path.write_text(json.dumps(data, indent=2, sort_keys=False) + "\n", encoding="utf-8")


def _run_gate(
    repo_root: pathlib.Path,
    temp_root: pathlib.Path,
    scenario: NonVacuityScenario,
    timeout_seconds: int,
) -> subprocess.CompletedProcess[str]:
    script = repo_root / "transformfit-harness" / scenario.gate_script
    command = [sys.executable, str(script)]
    for arg in scenario.gate_args:
        command.append(str(temp_root) if arg == "{temp_root}" else arg.format(temp_root=temp_root))
    return subprocess.run(
        command,
        cwd=str(repo_root),
        capture_output=True,
        text=True,
        timeout=timeout_seconds,
        check=False,
    )


def _scenario_result(
    repo_root: pathlib.Path,
    scenario: NonVacuityScenario,
    timeout_seconds: int,
) -> dict[str, object]:
    with tempfile.TemporaryDirectory(prefix=f"transformfit-nonvacuity-{scenario.scenario_id}-") as temp_dir:
        temp_root = pathlib.Path(temp_dir)
        missing = _copy_paths(repo_root, temp_root, scenario.copy_paths)
        if missing:
            return {
                "id": scenario.scenario_id,
                "verdict": "RED",
                "failure": f"missing source files for copied fixture: {missing}",
            }

        clean = _run_gate(repo_root, temp_root, scenario, timeout_seconds)
        if clean.returncode != 0:
            return {
                "id": scenario.scenario_id,
                "verdict": "RED",
                "failure": "clean fixture did not pass before planted failure",
                "clean_exit": clean.returncode,
                "clean_stdout_tail": clean.stdout[-2000:],
                "clean_stderr_tail": clean.stderr[-2000:],
            }

        mutation_file = temp_root / scenario.mutation_path
        try:
            scenario.mutation(mutation_file)
        except Exception as exc:  # fail-closed: mutation failure means no non-vacuity proof.
            return {
                "id": scenario.scenario_id,
                "verdict": "RED",
                "failure": f"failed to plant mutation: {exc}",
            }

        planted = _run_gate(repo_root, temp_root, scenario, timeout_seconds)
        planted_output = f"{planted.stdout}\n{planted.stderr}"
        if planted.returncode == 0:
            return {
                "id": scenario.scenario_id,
                "verdict": "RED",
                "failure": "planted failure escaped; gate stayed GREEN",
                "planted_exit": planted.returncode,
                "planted_stdout_tail": planted.stdout[-2000:],
                "planted_stderr_tail": planted.stderr[-2000:],
            }
        if scenario.expected_failure_fragment not in planted_output:
            return {
                "id": scenario.scenario_id,
                "verdict": "RED",
                "failure": "planted failure turned RED but did not report the expected failure fragment",
                "expected_failure_fragment": scenario.expected_failure_fragment,
                "planted_exit": planted.returncode,
                "planted_stdout_tail": planted.stdout[-2000:],
                "planted_stderr_tail": planted.stderr[-2000:],
            }

        return {
            "id": scenario.scenario_id,
            "verdict": "GREEN",
            "clean_exit": clean.returncode,
            "planted_exit": planted.returncode,
            "expected_failure_fragment": scenario.expected_failure_fragment,
        }


def _scenarios() -> list[NonVacuityScenario]:
    return [
        NonVacuityScenario(
            scenario_id="five_star_trust_milestone_missing",
            gate_script="five_star_experience_gate.py",
            gate_args=("--repo-root", "{temp_root}", "--json"),
            copy_paths=tuple(
                COMMON_ROUTE_FILES
                + [
                    "lib/features/reviews/five_star_experience.dart",
                    "lib/app_providers.dart",
                    "lib/features/coaching/coach_command_center.dart",
                    "lib/features/coaching/coach_command_screen.dart",
                    "test/features/reviews/five_star_experience_test.dart",
                    "test/features/coaching/coach_command_center_test.dart",
                    "test/features/coaching/coach_command_screen_test.dart",
                ]
            ),
            mutation_path="lib/features/coaching/coach_command_screen.dart",
            mutation=lambda path: _replace_required(path, "Trust milestone", "Trust marker"),
            expected_failure_fragment="Trust milestone",
        ),
        NonVacuityScenario(
            scenario_id="coach_command_route_missing",
            gate_script="coach_command_center_gate.py",
            gate_args=("--repo-root", "{temp_root}", "--json"),
            copy_paths=tuple(
                COMMON_ROUTE_FILES
                + [
                    "lib/features/coaching/coach_command_center.dart",
                    "lib/features/coaching/coach_command_screen.dart",
                    "lib/app_providers.dart",
                    "lib/navigation/app_router.dart",
                    "lib/screens/today_screen.dart",
                    "test/features/coaching/coach_command_center_test.dart",
                    "test/features/coaching/coach_command_screen_test.dart",
                    "test/navigation/app_router_test.dart",
                    "test/today_screen_test.dart",
                ]
            ),
            mutation_path="lib/navigation/app_router.dart",
            mutation=lambda path: _replace_required(path, "path: '/coach'", "path: '/coachx'"),
            expected_failure_fragment="path: '/coach'",
        ),
        NonVacuityScenario(
            scenario_id="coach_command_center_clock_injection_removed",
            gate_script="coach_command_center_gate.py",
            gate_args=("--repo-root", "{temp_root}", "--json"),
            copy_paths=tuple(
                COMMON_ROUTE_FILES
                + [
                    "lib/features/coaching/coach_command_center.dart",
                    "lib/features/coaching/coach_command_screen.dart",
                    "lib/app_providers.dart",
                    "lib/navigation/app_router.dart",
                    "lib/screens/today_screen.dart",
                    "test/features/coaching/coach_command_center_test.dart",
                    "test/features/coaching/coach_command_screen_test.dart",
                    "test/navigation/app_router_test.dart",
                    "test/today_screen_test.dart",
                    "transformfit-harness/coach_command_center_gate.py",
                ]
            ),
            mutation_path="lib/features/coaching/coach_command_center.dart",
            mutation=lambda path: _replace_required(
                path,
                "buildBehavioralRepairLoop(state, now: now)",
                "buildBehavioralRepairLoop(state)",
            ),
            expected_failure_fragment="buildBehavioralRepairLoop(state, now: now)",
        ),
        NonVacuityScenario(
            scenario_id="coach_command_shared_header_removed",
            gate_script="coach_command_center_gate.py",
            gate_args=("--repo-root", "{temp_root}", "--json"),
            copy_paths=tuple(
                COMMON_ROUTE_FILES
                + [
                    "lib/features/coaching/coach_command_center.dart",
                    "lib/features/coaching/coach_command_screen.dart",
                    "lib/app_providers.dart",
                    "lib/navigation/app_router.dart",
                    "lib/screens/today_screen.dart",
                    "test/features/coaching/coach_command_center_test.dart",
                    "test/features/coaching/coach_command_screen_test.dart",
                    "test/navigation/app_router_test.dart",
                    "test/today_screen_test.dart",
                    "transformfit-harness/coach_command_center_gate.py",
                    "transformfit-harness/ship_gate_non_vacuity_gate.py",
                ]
            ),
            mutation_path="lib/features/coaching/coach_command_screen.dart",
            mutation=lambda path: _replace_required(
                path,
                "class _CoachPanelHeader",
                "class _CoachPanelHeading",
            ),
            expected_failure_fragment="coach_command_screen.dart missing token: class _CoachPanelHeader",
        ),
        NonVacuityScenario(
            scenario_id="workout_logger_progression_intent_missing",
            gate_script="workout_logger_intelligence_gate.py",
            gate_args=("--repo-root", "{temp_root}", "--json"),
            copy_paths=tuple(
                COMMON_ROUTE_FILES
                + [
                    "lib/features/session/models.dart",
                    "lib/features/session/session_controller.dart",
                    "lib/features/workout/set_intelligence.dart",
                    "lib/features/workout/active_workout_screen.dart",
                    "test/features/session/session_controller_test.dart",
                    "test/features/workout/set_intelligence_test.dart",
                    "test/features/workout/active_workout_screen_test.dart",
                    "transformfit-harness/workout_logger_sources.json",
                ]
            ),
            mutation_path="lib/features/workout/active_workout_screen.dart",
            mutation=lambda path: _replace_required(path, "Progression intent", "Progression plan"),
            expected_failure_fragment="Progression intent",
        ),
        NonVacuityScenario(
            scenario_id="workout_debrief_fabricated_field_planted",
            gate_script="workout_logger_intelligence_gate.py",
            gate_args=("--repo-root", "{temp_root}", "--json"),
            copy_paths=tuple(
                COMMON_ROUTE_FILES
                + [
                    "lib/features/session/models.dart",
                    "lib/features/session/session_controller.dart",
                    "lib/features/workout/set_intelligence.dart",
                    "lib/features/workout/active_workout_screen.dart",
                    "test/features/session/session_controller_test.dart",
                    "test/features/workout/set_intelligence_test.dart",
                    "test/features/workout/active_workout_screen_test.dart",
                    "transformfit-harness/workout_logger_sources.json",
                ]
            ),
            mutation_path="lib/features/workout/active_workout_screen.dart",
            mutation=lambda path: _replace_required(
                path,
                "satisfaction: result.satisfaction,",
                "satisfaction: 4,\n      whatWorked: 'Logged the work and kept the appointment.',",
            ),
            expected_failure_fragment=(
                "active_workout_screen.dart contains forbidden fabricated debrief token: "
                "Logged the work and kept the appointment."
            ),
        ),
        NonVacuityScenario(
            scenario_id="workout_active_plan_empty_clear_guard_planted",
            gate_script="workout_logger_intelligence_gate.py",
            gate_args=("--repo-root", "{temp_root}", "--json"),
            copy_paths=tuple(
                COMMON_ROUTE_FILES
                + [
                    "lib/features/session/models.dart",
                    "lib/features/session/session_controller.dart",
                    "lib/features/workout/set_intelligence.dart",
                    "lib/features/workout/active_workout_screen.dart",
                    "test/features/session/session_controller_test.dart",
                    "test/features/workout/set_intelligence_test.dart",
                    "test/features/workout/active_workout_screen_test.dart",
                    "transformfit-harness/workout_logger_sources.json",
                ]
            ),
            mutation_path="lib/features/session/session_controller.dart",
            mutation=lambda path: _replace_required(
                path,
                "if (_state.activeSession == null) return;",
                "if (_state.activeSession == null || exercises.isEmpty) return;",
            ),
            expected_failure_fragment=(
                "session_controller.dart contains forbidden stale plan-clear guard: "
                "if (_state.activeSession == null || exercises.isEmpty) return;"
            ),
        ),
        NonVacuityScenario(
            scenario_id="workout_effort_units_timed_work_removed",
            gate_script="workout_logger_intelligence_gate.py",
            gate_args=("--repo-root", "{temp_root}", "--json"),
            copy_paths=tuple(
                COMMON_ROUTE_FILES
                + [
                    "lib/features/session/models.dart",
                    "lib/features/session/session_controller.dart",
                    "lib/features/workout/set_intelligence.dart",
                    "lib/features/workout/active_workout_screen.dart",
                    "test/features/session/session_controller_test.dart",
                    "test/features/workout/set_intelligence_test.dart",
                    "test/features/workout/active_workout_screen_test.dart",
                    "transformfit-harness/workout_logger_sources.json",
                ]
            ),
            mutation_path="lib/features/session/models.dart",
            mutation=lambda path: _replace_required(
                path,
                "s.durationSeconds! / 30.0",
                "0.0",
            ),
            expected_failure_fragment=(
                "models.dart missing rest timing token: s.durationSeconds! / 30.0"
            ),
        ),
        NonVacuityScenario(
            scenario_id="progress_summary_wall_clock_anchor_removed",
            gate_script="fitness_agent_review_swarm_gate.py",
            gate_args=(
                "{temp_root}/transformfit-harness/fitness_agent_review_swarm.json",
                "--repo-root",
                "{temp_root}",
                "--json",
            ),
            copy_paths=tuple(
                COMMON_ROUTE_FILES
                + [
                    "lib/navigation/app_router.dart",
                    "lib/features/progress/progress_summary.dart",
                    "test/features/progress/progress_summary_test.dart",
                    "lib/features/onboarding/plan_reveal_controller.dart",
                    "test/features/onboarding/plan_reveal_real_wiring_test.dart",
                    "transformfit-harness/fitness_agent_review_swarm.json",
                    "transformfit-harness/fitness_agent_review_swarm_gate.py",
                    "transformfit-harness/testsprite_full_user_testing.json",
                    "transformfit-harness/ship_gate_non_vacuity_gate.py",
                ]
            ),
            mutation_path="lib/features/progress/progress_summary.dart",
            mutation=lambda path: _replace_required(
                path,
                "final anchorDay = _dateOnly(now ?? DateTime.now());",
                "final anchorDay = _dateOnly(completed.last.startedAt);",
            ),
            expected_failure_fragment=(
                "progress_summary.dart must not anchor current week to latest completed session"
            ),
        ),
        NonVacuityScenario(
            scenario_id="plan_reveal_malformed_remote_payload_defaulting_planted",
            gate_script="fitness_agent_review_swarm_gate.py",
            gate_args=(
                "{temp_root}/transformfit-harness/fitness_agent_review_swarm.json",
                "--repo-root",
                "{temp_root}",
                "--json",
            ),
            copy_paths=tuple(
                COMMON_ROUTE_FILES
                + [
                    "lib/navigation/app_router.dart",
                    "lib/features/progress/progress_summary.dart",
                    "test/features/progress/progress_summary_test.dart",
                    "lib/features/onboarding/plan_reveal_controller.dart",
                    "test/features/onboarding/plan_reveal_real_wiring_test.dart",
                    "transformfit-harness/fitness_agent_review_swarm.json",
                    "transformfit-harness/fitness_agent_review_swarm_gate.py",
                    "transformfit-harness/testsprite_full_user_testing.json",
                    "transformfit-harness/ship_gate_non_vacuity_gate.py",
                ]
            ),
            mutation_path="lib/features/onboarding/plan_reveal_controller.dart",
            mutation=lambda path: _replace_required(
                path,
                "_requiredPlanString(e['name'], '$exercisePath.name')",
                "(e['name'] as String?) ?? ''",
            ),
            expected_failure_fragment=(
                "plan_reveal_controller.dart must not default missing remote plan fields"
            ),
        ),
        NonVacuityScenario(
            scenario_id="body_composition_adherence_wall_clock_anchor_removed",
            gate_script="body_composition_trust_gate.py",
            gate_args=("--repo-root", "{temp_root}", "--json"),
            copy_paths=tuple(
                COMMON_ROUTE_FILES
                + [
                    "lib/features/body_composition/body_composition_trust.dart",
                    "lib/features/body_composition/body_composition_screen.dart",
                    "lib/navigation/app_router.dart",
                    "lib/screens/today_screen.dart",
                    "lib/features/progress/progress_screen.dart",
                    "lib/screens/profile_screen.dart",
                    "test/features/body_composition/body_composition_trust_test.dart",
                    "test/features/body_composition/body_composition_screen_test.dart",
                    "test/features/progress/progress_screen_test.dart",
                    "test/today_screen_test.dart",
                    "test/navigation/app_router_test.dart",
                    "transformfit-harness/body_composition_sources.json",
                    "transformfit-harness/body_composition_trust_gate.py",
                    "transformfit-harness/ship_gate_non_vacuity_gate.py",
                ]
            ),
            mutation_path="lib/features/body_composition/body_composition_trust.dart",
            mutation=lambda path: _replace_required(
                path,
                "final anchorDay = _dateOnly(now ?? DateTime.now());",
                "final anchorDay = _dateOnly(completedSessions.last.startedAt);",
            ),
            expected_failure_fragment=(
                "body_composition_trust.dart must not anchor adherence to latest completed session"
            ),
        ),
        NonVacuityScenario(
            scenario_id="coach_active_session_precedence_reversed",
            gate_script="coaching_runtime_gate.py",
            gate_args=("--repo-root", "{temp_root}", "--json"),
            copy_paths=tuple(
                COMMON_ROUTE_FILES
                + [
                    "lib/features/coaching/coach_signal.dart",
                    "lib/features/coaching/coach_quality_eval.dart",
                    "lib/features/workout/active_workout_screen.dart",
                    "lib/app_providers.dart",
                    "lib/screens/today_screen.dart",
                    "test/features/coaching/coach_signal_test.dart",
                    "test/features/coaching/coach_quality_eval_test.dart",
                    "test/features/workout/active_workout_screen_test.dart",
                    "test/today_screen_test.dart",
                    "transformfit-harness/coaching_runtime_gate.py",
                ]
            ),
            mutation_path="lib/features/coaching/coach_signal.dart",
            mutation=lambda path: _replace_required(
                path,
                """  if (state.activeSession != null) {
    return _liveSessionGuidance(state);
  }

  final historicalRiskSignal = _historicalRiskSignal(state);
  if (historicalRiskSignal != null) return historicalRiskSignal;""",
                """  final historicalRiskSignal = _historicalRiskSignal(state);
  if (historicalRiskSignal != null) return historicalRiskSignal;

  if (state.activeSession != null) {
    return _liveSessionGuidance(state);
  }""",
            ),
            expected_failure_fragment=(
                "coach_signal.dart must keep active-session guidance before historical risk/progress interpretation"
            ),
        ),
        NonVacuityScenario(
            scenario_id="coach_shared_effort_classifier_removed",
            gate_script="coaching_runtime_gate.py",
            gate_args=("--repo-root", "{temp_root}", "--json"),
            copy_paths=tuple(
                COMMON_ROUTE_FILES
                + [
                    "lib/features/coaching/coach_signal.dart",
                    "lib/features/coaching/coach_quality_eval.dart",
                    "lib/features/workout/active_workout_screen.dart",
                    "lib/app_providers.dart",
                    "lib/screens/today_screen.dart",
                    "test/features/coaching/coach_signal_test.dart",
                    "test/features/coaching/coach_quality_eval_test.dart",
                    "test/features/workout/active_workout_screen_test.dart",
                    "test/today_screen_test.dart",
                    "transformfit-harness/coaching_runtime_gate.py",
                    "transformfit-harness/ship_gate_non_vacuity_gate.py",
                ]
            ),
            mutation_path="lib/features/coaching/coach_signal.dart",
            mutation=lambda path: _replace_required(
                path,
                "enum _EffortRiskKind { none, coasting, overreaching }",
                "enum _EffortRiskKind { none, soft, overreaching }",
            ),
            expected_failure_fragment="coach_signal.dart missing shared effort classifier token",
        ),
        NonVacuityScenario(
            scenario_id="value_before_auth_first_open_redirect_removed",
            gate_script="value_before_auth_gate.py",
            gate_args=("--repo-root", "{temp_root}", "--json"),
            copy_paths=tuple(
                COMMON_ROUTE_FILES
                + [
                    "lib/navigation/app_router.dart",
                    "lib/features/onboarding/landing_screen.dart",
                    "test/navigation/app_router_test.dart",
                    "test/widget_test.dart",
                    "test/features/onboarding/landing_screen_test.dart",
                    "transformfit-harness/value_before_auth_gate.py",
                    "transformfit-harness/ship_gate_non_vacuity_gate.py",
                ]
            ),
            mutation_path="lib/navigation/app_router.dart",
            mutation=lambda path: _replace_required(path, "return '/onboarding';", "return '/auth';"),
            expected_failure_fragment="return '/onboarding';",
        ),
        NonVacuityScenario(
            scenario_id="value_before_auth_stale_m1_onboarding_screen_recreated",
            gate_script="value_before_auth_gate.py",
            gate_args=("--repo-root", "{temp_root}", "--json"),
            copy_paths=tuple(
                COMMON_ROUTE_FILES
                + [
                    "lib/navigation/app_router.dart",
                    "lib/features/onboarding/landing_screen.dart",
                    "test/navigation/app_router_test.dart",
                    "test/widget_test.dart",
                    "test/features/onboarding/landing_screen_test.dart",
                    "transformfit-harness/value_before_auth_gate.py",
                    "transformfit-harness/ship_gate_non_vacuity_gate.py",
                ]
            ),
            mutation_path="lib/screens/onboarding_screen.dart",
            mutation=lambda path: _write_required(
                path,
                "class OnboardingScreen {}\n",
            ),
            expected_failure_fragment=(
                "stale M1 onboarding screen must be removed or dev-only gated: "
                "lib/screens/onboarding_screen.dart"
            ),
        ),
        NonVacuityScenario(
            scenario_id="first_session_handoff_remote_completion_block_removed",
            gate_script="first_session_handoff_gate.py",
            gate_args=("--repo-root", "{temp_root}", "--json"),
            copy_paths=tuple(
                COMMON_ROUTE_FILES
                + [
                    "lib/features/onboarding/first_session_handoff_screen.dart",
                    "test/features/onboarding/first_session_handoff_test.dart",
                    "transformfit-harness/first_session_handoff_gate.py",
                    "transformfit-harness/ship_gate_non_vacuity_gate.py",
                ]
            ),
            mutation_path="lib/features/onboarding/first_session_handoff_screen.dart",
            mutation=lambda path: _replace_required(
                path,
                "unawaited(",
                "await ",
            ),
            expected_failure_fragment="unawaited(",
        ),
        NonVacuityScenario(
            scenario_id="first_session_handoff_limitations_as_soreness_planted",
            gate_script="first_session_handoff_gate.py",
            gate_args=("--repo-root", "{temp_root}", "--json"),
            copy_paths=tuple(
                COMMON_ROUTE_FILES
                + [
                    "lib/features/onboarding/first_session_handoff_screen.dart",
                    "test/features/onboarding/first_session_handoff_test.dart",
                    "transformfit-harness/first_session_handoff_gate.py",
                    "transformfit-harness/ship_gate_non_vacuity_gate.py",
                ]
            ),
            mutation_path="lib/features/onboarding/first_session_handoff_screen.dart",
            mutation=lambda path: _replace_required(
                path,
                "sorenessMap: const [],",
                "sorenessMap: intake.limitations,",
            ),
            expected_failure_fragment=(
                "first-session handoff fabricates soreness from non-soreness input"
            ),
        ),
        NonVacuityScenario(
            scenario_id="first_session_handoff_pending_onboarding_clear_removed",
            gate_script="first_session_handoff_gate.py",
            gate_args=("--repo-root", "{temp_root}", "--json"),
            copy_paths=tuple(
                COMMON_ROUTE_FILES
                + [
                    "lib/features/onboarding/first_session_handoff_screen.dart",
                    "lib/features/onboarding/plan_reveal_controller.dart",
                    "test/features/onboarding/first_session_handoff_test.dart",
                    "transformfit-harness/first_session_handoff_gate.py",
                    "transformfit-harness/ship_gate_non_vacuity_gate.py",
                ]
            ),
            mutation_path="lib/features/onboarding/first_session_handoff_screen.dart",
            mutation=lambda path: _replace_required(
                path,
                "ref.read(pendingIntakeProvider.notifier).clear();",
                "// pending intake clear removed",
            ),
            expected_failure_fragment="ref.read(pendingIntakeProvider.notifier).clear();",
        ),
        NonVacuityScenario(
            scenario_id="plan_reveal_question_sanitizer_removed",
            gate_script="ux_ui_research_ingestion_gate.py",
            gate_args=(
                "{temp_root}/transformfit-harness/ux_ui_research_ingestion.json",
                "--competitive-ledger",
                "{temp_root}/transformfit-harness/competitive_reverse_engineering.json",
                "--coaching-harness",
                "{temp_root}/transformfit-harness/coaching_harness.json",
                "--repo-root",
                "{temp_root}",
                "--json",
            ),
            copy_paths=tuple(
                COMMON_ROUTE_FILES
                + [
                    "transformfit-harness/ux_ui_research_ingestion.json",
                    "transformfit-harness/competitive_reverse_engineering.json",
                    "transformfit-harness/coaching_harness.json",
                    "lib/features/onboarding/welcome_screen.dart",
                    "lib/features/onboarding/intake_screen.dart",
                    "lib/features/onboarding/plan_reveal_screen.dart",
                    "lib/screens/today_screen.dart",
                    "lib/features/workout/active_workout_screen.dart",
                    "lib/features/progress/progress_screen.dart",
                    "lib/features/proof/proof_card_screen.dart",
                    "lib/screens/profile_screen.dart",
                    "lib/features/proof/proof_card.dart",
                    "test/features/proof/proof_card_test.dart",
                    "test/features/proof/proof_card_screen_test.dart",
                    "lib/features/onboarding/plan_reveal_controller.dart",
                    "test/features/onboarding/plan_reveal_real_wiring_test.dart",
                    "supabase/functions/_shared/llm.ts",
                    "supabase/functions/_shared/llm_test.ts",
                    "transformfit-harness/ux_ui_research_ingestion_gate.py",
                    "transformfit-harness/ship_gate_non_vacuity_gate.py",
                ]
            ),
            mutation_path="lib/features/onboarding/plan_reveal_controller.dart",
            mutation=lambda path: _replace_required(
                path,
                "replaceAll(RegExp(r'\\?'), '')",
                "replaceAll(RegExp(r'\\s+'), ' ')",
            ),
            expected_failure_fragment="plan reveal sanitizer controller missing parity token",
        ),
        NonVacuityScenario(
            scenario_id="accessibility_low_end_proof_large_text_removed",
            gate_script="accessibility_low_end_device_gate.py",
            gate_args=("--repo-root", "{temp_root}", "--json"),
            copy_paths=tuple(
                COMMON_ROUTE_FILES
                + [
                    "lib/screens/today_screen.dart",
                    "lib/features/workout/active_workout_screen.dart",
                    "lib/features/proof/proof_card_screen.dart",
                    "lib/features/progress/progress_screen.dart",
                    "lib/screens/auth_screen.dart",
                    "lib/features/onboarding/landing_screen.dart",
                    "test/today_screen_test.dart",
                    "test/features/workout/active_workout_screen_test.dart",
                    "test/features/proof/proof_card_screen_test.dart",
                    "test/features/progress/progress_screen_test.dart",
                    "test/features/auth/auth_screen_test.dart",
                    "test/features/onboarding/landing_screen_test.dart",
                    "test/navigation/app_router_test.dart",
                    "transformfit-harness/accessibility_low_end_device_gate.py",
                    "transformfit-harness/ship_gate_non_vacuity_gate.py",
                ]
            ),
            mutation_path="test/features/proof/proof_card_screen_test.dart",
            mutation=lambda path: _replace_required(
                path,
                "proof card sharing controls survive narrow large-text viewport",
                "proof card sharing controls render",
            ),
            expected_failure_fragment=(
                "proof card sharing controls survive narrow large-text viewport"
            ),
        ),
        NonVacuityScenario(
            scenario_id="perf_frame_budget_route_budget_removed",
            gate_script="perf_frame_budget_gate.py",
            gate_args=("--repo-root", "{temp_root}", "--json"),
            copy_paths=tuple(
                COMMON_ROUTE_FILES
                + [
                    "lib/main.dart",
                    "lib/navigation/app_router.dart",
                    "test/performance/frame_budget_test.dart",
                    "transformfit-harness/perf_frame_budget_gate.py",
                    "transformfit-harness/ship_gate_non_vacuity_gate.py",
                ]
            ),
            mutation_path="test/performance/frame_budget_test.dart",
            mutation=lambda path: _replace_required(
                path,
                "const _transitionBudgetMs = 800;",
                "const _transitionBudgetMs = 1200;",
            ),
            expected_failure_fragment="const _transitionBudgetMs = 800;",
        ),
        NonVacuityScenario(
            scenario_id="wearable_adapter_provider_removed",
            gate_script="wearable_dai_interface_gate.py",
            gate_args=("--repo-root", "{temp_root}"),
            copy_paths=tuple(
                COMMON_ROUTE_FILES
                + [
                    "lib/features/wearables/wearable_signal.dart",
                    "lib/features/wearables/health_wearable_adapter.dart",
                    "lib/features/coaching/dai_interface.dart",
                    "lib/features/session/session_controller.dart",
                    "lib/app_providers.dart",
                    "lib/screens/today_screen.dart",
                    "test/features/wearables/wearable_signal_test.dart",
                    "test/features/wearables/health_wearable_adapter_test.dart",
                    "test/features/coaching/dai_interface_test.dart",
                    "test/features/session/session_controller_test.dart",
                    "test/today_screen_test.dart",
                    "transformfit-harness/wearable_dai_sources.json",
                    "pubspec.yaml",
                    "android/app/src/main/AndroidManifest.xml",
                    "android/app/src/main/kotlin/com/rigintelligence/transformfitai/MainActivity.kt",
                    "android/gradle.properties",
                    "ios/Runner/Info.plist",
                    "ios/Runner/Runner.entitlements",
                    "ios/Runner.xcodeproj/project.pbxproj",
                ]
            ),
            mutation_path="lib/app_providers.dart",
            mutation=lambda path: _replace_required(
                path,
                "wearableSyncAdapterProvider",
                "wearableLocalSampleProvider",
            ),
            expected_failure_fragment="wearableSyncAdapterProvider",
        ),
        NonVacuityScenario(
            scenario_id="wearable_adapter_automatic_filter_planted",
            gate_script="wearable_dai_interface_gate.py",
            gate_args=("--repo-root", "{temp_root}"),
            copy_paths=tuple(
                COMMON_ROUTE_FILES
                + [
                    "lib/features/wearables/wearable_signal.dart",
                    "lib/features/wearables/health_wearable_adapter.dart",
                    "lib/features/coaching/dai_interface.dart",
                    "lib/features/session/session_controller.dart",
                    "lib/app_providers.dart",
                    "lib/screens/today_screen.dart",
                    "test/features/wearables/wearable_signal_test.dart",
                    "test/features/wearables/health_wearable_adapter_test.dart",
                    "test/features/coaching/dai_interface_test.dart",
                    "test/features/session/session_controller_test.dart",
                    "test/today_screen_test.dart",
                    "transformfit-harness/wearable_dai_sources.json",
                    "pubspec.yaml",
                    "android/app/src/main/AndroidManifest.xml",
                    "android/app/src/main/kotlin/com/rigintelligence/transformfitai/MainActivity.kt",
                    "android/gradle.properties",
                    "ios/Runner/Info.plist",
                    "ios/Runner/Runner.entitlements",
                    "ios/Runner.xcodeproj/project.pbxproj",
                ]
            ),
            mutation_path="lib/features/wearables/health_wearable_adapter.dart",
            mutation=lambda path: _replace_required(
                path,
                "  RecordingMethod.manual,\n];",
                "  RecordingMethod.manual,\n  RecordingMethod.automatic,\n];",
            ),
            expected_failure_fragment=(
                "health_wearable_adapter.dart must not filter automatic wearable data"
            ),
        ),
        NonVacuityScenario(
            scenario_id="war_room_required_gate_removed",
            gate_script="two_day_war_room_gate.py",
            gate_args=("{temp_root}/transformfit-harness/two_day_war_room.json", "--json"),
            copy_paths=("transformfit-harness/two_day_war_room.json",),
            mutation_path="transformfit-harness/two_day_war_room.json",
            mutation=lambda path: _remove_required_gate(path, "ship_gate_non_vacuity_gate"),
            expected_failure_fragment="ship_gate_non_vacuity_gate",
        ),
    ]


def run(repo_root: pathlib.Path, timeout_seconds: int) -> dict[str, object]:
    failures: list[str] = []
    ship_gate = _read(repo_root / "transformfit-harness/ship_gate.sh")
    bridge = _read(repo_root / "transformfit-harness/bridge.json")
    war_room = _read(repo_root / "transformfit-harness/two_day_war_room.json")
    war_room_gate = _read(repo_root / "transformfit-harness/two_day_war_room_gate.py")

    for token in sorted(REQUIRED_SHIP_TOKENS):
        if token not in ship_gate:
            failures.append(f"ship_gate.sh missing non-vacuity token: {token}")
    for token in sorted(REQUIRED_BRIDGE_TOKENS):
        if token not in bridge:
            failures.append(f"bridge.json missing non-vacuity token: {token}")
    for token in sorted(REQUIRED_WAR_ROOM_TOKENS):
        if token not in war_room:
            failures.append(f"two_day_war_room.json missing non-vacuity token: {token}")
    for token in sorted(REQUIRED_WAR_ROOM_GATE_TOKENS):
        if token not in war_room_gate:
            failures.append(f"two_day_war_room_gate.py missing non-vacuity token: {token}")

    scenario_results = [
        _scenario_result(repo_root, scenario, timeout_seconds) for scenario in _scenarios()
    ]
    for result in scenario_results:
        if result.get("verdict") != "GREEN":
            failures.append(f"non-vacuity scenario failed: {result.get('id')}")

    return {
        "schema": "transformfit.ship_gate_non_vacuity_gate.v1",
        "repo_root": str(repo_root),
        "verdict": "GREEN" if not failures else "RED",
        "failures": failures,
        "scenario_count": len(scenario_results),
        "scenarios": scenario_results,
        "real_tree_mutated": False,
    }


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--repo-root",
        type=pathlib.Path,
        default=pathlib.Path("."),
        help="TransformFit Flutter repo root",
    )
    parser.add_argument("--timeout-seconds", type=int, default=30)
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args(argv)

    result = run(args.repo_root.resolve(), args.timeout_seconds)
    print(json.dumps(result, indent=2, sort_keys=True))
    return 0 if result["verdict"] == "GREEN" else 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
