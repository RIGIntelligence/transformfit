#!/usr/bin/env python3
"""Fail-closed gate for the TransformFit two-day multidisciplinary war room."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


REQUIRED_TEAM_GROUPS = {
    "designers": 4,
    "fitness_coaches": 4,
    "influencer_pattern_board": 8,
    "artists_photographers": 4,
    "ai_engineers": 4,
    "nutritionists": 3,
    "behavioral_science_specialists": 4,
    "gtm_strategists": 3,
}

REQUIRED_KPIS = {
    "kpi-activation-week-2",
    "kpi-time-to-first-set",
    "kpi-log-friction",
    "kpi-coach-trust",
    "kpi-safety",
    "kpi-activation-24h",
    "kpi-retention",
    "kpi-conversion",
    "kpi-viral-loop",
    "kpi-body-composition-trust",
    "kpi-set-intelligence",
    "kpi-wearable-dai-interface",
    "kpi-coach-command-center",
    "kpi-rig-systems-engineering",
    "kpi-behavioral-repair-loop",
    "kpi-emotional-experience-map",
    "kpi-testsprite-user-testing",
    "kpi-fitness-agent-review-swarm",
    "kpi-five-star-experience",
    "kpi-value-before-auth",
    "kpi-first-session-handoff",
    "kpi-accessibility-low-end-device",
    "kpi-performance-reliability",
    "kpi-ship-gate-non-vacuity",
    "kpi-native-readiness",
    "kpi-proof",
}

REQUIRED_GATES = {
    "doctrine_lint",
    "message_rule_lint",
    "design_lint",
    "build_test_gate",
    "coaching_harness_gate",
    "competitive_reverse_engineering_gate",
    "ux_ui_research_ingestion_gate",
    "coaching_runtime_gate",
    "coach_quality_eval_gate",
    "nutrition_target_gate",
    "body_composition_trust_gate",
    "workout_logger_intelligence_gate",
    "wearable_dai_interface_gate",
    "coach_command_center_gate",
    "behavioral_repair_loop_gate",
    "emotional_experience_map_gate",
    "rig_systems_engineering_gate",
    "testsprite_full_user_testing_gate",
    "fitness_agent_review_swarm_gate",
    "native_mobile_setup_gate",
    "two_day_war_room_gate",
    "five_star_experience_gate",
    "value_before_auth_gate",
    "first_session_handoff_gate",
    "accessibility_low_end_device_gate",
    "perf_frame_budget_gate",
    "ship_gate_non_vacuity_gate",
}

REQUIRED_ITERATION_LANES = {
    "workout_logger_speed",
    "coach_workflow_embedding",
    "onboarding_to_first_session",
    "progress_and_proof",
    "native_mobile_shell",
    "visual_assets_and_app_store_story",
    "nutrition_recovery_boundaries",
    "body_composition_trust",
    "set_intelligence",
    "wearable_dai_interface",
    "coach_command_center",
    "rig_systems_engineering",
    "emotional_experience_map",
    "gtm_conversion_loop",
    "behavioral_repair_flows",
    "accessibility_and_low_end_device",
    "1000_scenario_matrix",
    "testsprite_comprehensive_user_testing",
    "fitness_agent_review_swarm",
    "five_star_experience",
    "value_before_auth",
    "first_session_handoff",
    "performance_reliability_budget",
    "ship_gate_non_vacuity",
}

REQUIRED_SIDECAR_INPUTS = {
    "market-pattern-sidecar-2026-07-02": "received",
    "behavioral-sidecar-2026-07-02": "received",
    "ai-coach-sidecar-2026-07-02": "received",
    "ux-sidecar-2026-07-02": "received",
    "strength-coach-sidecar-2026-07-02": "received",
    "wearable-platform-sidecar-2026-07-02": "received",
    "evidence-collector-sidecar-2026-07-02": "blocked",
}


def fail_if(failures: list[str], condition: bool, message: str) -> None:
    if not condition:
        failures.append(message)


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def run(path: Path) -> dict:
    failures: list[str] = []
    data = load_json(path)

    fail_if(failures, data.get("schema") == "transformfit.two_day_war_room.v1", "schema must be transformfit.two_day_war_room.v1")
    fail_if(failures, data.get("duration_hours") == 48, "war room duration must be exactly 48 hours")

    cadence = data.get("cadence", {})
    fail_if(failures, cadence.get("heartbeat_automation_id") == "transformfit-two-day-1000x-improvement-loop", "heartbeat automation id must be recorded")
    fail_if(failures, cadence.get("interval_hours") == 2, "heartbeat interval must be 2 hours")
    fail_if(failures, cadence.get("planned_heartbeats") == 24, "48-hour sprint must plan 24 two-hour heartbeats")
    fail_if(failures, len(cadence.get("per_heartbeat_done_contract", [])) >= 5, "per-heartbeat done contract must have at least 5 proof obligations")

    boundary = data.get("external_action_boundary", {})
    fail_if(failures, boundary.get("direct_outreach_authorized") is False, "direct outreach must remain unauthorized")
    fail_if(failures, boundary.get("paid_recruiting_authorized") is False, "paid recruiting must remain unauthorized")
    fail_if(failures, boundary.get("public_posting_authorized") is False, "public posting must remain unauthorized")
    fail_if(failures, boundary.get("endorsement_claims_allowed") is False, "endorsement claims must remain disallowed")

    team = data.get("team", {})
    for group, minimum in REQUIRED_TEAM_GROUPS.items():
        members = team.get(group, [])
        fail_if(failures, isinstance(members, list), f"team group {group} must be a list")
        fail_if(failures, len(members) >= minimum, f"team group {group} must have at least {minimum} members")
        for member in members:
            fail_if(failures, bool(member.get("id")), f"{group} member missing id")
            fail_if(
                failures,
                bool(member.get("job") or member.get("product_lesson")),
                f"{group} member {member.get('id', '<unknown>')} missing job/product_lesson",
            )
            if group == "influencer_pattern_board":
                fail_if(failures, bool(member.get("archetype")), f"influencer pattern {member.get('id')} missing archetype")
                fail_if(
                    failures,
                    "endorsement" not in json.dumps(member).lower(),
                    f"influencer pattern {member.get('id')} must not claim endorsement",
                )

    users = data.get("user_panel", [])
    fail_if(failures, len(users) == 20, "user panel must contain exactly 20 users")
    seen_user_ids: set[str] = set()
    for user in users:
        user_id = user.get("id")
        fail_if(failures, bool(user_id), "every user must have id")
        if user_id:
            fail_if(failures, user_id not in seen_user_ids, f"duplicate user id: {user_id}")
            seen_user_ids.add(user_id)
        for key in ["segment", "primary_job", "risk_to_test", "scenario"]:
            fail_if(failures, bool(user.get(key)), f"user {user_id} missing {key}")

    kpi_ids = {item.get("id") for item in data.get("north_star_kpis", [])}
    fail_if(failures, REQUIRED_KPIS.issubset(kpi_ids), f"missing KPIs: {sorted(REQUIRED_KPIS - kpi_ids)}")
    activation_24h = next(
        (item for item in data.get("north_star_kpis", []) if item.get("id") == "kpi-activation-24h"),
        {},
    )
    fail_if(
        failures,
        "one nutrition target within 24 hours" in activation_24h.get("target", ""),
        "24-hour activation KPI must include one nutrition target",
    )
    body_composition = next(
        (item for item in data.get("north_star_kpis", []) if item.get("id") == "kpi-body-composition-trust"),
        {},
    )
    body_target = body_composition.get("target", "")
    fail_if(
        failures,
        "imperfect signals" in body_target and "strength, recovery, and adherence" in body_target,
        "body-composition KPI must require imperfect signals plus strength, recovery, and adherence context",
    )

    lanes = set(data.get("iteration_lanes", []))
    fail_if(failures, REQUIRED_ITERATION_LANES.issubset(lanes), f"missing iteration lanes: {sorted(REQUIRED_ITERATION_LANES - lanes)}")

    gates = set(data.get("required_gates", []))
    fail_if(failures, REQUIRED_GATES.issubset(gates), f"missing required gates: {sorted(REQUIRED_GATES - gates)}")

    sidecars = {
        item.get("id"): item
        for item in data.get("sidecar_inputs", [])
        if isinstance(item, dict) and item.get("id")
    }
    for sidecar_id, expected_status in REQUIRED_SIDECAR_INPUTS.items():
        sidecar = sidecars.get(sidecar_id, {})
        fail_if(failures, bool(sidecar), f"missing sidecar input: {sidecar_id}")
        fail_if(
            failures,
            sidecar.get("status") == expected_status,
            f"sidecar {sidecar_id} must have status {expected_status}",
        )
        fail_if(
            failures,
            bool(sidecar.get("caveat")),
            f"sidecar {sidecar_id} must carry an evidence caveat",
        )
    for sidecar in sidecars.values():
        if sidecar.get("status") == "blocked":
            fail_if(
                failures,
                not sidecar.get("usable_lessons"),
                f"blocked sidecar {sidecar.get('id')} must not contribute usable lessons",
            )

    quality_bar = data.get("quality_bar", {})
    fail_if(failures, quality_bar.get("anti_generic_force_minimum", 0) >= 85, "AntiGenericForce minimum must be >=85")
    for key in ["no_source_no_number", "no_mechanism_no_claim", "proofpacket_required", "builder_does_not_grade_final_release"]:
        fail_if(failures, quality_bar.get(key) is True, f"quality bar {key} must be true")

    open_gaps = data.get("open_gaps", [])
    fail_if(failures, any("real recruited user testing" in gap for gap in open_gaps), "open gaps must admit real recruited user testing is incomplete")
    fail_if(failures, any("native strict toolchain" in gap for gap in open_gaps), "open gaps must admit strict native toolchain proof is incomplete")

    return {
        "schema": "transformfit.two_day_war_room_gate.v1",
        "artifact": str(path),
        "verdict": "GREEN" if not failures else "RED",
        "failures": failures,
        "team_groups": {group: len(team.get(group, [])) for group in REQUIRED_TEAM_GROUPS},
        "user_panel_count": len(users),
        "planned_heartbeats": cadence.get("planned_heartbeats"),
        "sidecar_inputs": {sidecar_id: sidecars.get(sidecar_id, {}).get("status") for sidecar_id in REQUIRED_SIDECAR_INPUTS},
    }


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("artifact", nargs="?", default="transformfit-harness/two_day_war_room.json")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args(argv)

    path = Path(args.artifact).resolve()
    result = run(path)
    if args.json:
        print(json.dumps(result, indent=2))
    elif result["verdict"] == "GREEN":
        print(f"GREEN two_day_war_room_gate: {path}")
    else:
        print(f"RED two_day_war_room_gate: {path}", file=sys.stderr)
        for failure in result["failures"]:
            print(f"  - {failure}", file=sys.stderr)
    return 0 if result["verdict"] == "GREEN" else 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
