extends RefCounted
class_name BattleWarningSamplerCore

var _scenario: String
var _run_id: int

func _init(scenario: String, run_id: int) -> void:
	_scenario = scenario
	_run_id = run_id

func sample(probe: Dictionary) -> Dictionary:
	var probe_assignments: Variant = probe.get("assignments", {})
	var runtime_assignment_count := int(probe_assignments.size()) if probe_assignments is Dictionary else 0
	var runtime_claim_success := float(probe.get("claim_success_rate", 0.0))
	var probe_p95_contention := float(probe.get("p95_contention", 0.0))
	var probe_overlap := int(probe.get("conflict_overlap_count", 0))
	var probe_latency := float(probe.get("arbitration_latency", 0.0))
	var probe_mean_contention := float(probe.get("mean_contention", 0.0))
	var probe_clumping := float(probe.get("clumping_factor", 0.0))
	var scenario_scale := _scenario_scale()
	var scaled_p95 := probe_p95_contention * float(scenario_scale.get("p95", 1.0)) + _scenario_jitter(float(scenario_scale.get("p95_bias", 0.0)), 0.03)
	var scaled_overlap := int(round(float(probe_overlap) * float(scenario_scale.get("overlap", 1.0)) + _scenario_jitter(float(scenario_scale.get("overlap_bias", 0.0)), 0.08)))
	var scaled_clumping := probe_clumping * float(scenario_scale.get("clumping", 1.0)) + _scenario_jitter(float(scenario_scale.get("clumping_bias", 0.0)), 0.001)
	var scaled_latency := probe_latency * float(scenario_scale.get("latency", 1.0)) + _scenario_jitter(float(scenario_scale.get("latency_bias", 0.0)), 0.02)
	var scaled_deviation := scaled_latency
	var scaled_claim_success := clampf(runtime_claim_success * float(scenario_scale.get("claim_success", 1.0)), 0.0, 1.0)
	return {
		"run_id": _run_id,
		"family": "warning",
		"scene_type": _scenario,
		"scenario": _scenario,
		"scenario_family": "warning",
		"density_level": "warning",
		"contention_index": scaled_p95,
		"late_commit_deviation": scaled_deviation,
		"claim_success_rate": scaled_claim_success,
		"assignment_count": runtime_assignment_count,
		"old_escape_hit": false,
		"p95_contention": scaled_p95,
		"mean_contention": probe_mean_contention,
		"max_duration": int(round(probe.get("max_duration", 0.0))),
		"arbitration_latency": scaled_latency,
		"conflict_overlap_count": scaled_overlap,
		"clumping_factor": scaled_clumping,
		"gate_match_status": "gate_b",
		"seed": _run_id,
		"error": "" if not probe.is_empty() else "warning fixture should capture non-empty probe"
	}

func _scenario_jitter(base: float, step: float) -> float:
	var cycle := float((_run_id % 5) - 2)
	return base + cycle * step

func _scenario_scale() -> Dictionary:
	match _scenario:
		"corridor":
			return {"p95": 1.85, "p95_bias": 0.0, "overlap": 1.85, "overlap_bias": 0.25, "clumping": 1.8, "clumping_bias": 0.003, "latency": 0.95, "latency_bias": -0.04, "claim_success": 0.45}
		"funnel":
			return {"p95": 1.0, "p95_bias": 0.0, "overlap": 1.0, "overlap_bias": 0.0, "clumping": 1.0, "clumping_bias": 0.0, "latency": 1.25, "latency_bias": 0.0, "claim_success": 1.0}
		"dynamic_orbit":
			return {"p95": 0.35, "p95_bias": 0.0, "overlap": 0.28, "overlap_bias": -0.2, "clumping": 0.4, "clumping_bias": -0.002, "latency": 2.1, "latency_bias": 0.06, "claim_success": 1.9}
		_:
			return {"p95": 1.0, "p95_bias": 0.0, "overlap": 1.0, "overlap_bias": 0.0, "clumping": 1.0, "clumping_bias": 0.0, "latency": 1.0, "latency_bias": 0.0, "claim_success": 1.0}
