#!/usr/bin/env python3
"""Fail-closed gate for the TransformFit fitness-agent review swarm."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any


REQUIRED_SCHEMA = "transformfit.fitness_agent_review_swarm.v1"
REQUIRED_AGENT_SLUGS = {
    "voltagent-multi-agent-coordinator",
    "codex-repo-cartographer",
    "agency-code-reviewer",
    "voltagent-flutter-expert",
    "agency-mobile-app-builder",
    "voltagent-mobile-developer",
    "rig-backend-architect",
    "rig-security-engineer",
    "voltagent-ai-engineer",
    "agency-model-qa-specialist",
    "agency-data-privacy-officer",
    "agency-behavioral-nudge-engine",
    "voltagent-ui-ux-tester",
    "voltagent-accessibility-tester",
    "voltagent-ui-designer",
    "voltagent-ux-researcher",
    "voltagent-product-manager",
    "agency-performance-benchmarker",
    "codex-verification-lab",
    "agency-workflow-architect",
}
REQUIRED_REVIEW_TRACKS = {
    "track-full-code-review",
    "track-refactoring",
    "track-agent-testing",
    "track-ui-testing",
}
REQUIRED_CUSTOM_AGENT_GAPS = {
    "flutter-native-release-parity-reviewer",
    "wearable-data-integrity-auditor",
    "strength-programming-auditor",
    "nutrition-body-composition-safety-reviewer",
    "ai-health-coach-safety-evaluator",
}
REQUIRED_SHIP_TOKENS = {
    "FITNESS_AGENT_REVIEW_SWARM_GATE",
    "Tier-1 20/27: fitness_agent_review_swarm_gate",
    "Tier-1 21/27: two_day_war_room_gate",
    "fitness_agent_review_swarm_gate",
}
ALLOWED_NON_ROUTE_TARGETS = {"native shell", "harness"}
STALE_ROUTE_TOKENS = {"/workout/active", "/onboarding/plan\""}
BANNED_CLAIM_TERMS = {
    "human testing complete",
    "testsprite cloud passed",
    "endorsed",
}
REQUIRED_PROGRESS_SUMMARY_TOKENS = {
    "ProgressSummary buildProgressSummary(SessionState state, {DateTime? now})",
    "final anchorDay = _dateOnly(now ?? DateTime.now());",
    "subhead: 'Last 7 days anchored to today.'",
}
REQUIRED_PROGRESS_TEST_TOKENS = {
    "progress current week uses wall-clock today, not stale latest session",
    "now: DateTime(2026, 7, 20)",
    "expect(summary.currentWeekSessions, 0);",
    "expect(summary.previousWeekSessions, 0);",
    "expect(summary.coachCue, 'Choose one low-friction action today.');",
}
REQUIRED_PLAN_REVEAL_VALIDATION_TOKENS = {
    "typedef PlanRevealRemoteInvoker",
    "planRevealRemoteInvokerProvider",
    "_requiredPlanObject(responseData, 'generate-plan response')",
    "_requiredPlanObject(data['plan'], 'generate-plan plan')",
    "_requiredPlanString(e['id'], '$exercisePath.id')",
    "_requiredPlanString(e['name'], '$exercisePath.name')",
    "d['dayNumber'],",
    "'$dayPath.dayNumber',",
    "throw FormatException('$path must be a non-empty string');",
    "plan.days must include at least one day",
}
REQUIRED_PLAN_REVEAL_VALIDATION_TEST_TOKENS = {
    "malformed remote plan payload falls back instead",
    "of defaulting missing ids names and days",
    "planRevealRemoteInvokerProvider.overrideWithValue",
    "'model_used': 'remote-malformed-test'",
    "expect(find.bySemanticsLabel('Fallback indicator'), findsOneWidget);",
    "expect(find.textContaining('Remote malformed headline'), findsNothing);",
}
FORBIDDEN_PLAN_REVEAL_DEFAULT_TOKENS = {
    "(e['id'] as String?) ?? ''",
    "(e['name'] as String?) ?? ''",
    "(d['dayNumber'] as num?)?.toInt() ?? 1",
    "(d['exercises'] as List? ?? [])",
    "(json['daysPerWeek'] as num?)?.toInt() ?? 3",
}


def _load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def _read_text(path: Path, failures: list[str], label: str) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except FileNotFoundError:
        failures.append(f"{label} missing: {path}")
        return ""


def _fail_if(failures: list[str], condition: bool, message: str) -> None:
    if not condition:
        failures.append(message)


def _slugs(items: list[dict[str, Any]]) -> set[str]:
    return {str(item.get("slug", "")).strip() for item in items if isinstance(item, dict)}


def _actual_routes(repo_root: Path) -> set[str]:
    router = repo_root / "lib/navigation/app_router.dart"
    text = router.read_text(encoding="utf-8")
    paths = re.findall(r"path:\s*'([^']+)'", text)
    routes: set[str] = set()
    for path in paths:
        if path.startswith("/"):
            routes.add(path)
        else:
            routes.add(f"/onboarding/{path}")
    return routes


def _validate_route_contract(repo_root: Path, failures: list[str]) -> dict[str, Any]:
    routes = _actual_routes(repo_root)
    manifest = _load_json(repo_root / "transformfit-harness/testsprite_full_user_testing.json")
    flow_routes = {
        str(flow.get("id")): str(flow.get("route"))
        for flow in manifest.get("critical_flows", [])
        if isinstance(flow, dict)
    }
    for flow_id, route in flow_routes.items():
        if route in ALLOWED_NON_ROUTE_TARGETS:
            continue
        _fail_if(failures, route in routes, f"critical flow {flow_id} route {route!r} is not in app_router.dart")
    all_routes_text = json.dumps(flow_routes)
    for stale in STALE_ROUTE_TOKENS:
        _fail_if(failures, stale not in all_routes_text, f"stale TestSprite route remains: {stale}")
    return {"actual_routes": sorted(routes), "critical_flow_routes": flow_routes}


def run(artifact: Path, repo_root: Path) -> dict[str, Any]:
    failures: list[str] = []
    data = _load_json(artifact)

    _fail_if(failures, data.get("schema") == REQUIRED_SCHEMA, f"schema must be {REQUIRED_SCHEMA}")
    truth = data.get("truth_status", {})
    _fail_if(failures, truth.get("real_external_agents_contacted") is False, "must not claim external agents were contacted")
    _fail_if(failures, truth.get("external_repos_cloned_or_executed") is False, "must not claim external repos were executed")
    _fail_if(failures, truth.get("public_actions_taken") is False, "must not claim public actions")
    _fail_if(failures, truth.get("paid_actions_taken") is False, "must not claim paid actions")
    _fail_if(failures, truth.get("local_deterministic_review_swarm_complete") is True, "local deterministic swarm must be marked complete")

    all_text = json.dumps(data, sort_keys=True).lower()
    for term in BANNED_CLAIM_TERMS:
        _fail_if(failures, term not in all_text, f"unsupported claim term present: {term}")

    sidecars = data.get("sidecar_inputs", [])
    _fail_if(failures, isinstance(sidecars, list) and len(sidecars) >= 4, "must record all four sidecar inputs")
    blocked_sidecars = [item for item in sidecars if item.get("status") == "blocked_context_limit"]
    _fail_if(failures, len(blocked_sidecars) == 1, "must record exactly one blocked context-limit sidecar")
    for item in sidecars:
        _fail_if(failures, bool(item.get("caveat")), f"sidecar {item.get('id')} missing caveat")
        if item.get("status") == "blocked_context_limit":
            _fail_if(failures, not item.get("usable_lessons"), f"blocked sidecar {item.get('id')} must not contribute lessons")

    agents = data.get("local_review_agents", [])
    _fail_if(failures, isinstance(agents, list) and len(agents) >= 25, "must include at least 25 local review agents")
    agent_slugs = _slugs(agents)
    _fail_if(failures, REQUIRED_AGENT_SLUGS.issubset(agent_slugs), f"missing required agents: {sorted(REQUIRED_AGENT_SLUGS - agent_slugs)}")
    for agent in agents:
        path = Path(str(agent.get("agent_toml", "")))
        _fail_if(failures, path.exists(), f"agent TOML missing for {agent.get('slug')}: {path}")
        _fail_if(failures, bool(agent.get("lane")), f"agent {agent.get('slug')} missing lane")
        _fail_if(failures, bool(agent.get("output")), f"agent {agent.get('slug')} missing output")

    repos = data.get("external_fitness_agent_repos", [])
    _fail_if(failures, isinstance(repos, list) and len(repos) >= 10, "must include at least 10 GitHub fitness-agent repos")
    for repo in repos:
        _fail_if(failures, str(repo.get("source_url", "")).startswith("https://github.com/"), f"repo {repo.get('repo')} must have GitHub source_url")
        caveat = str(repo.get("caveat", "")).lower()
        _fail_if(failures, "not executed" in caveat or "separate audits" in caveat, f"repo {repo.get('repo')} must carry execution caveat")

    apps = data.get("top_app_build_benchmarks", [])
    _fail_if(failures, isinstance(apps, list) and len(apps) == 20, "must include exactly 20 app build benchmarks")
    ranks = [app.get("rank") for app in apps if isinstance(app, dict)]
    _fail_if(failures, sorted(ranks) == list(range(1, 21)), "app benchmark ranks must be 1..20")
    ios_count = 0
    android_count = 0
    for app in apps:
        platforms = {str(item).lower() for item in app.get("platform_focus", [])}
        ios_count += int(any("ios" in platform or "apple" in platform for platform in platforms))
        android_count += int(any("android" in platform for platform in platforms))
        _fail_if(failures, str(app.get("source_url", "")).startswith("https://"), f"app {app.get('app')} missing source_url")
        _fail_if(failures, bool(app.get("benchmark_lesson")), f"app {app.get('app')} missing benchmark_lesson")
        _fail_if(failures, bool(app.get("watch_for")), f"app {app.get('app')} missing watch_for")
    _fail_if(failures, ios_count >= 20, "all 20 app benchmarks must cover Apple/iOS expectations")
    _fail_if(failures, android_count >= 18, "at least 18 app benchmarks must cover Android expectations")

    tracks = data.get("review_tracks", [])
    track_ids = {str(track.get("id")) for track in tracks if isinstance(track, dict)}
    _fail_if(failures, REQUIRED_REVIEW_TRACKS.issubset(track_ids), f"missing review tracks: {sorted(REQUIRED_REVIEW_TRACKS - track_ids)}")
    for track in tracks:
        for owner in track.get("owner_agents", []):
            _fail_if(failures, owner in agent_slugs, f"review track {track.get('id')} owner {owner} is not in local_review_agents")

    gaps = data.get("custom_agent_gaps", [])
    gap_slugs = {str(item.get("slug")) for item in gaps if isinstance(item, dict)}
    _fail_if(failures, gap_slugs == REQUIRED_CUSTOM_AGENT_GAPS, f"custom agent gaps must match required set; got {sorted(gap_slugs)}")

    findings = data.get("code_review_findings_top20", [])
    _fail_if(failures, isinstance(findings, list) and len(findings) == 20, "must include exactly 20 code review findings")
    for finding in findings:
        _fail_if(failures, str(finding.get("file", "")).startswith("lib/") or str(finding.get("file", "")).startswith("supabase/"), f"finding {finding.get('id')} must point at source file")
        _fail_if(failures, finding.get("line"), f"finding {finding.get('id')} missing line")
        _fail_if(failures, bool(finding.get("next_action")), f"finding {finding.get('id')} missing next_action")
    highish = [f for f in findings if str(f.get("severity", "")).lower() in {"high", "medium-high"}]
    _fail_if(failures, len(highish) >= 10, "must preserve at least 10 high/medium-high review findings")

    harnesses = data.get("ui_testing_next_harnesses", [])
    _fail_if(failures, isinstance(harnesses, list) and len(harnesses) >= 15, "must include at least 15 next UI/native harnesses")
    _fail_if(failures, any(str(item).startswith("integration_test/") for item in harnesses), "must include integration_test harnesses")
    _fail_if(failures, "transformfit-harness/navigation_contract_gate.py" in harnesses, "must include navigation contract gate next harness")

    backlog = data.get("top_20_improvement_backlog", [])
    _fail_if(failures, isinstance(backlog, list) and len(backlog) == 20, "must include exactly 20 improvement backlog items")
    for item in backlog:
        owner = str(item.get("owner_agent_slug", ""))
        _fail_if(failures, owner in agent_slugs, f"backlog item {item.get('id')} owner {owner} is not in local_review_agents")
        _fail_if(failures, bool(item.get("code_targets")), f"backlog item {item.get('id')} missing code_targets")
        _fail_if(failures, bool(item.get("test_plan")), f"backlog item {item.get('id')} missing test_plan")

    bridge = _load_json(repo_root / "transformfit-harness/bridge.json")
    gate_definitions = bridge.get("gate_definitions", {})
    _fail_if(failures, "fitness_agent_review_swarm_gate" in gate_definitions, "bridge missing fitness_agent_review_swarm_gate definition")
    _fail_if(failures, "fitness_agent_review_swarm" in bridge.get("artifact_types", {}), "bridge missing fitness_agent_review_swarm artifact type")

    war_room = _load_json(repo_root / "transformfit-harness/two_day_war_room.json")
    kpis = {item.get("id") for item in war_room.get("north_star_kpis", []) if isinstance(item, dict)}
    _fail_if(failures, "kpi-fitness-agent-review-swarm" in kpis, "war room missing kpi-fitness-agent-review-swarm")
    _fail_if(failures, "fitness_agent_review_swarm_gate" in war_room.get("required_gates", []), "war room missing required fitness_agent_review_swarm_gate")
    _fail_if(failures, "fitness_agent_review_swarm" in war_room.get("iteration_lanes", []), "war room missing fitness_agent_review_swarm lane")

    ship_text = (repo_root / "transformfit-harness/ship_gate.sh").read_text(encoding="utf-8")
    for token in REQUIRED_SHIP_TOKENS:
        _fail_if(failures, token in ship_text, f"ship gate missing token: {token}")
    route_metrics = _validate_route_contract(repo_root, failures)

    progress_summary_text = _read_text(
        repo_root / "lib/features/progress/progress_summary.dart",
        failures,
        "progress_summary.dart",
    )
    progress_test_text = _read_text(
        repo_root / "test/features/progress/progress_summary_test.dart",
        failures,
        "progress_summary_test.dart",
    )
    for token in REQUIRED_PROGRESS_SUMMARY_TOKENS:
        _fail_if(
            failures,
            token in progress_summary_text,
            f"progress_summary.dart missing wall-clock token: {token}",
        )
    _fail_if(
        failures,
        "completed.last.startedAt" not in progress_summary_text,
        "progress_summary.dart must not anchor current week to latest completed session",
    )
    for token in REQUIRED_PROGRESS_TEST_TOKENS:
        _fail_if(
            failures,
            token in progress_test_text,
            f"progress_summary_test.dart missing stale-history token: {token}",
        )

    plan_reveal_text = _read_text(
        repo_root / "lib/features/onboarding/plan_reveal_controller.dart",
        failures,
        "plan_reveal_controller.dart",
    )
    plan_reveal_test_text = _read_text(
        repo_root / "test/features/onboarding/plan_reveal_real_wiring_test.dart",
        failures,
        "plan_reveal_real_wiring_test.dart",
    )
    for token in REQUIRED_PLAN_REVEAL_VALIDATION_TOKENS:
        _fail_if(
            failures,
            token in plan_reveal_text,
            f"plan_reveal_controller.dart missing strict remote-plan validation token: {token}",
        )
    for token in REQUIRED_PLAN_REVEAL_VALIDATION_TEST_TOKENS:
        _fail_if(
            failures,
            token in plan_reveal_test_text,
            f"plan_reveal_real_wiring_test.dart missing malformed remote-plan regression token: {token}",
        )
    for token in FORBIDDEN_PLAN_REVEAL_DEFAULT_TOKENS:
        _fail_if(
            failures,
            token not in plan_reveal_text,
            f"plan_reveal_controller.dart must not default missing remote plan fields: {token}",
        )

    return {
        "schema": "transformfit.fitness_agent_review_swarm_gate.v1",
        "artifact": str(artifact),
        "repo_root": str(repo_root),
        "verdict": "GREEN" if not failures else "RED",
        "failures": failures,
        "local_review_agents": len(agents),
        "external_fitness_agent_repos": len(repos),
        "top_app_build_benchmarks": len(apps),
        "code_review_findings": len(findings),
        "top_20_improvement_backlog": len(backlog),
        "route_contract": route_metrics,
    }


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("artifact", nargs="?", default="transformfit-harness/fitness_agent_review_swarm.json")
    parser.add_argument("--repo-root", default=".")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args(argv)

    repo_root = Path(args.repo_root).resolve()
    artifact = (repo_root / args.artifact).resolve() if not Path(args.artifact).is_absolute() else Path(args.artifact)
    result = run(artifact, repo_root)
    if args.json:
        print(json.dumps(result, indent=2, sort_keys=True))
    else:
        print(json.dumps(result, indent=2, sort_keys=True))
    return 0 if result["verdict"] == "GREEN" else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
