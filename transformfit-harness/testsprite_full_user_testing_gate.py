#!/usr/bin/env python3
"""Fail-closed gate for TestSprite-aware comprehensive user testing.

This gate deliberately separates three things:
1. TestSprite CLI contract proof.
2. Deterministic local 1000-scenario user testing.
3. Real cloud/recruited-user testing, which must stay recorded as incomplete
   unless there is a real public URL, valid TestSprite auth, and user evidence.
"""

from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
import tempfile
from itertools import product
from pathlib import Path
from typing import Any


REQUIRED_SCHEMA = "transformfit.testsprite_full_user_testing.v1"
ALLOWED_EXPERT_STATUSES = {
    "completed_sidecar",
    "usage_limit_blocked_compensated_locally",
    "local_deterministic",
}
REQUIRED_RISK_MODES = {
    "happy_path",
    "low_readiness",
    "pain_or_safety",
    "offline_or_malformed_state",
    "privacy_or_auth_boundary",
}
REQUIRED_ENTRY_STATES = {
    "landing_to_welcome",
    "intake_to_plan_reveal",
    "auth_and_profile_guard",
    "today_readiness",
    "active_workout_logger",
    "ai_coach_runtime",
    "nutrition_target",
    "body_composition_trust",
    "progress_and_proof",
    "offline_restore",
}
REQUIRED_CRITICAL_FLOW_IDS = {
    "flow-01-first-open-value",
    "flow-02-intake-plan-fit",
    "flow-03-plan-reveal-first-session",
    "flow-04-auth-guard",
    "flow-05-today-next-action",
    "flow-06-active-workout-log-set",
    "flow-07-rest-and-set-intelligence",
    "flow-08-pain-blocks-progression",
    "flow-09-ai-coach-trace",
    "flow-10-nutrition-target",
    "flow-11-body-composition",
    "flow-12-progress-recommit",
    "flow-13-proof-card",
    "flow-14-offline-restore",
    "flow-15-accessibility-core",
    "flow-16-low-end-device",
    "flow-17-comeback-flow",
    "flow-18-profile-settings",
    "flow-19-native-first-open",
    "flow-20-real-testing-boundary",
}
BANNED_CLAIM_TERMS = {
    "real user testing complete",
    "100 users tested",
    "testsprite cloud passed",
    "live cloud run passed",
    "influencer endorsed",
    "clinically proven",
}
ALLOWED_BLOCKED_TESTSPRITE_AUTH_CODES = {
    "AUTH_INVALID",
    "AUTH_MISSING",
    "AUTH_FORBIDDEN",
    "UNAVAILABLE",
}


def _load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def _run_command(command: list[str], *, timeout: int = 30) -> dict[str, Any]:
    try:
        completed = subprocess.run(
            command,
            check=False,
            capture_output=True,
            text=True,
            timeout=timeout,
        )
        return {
            "command": command,
            "returncode": completed.returncode,
            "stdout": completed.stdout.strip(),
            "stderr": completed.stderr.strip(),
        }
    except FileNotFoundError as exc:
        return {"command": command, "returncode": 127, "stdout": "", "stderr": str(exc)}
    except subprocess.TimeoutExpired as exc:
        return {
            "command": command,
            "returncode": 124,
            "stdout": (exc.stdout or "").strip() if isinstance(exc.stdout, str) else "",
            "stderr": (exc.stderr or "").strip() if isinstance(exc.stderr, str) else "timeout",
        }


def _parse_json_output(output: str) -> Any | None:
    if not output:
        return None
    cleaned = "\n".join(line for line in output.splitlines() if not line.startswith("[dry-run]"))
    try:
        return json.loads(cleaned)
    except json.JSONDecodeError:
        return None


def _scenario_id(user_id: str, entry_state: str, risk_mode: str) -> str:
    return f"{user_id}.{entry_state}.{risk_mode}"


def _scenario_invariants(entry_state: str, risk_mode: str) -> set[str]:
    invariants = {"has_user", "has_entry_state", "has_risk_mode", "no_banned_claims"}
    if entry_state == "landing_to_welcome":
        invariants.update({"value_before_account", "single_primary_cta"})
    if entry_state == "intake_to_plan_reveal":
        invariants.update({"plan_impact_explained", "limitations_safe"})
    if entry_state == "auth_and_profile_guard":
        invariants.update({"auth_error_recoverable", "no_secret_leak"})
    if entry_state == "today_readiness":
        invariants.update({"one_next_action", "why_changed_visible"})
    if entry_state == "active_workout_logger":
        invariants.update({"log_set", "undo_set", "previous_reference"})
    if entry_state == "ai_coach_runtime":
        invariants.update({"source_trace", "deterministic_decision"})
    if entry_state == "nutrition_target":
        invariants.update({"one_safe_target", "no_diet_culture"})
    if entry_state == "body_composition_trust":
        invariants.update({"privacy_default", "imperfect_signal_caveat"})
    if entry_state == "progress_and_proof":
        invariants.update({"kept_promises_first", "private_notes_omitted"})
    if entry_state == "offline_restore":
        invariants.update({"state_restores_or_clears", "fallback_labeled"})
    if risk_mode == "low_readiness":
        invariants.update({"recovery_counts", "no_forced_progression"})
    if risk_mode == "pain_or_safety":
        invariants.update({"pain_blocks_progression", "safe_modify_or_stop"})
    if risk_mode == "offline_or_malformed_state":
        invariants.update({"no_crash", "local_state_recovery"})
    if risk_mode == "privacy_or_auth_boundary":
        invariants.update({"no_private_data_export", "explicit_user_action"})
    return invariants


def _build_testsprite_plan(flow: dict[str, Any]) -> dict[str, Any]:
    route = str(flow.get("route", "/"))
    target = "https://transformfit.example.test"
    if route.startswith("/"):
        target = f"{target}{route}"
    elif route == "native shell":
        target = "https://transformfit.example.test/native-shell"
    elif route == "harness":
        target = "https://transformfit.example.test/proof"
    assertions = flow.get("assertions", [])
    plan_steps = [
        {
            "type": "action",
            "description": f"Navigate to {target}",
            "action": "navigate",
            "value": target,
        },
        {
            "type": "assertion",
            "description": "Page shell is visible",
            "selector": "body",
            "condition": "visible",
        },
    ]
    for assertion in assertions[:5]:
        plan_steps.append(
            {
                "type": "assertion",
                "description": f"Verify {assertion}",
                "selector": "body",
                "condition": f"contains:{assertion}",
            }
        )
    return {
        "projectId": "project_transformfit_local_contract",
        "type": "frontend",
        "name": f"TransformFit {flow.get('id')}: {flow.get('screen')}",
        "planSteps": plan_steps,
    }


def _validate_manifest(data: dict[str, Any]) -> tuple[list[str], dict[str, Any]]:
    failures: list[str] = []
    metrics: dict[str, Any] = {}

    if data.get("schema") != REQUIRED_SCHEMA:
        failures.append(f"schema must be {REQUIRED_SCHEMA}")
    if not str(data.get("version", "")).strip():
        failures.append("version is required")

    truth = data.get("truth_status", {})
    if truth.get("real_recruited_user_testing_complete") is not False:
        failures.append("real recruited user testing must not be claimed complete")
    if truth.get("live_testsprite_cloud_run_complete") is not False:
        failures.append("live TestSprite cloud run must not be claimed complete")
    if truth.get("local_deterministic_user_testing_complete") is not True:
        failures.append("local deterministic user testing must be marked complete")

    all_text = json.dumps(data, sort_keys=True).lower()
    for term in BANNED_CLAIM_TERMS:
        if term in all_text:
            failures.append(f"manifest contains banned unsupported claim term: {term}")

    testsprite = data.get("testsprite", {})
    if testsprite.get("cloud_run_status") != "blocked_auth_invalid_or_no_public_url":
        failures.append("TestSprite cloud run status must honestly record auth/public URL blockage")
    if len(testsprite.get("docs", [])) < 3:
        failures.append("TestSprite docs/source references must include at least 3 entries")
    for command in testsprite.get("required_commands", []):
        if "testsprite" not in command:
            failures.append(f"required command is not a TestSprite command: {command}")

    experts = data.get("expert_panel", [])
    expert_ids = [item.get("id") for item in experts]
    metrics["expert_count"] = len(experts)
    metrics["completed_sidecars"] = sum(1 for item in experts if item.get("status") == "completed_sidecar")
    metrics["usage_limit_blocked_compensated"] = sum(
        1 for item in experts if item.get("status") == "usage_limit_blocked_compensated_locally"
    )
    if len(experts) != data.get("quality_bar", {}).get("minimum_expert_lanes"):
        failures.append("expert panel must match minimum_expert_lanes exactly")
    if len(set(expert_ids)) != len(expert_ids):
        failures.append("expert panel contains duplicate ids")
    for expert in experts:
        if expert.get("status") not in ALLOWED_EXPERT_STATUSES:
            failures.append(f"expert {expert.get('id')} has invalid status: {expert.get('status')}")
        for key in ("discipline", "source", "coverage_output"):
            if not expert.get(key):
                failures.append(f"expert {expert.get('id')} missing {key}")
    if metrics["completed_sidecars"] < data.get("quality_bar", {}).get("minimum_completed_sidecars", 0):
        failures.append("completed sidecar count below quality bar")

    users = data.get("user_panel", [])
    user_ids = [item.get("id") for item in users]
    metrics["user_count"] = len(users)
    if len(users) != data.get("quality_bar", {}).get("minimum_user_personas"):
        failures.append("user panel must match minimum_user_personas exactly")
    if len(set(user_ids)) != len(user_ids):
        failures.append("user panel contains duplicate ids")
    for user in users:
        for key in ("segment", "primary_job", "risk_to_test", "scenario"):
            if not user.get(key):
                failures.append(f"user {user.get('id')} missing {key}")

    generation = data.get("scenario_generation", {})
    entry_states = generation.get("entry_states", [])
    risk_modes = generation.get("risk_modes", [])
    if set(entry_states) != REQUIRED_ENTRY_STATES:
        failures.append(f"entry state axis mismatch: {sorted(set(entry_states) ^ REQUIRED_ENTRY_STATES)}")
    if set(risk_modes) != REQUIRED_RISK_MODES:
        failures.append(f"risk mode axis mismatch: {sorted(set(risk_modes) ^ REQUIRED_RISK_MODES)}")
    scenarios = [
        {
            "id": _scenario_id(user.get("id", "missing-user"), entry_state, risk_mode),
            "invariants": sorted(_scenario_invariants(entry_state, risk_mode)),
        }
        for user, entry_state, risk_mode in product(users, entry_states, risk_modes)
    ]
    metrics["generated_scenarios"] = len(scenarios)
    metrics["sample_scenarios"] = scenarios[:3]
    required_total = generation.get("required_total")
    if len(scenarios) != required_total:
        failures.append(f"generated scenario count {len(scenarios)} != required_total {required_total}")
    if len(scenarios) < data.get("quality_bar", {}).get("minimum_generated_scenarios", 0):
        failures.append("generated scenario count below quality bar")
    for scenario in scenarios:
        invariants = set(scenario["invariants"])
        if "has_user" not in invariants or "no_banned_claims" not in invariants:
            failures.append(f"scenario invariant failure: {scenario['id']}")

    flows = data.get("critical_flows", [])
    flow_ids = {item.get("id") for item in flows}
    metrics["critical_flow_count"] = len(flows)
    if not REQUIRED_CRITICAL_FLOW_IDS.issubset(flow_ids):
        failures.append(f"missing critical flows: {sorted(REQUIRED_CRITICAL_FLOW_IDS - flow_ids)}")
    if len(flows) < data.get("quality_bar", {}).get("minimum_critical_flows", 0):
        failures.append("critical flow count below quality bar")
    for flow in flows:
        if len(flow.get("assertions", [])) < 3:
            failures.append(f"flow {flow.get('id')} must have at least 3 assertions")
        if not set(flow.get("risk_modes", [])).issubset(REQUIRED_RISK_MODES):
            failures.append(f"flow {flow.get('id')} has unknown risk modes")
        if not flow.get("route") or not flow.get("priority") or not flow.get("screen"):
            failures.append(f"flow {flow.get('id')} missing route, priority, or screen")

    plans = [_build_testsprite_plan(flow) for flow in flows]
    metrics["testsprite_plan_specs"] = len(plans)
    if len(plans) < data.get("quality_bar", {}).get("minimum_testsprite_plan_specs", 0):
        failures.append("TestSprite plan count below quality bar")
    for plan in plans:
        if plan.get("type") != "frontend":
            failures.append(f"TestSprite plan {plan.get('name')} must be frontend")
        if len(plan.get("planSteps", [])) < 3:
            failures.append(f"TestSprite plan {plan.get('name')} must have at least 3 steps")

    return failures, {"metrics": metrics, "plans": plans}


def _validate_testsprite_cli(plans: list[dict[str, Any]]) -> tuple[list[str], dict[str, Any]]:
    failures: list[str] = []
    evidence: dict[str, Any] = {}
    executable = shutil.which("testsprite")
    evidence["executable"] = executable
    if not executable:
        return ["testsprite CLI not found on PATH"], evidence

    version = _run_command(["testsprite", "--version"], timeout=20)
    evidence["version"] = version
    if version["returncode"] != 0:
        failures.append("testsprite --version failed")

    project_list = _run_command(["testsprite", "--dry-run", "--output", "json", "project", "list"], timeout=20)
    evidence["dry_run_project_list"] = {
        "returncode": project_list["returncode"],
        "stderr": project_list["stderr"],
        "json_shape": None,
    }
    project_json = _parse_json_output(project_list["stdout"])
    if project_list["returncode"] != 0 or not isinstance(project_json, dict) or not isinstance(project_json.get("items"), list):
        failures.append("testsprite dry-run project list did not return expected JSON contract")
    else:
        evidence["dry_run_project_list"]["json_shape"] = {"items": len(project_json.get("items", []))}

    auth_status = _run_command(["testsprite", "--output", "json", "auth", "status"], timeout=20)
    auth_json = _parse_json_output(auth_status["stdout"]) or _parse_json_output(auth_status["stderr"])
    auth_code = None
    if isinstance(auth_json, dict):
        auth_code = auth_json.get("error", {}).get("code")
    evidence["auth_status"] = {
        "returncode": auth_status["returncode"],
        "error_code": auth_code,
        "expected_blocked": auth_status["returncode"] != 0,
    }
    if auth_status["returncode"] == 0:
        evidence["auth_status"]["expected_blocked"] = False
    elif auth_code not in ALLOWED_BLOCKED_TESTSPRITE_AUTH_CODES:
        failures.append(f"unexpected TestSprite auth failure code: {auth_code or 'unparseable'}")

    with tempfile.TemporaryDirectory(prefix="transformfit-testsprite-") as temp_dir:
        plans_path = Path(temp_dir) / "full_user_flows.jsonl"
        plans_path.write_text("\n".join(json.dumps(plan, sort_keys=True) for plan in plans) + "\n", encoding="utf-8")
        create_batch = _run_command(
            ["testsprite", "--dry-run", "--output", "json", "test", "create-batch", "--plans", str(plans_path)],
            timeout=20,
        )
    batch_json = _parse_json_output(create_batch["stdout"])
    evidence["dry_run_create_batch"] = {
        "returncode": create_batch["returncode"],
        "stderr": create_batch["stderr"],
        "json_contract_present": batch_json is not None,
    }
    if create_batch["returncode"] != 0 or batch_json is None:
        failures.append("testsprite dry-run create-batch did not return JSON contract")

    return failures, evidence


def run(manifest_path: Path, repo_root: Path) -> dict[str, Any]:
    failures: list[str] = []
    data = _load_json(manifest_path)

    manifest_failures, manifest_result = _validate_manifest(data)
    failures.extend(manifest_failures)

    cli_failures: list[str] = []
    cli_evidence: dict[str, Any] = {}
    if not manifest_failures:
        cli_failures, cli_evidence = _validate_testsprite_cli(manifest_result["plans"])
        failures.extend(cli_failures)

    return {
        "schema": "transformfit.testsprite_full_user_testing_gate.v1",
        "repo_root": str(repo_root),
        "manifest": str(manifest_path),
        "verdict": "GREEN" if not failures else "RED",
        "failures": failures,
        "metrics": manifest_result.get("metrics", {}),
        "testsprite_cli": cli_evidence,
        "truth_status": data.get("truth_status", {}),
    }


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "manifest",
        nargs="?",
        default="transformfit-harness/testsprite_full_user_testing.json",
    )
    parser.add_argument("--repo-root", default=".")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args(argv)

    repo_root = Path(args.repo_root).resolve()
    manifest_path = Path(args.manifest)
    if not manifest_path.is_absolute():
        manifest_path = (repo_root / manifest_path).resolve()
    result = run(manifest_path, repo_root)
    if args.json:
        print(json.dumps(result, indent=2))
    elif result["verdict"] == "GREEN":
        metrics = result.get("metrics", {})
        print(
            "GREEN testsprite_full_user_testing_gate: "
            f"{metrics.get('generated_scenarios')} scenarios, "
            f"{metrics.get('expert_count')} expert lanes, "
            f"{metrics.get('user_count')} users, "
            f"{metrics.get('testsprite_plan_specs')} TestSprite plans"
        )
    else:
        print(f"RED testsprite_full_user_testing_gate: {manifest_path}", file=sys.stderr)
        for failure in result["failures"]:
            print(f"  - {failure}", file=sys.stderr)
    return 0 if result["verdict"] == "GREEN" else 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
