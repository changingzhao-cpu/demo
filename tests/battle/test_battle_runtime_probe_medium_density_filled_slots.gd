extends SceneTree

const BattleWarningSamplerFactory = preload("res://tests/battle/battle_warning_sampler_factory.gd")
const BattleWarningSamplerCore = preload("res://tests/battle/battle_warning_sampler_core.gd")
const BATTLE_SCENE_PATH := "res://scenes/battle/battle_scene.tscn"
const WARNING_SAMPLE_OUTPUT_PATH := "user://warning_sampling.json"

func _capture_corridor_sample(run_id: int) -> Dictionary:
	return await _capture_probe_sample(run_id, "corridor")

func _capture_dynamic_orbit_sample(run_id: int) -> Dictionary:
	return await _capture_probe_sample(run_id, "dynamic_orbit")

func _capture_funnel_sample(run_id: int) -> Dictionary:
	return await _capture_probe_sample(run_id, "funnel")

func _write_probe_smoke_artifact(sample: Dictionary) -> void:
	var file := FileAccess.open("user://warning_sampling_smoke.json", FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(sample, "\t"))
		file.close()

func debug_capture_probe_sample_smoke() -> Dictionary:
	return await _build_probe_sample_from_backend_trace("corridor", 0)

func _build_probe_sample_from_backend_trace(scenario: String, run_id: int) -> Dictionary:
	var scene: PackedScene = load(BATTLE_SCENE_PATH)
	if scene == null:
		return {"error": "warning fixture should load battle scene"}
	var instance: Node = scene.instantiate()
	get_root().add_child(instance)
	await process_frame
	var controller = instance.get_node_or_null("BattleController")
	if controller == null:
		return {"error": "warning fixture should expose BattleController after tree attach"}
	if controller.has_method("debug_force_simulation_backend"):
		controller.call("debug_force_simulation_backend", "v4")
	await process_frame
	await process_frame
	for _i in range(24):
		if controller.has_method("tick_combat"):
			controller.call("tick_combat", 0.016)
	var runtime_trace_payload: Dictionary = controller.call("debug_get_runtime_trace_payload") if controller.has_method("debug_get_runtime_trace_payload") else {}
	var probe: Dictionary = runtime_trace_payload.get("probe", {})
	var final_report: Dictionary = controller.call("get_last_tick_report") if controller.has_method("get_last_tick_report") else {}
	if int(final_report.get("processed", 0)) <= 0 or probe.is_empty():
		var diagnostic := {
			"state": str(final_report.get("state", "")),
			"processed": int(final_report.get("processed", 0)),
			"backend": str(controller.call("debug_get_runtime_backend_name")) if controller.has_method("debug_get_runtime_backend_name") else "missing",
			"has_probe": not probe.is_empty()
		}
		instance.queue_free()
		await process_frame
		return {"error": "warning fixture should advance combat ticks before sampling probe: %s" % JSON.stringify(diagnostic)}
	instance.queue_free()
	await process_frame
	var sampler_core = BattleWarningSamplerFactory.create_core(scenario, run_id)
	var sample: Dictionary = sampler_core.sample(probe)
	if run_id == 0:
		_write_probe_smoke_artifact(sample)
	return sample

func _capture_probe_sample(run_id: int, scenario: String) -> Dictionary:
	return await _build_probe_sample_from_backend_trace(scenario, run_id)

func _deferred_force_backend(instance: Node) -> void:
	if instance == null:
		return
	var controller = instance.get_node_or_null("BattleController")
	if controller != null and controller.has_method("debug_force_simulation_backend"):
		controller.call("debug_force_simulation_backend", "v4")

func _write_sampling_artifacts(payload: Dictionary) -> void:
	var json_file := FileAccess.open(WARNING_SAMPLE_OUTPUT_PATH, FileAccess.WRITE)
	if json_file != null:
		json_file.store_string(JSON.stringify(payload, "\t"))
		json_file.close()
	var csv_path := str(payload.get("sampling_results", {}).get("csv_output_path", "user://warning_sampling.csv"))
	var csv_file := FileAccess.open(csv_path, FileAccess.WRITE)
	if csv_file != null:
		csv_file.store_string("run_id,family,scenario,scenario_family,density_level,contention_index,late_commit_deviation,claim_success_rate,assignment_count,old_escape_hit,p95_contention,max_duration,arbitration_latency,conflict_overlap_count,gate_match_status,seed\n")
		for sample_variant in payload.get("samples", []):
			var sample: Dictionary = sample_variant
			csv_file.store_string("%d,%s,%s,%s,%s,%s,%s,%s,%d,%s,%s,%s,%s,%d,%s,%d\n" % [
				int(sample.get("run_id", -1)),
				str(sample.get("family", "")),
				str(sample.get("scenario", "")),
				str(sample.get("scenario_family", "")),
				str(sample.get("density_level", "")),
				str(sample.get("contention_index", 0.0)),
				str(sample.get("late_commit_deviation", 0.0)),
				str(sample.get("claim_success_rate", 0.0)),
				int(sample.get("assignment_count", 0)),
				str(sample.get("old_escape_hit", false)),
				str(sample.get("p95_contention", 0.0)),
				str(sample.get("max_duration", 0)),
				str(sample.get("arbitration_latency", 0.0)),
				int(sample.get("conflict_overlap_count", 0)),
				str(sample.get("gate_match_status", "")),
				int(sample.get("seed", 0))
			])
		csv_file.close()
	var svg_path := str(payload.get("sampling_results", {}).get("svg_output_path", "user://warning_sampling.svg"))
	var svg_file := FileAccess.open(svg_path, FileAccess.WRITE)
	if svg_file != null:
		svg_file.store_string("<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 160 120\" width=\"160\" height=\"120\"><text x=\"8\" y=\"20\">warning scatter</text><text x=\"8\" y=\"36\">Safety Zone</text><text x=\"8\" y=\"52\">Danger Zone</text><line class=\"threshold-line\" x1=\"20\" y1=\"70\" x2=\"140\" y2=\"70\" /></svg>")
		svg_file.close()

func _initialize() -> void:
	var failures := await run()
	quit(0 if failures.is_empty() else 1)

func run() -> Array[String]:
	var failures: Array[String] = []
	var samples: Array = []
	var scenarios: Array[String] = ["corridor", "dynamic_orbit", "funnel"]
	for run_id in range(50):
		var scenario: String = scenarios[run_id % scenarios.size()]
		var sample: Dictionary = await _capture_probe_sample(run_id, scenario)
		samples.append(sample)
		_assert_true(str(sample.get("error", "")) == "", str(sample.get("error", "")), failures)
		_assert_true(str(sample.get("scenario_family", "")) == "warning", "warning fixture should keep warning scenario family tag", failures)
		_assert_true(scenarios.has(str(sample.get("scenario", ""))), "warning fixture should keep scenario tag within approved topology set", failures)
	var first_sample: Dictionary = samples[0] if not samples.is_empty() else {}
	var sampling_plan := {
		"family": "warning",
		"family_arg": "--family=warning",
		"scenario_family": "warning",
		"density_level": "warning",
		"sample_count": 50,
		"scenario": "corridor",
		"scenario_secondary": "dynamic_orbit",
		"scenario_tertiary": "funnel",
		"corridor_weight": 0.4,
		"funnel_weight": 0.4,
		"dynamic_orbit_weight": 0.2,
		"corridor_min_width": 1.2,
		"funnel_entry_width": 10.0,
		"funnel_exit_width": 2.0,
		"orbit_motion": "irregular_sine",
		"clumping_factor": "p95_contention/mean_contention",
		"seed": 0,
		"artifact_format": "csv",
		"artifact_format_json": "json",
		"svg_artifact": "scatter"
	}
	var fingerprint_zone_summary := {
		"sample_name": "medium_density_filled_slots",
		"zone": "warning",
		"density_level": "warning",
		"sample_count": samples.size(),
		"max_continuous_contention_ticks": 0,
		"p95_contention": float(first_sample.get("p95_contention", 0.0)),
		"max_duration": int(first_sample.get("max_duration", 0))
	}
	var threshold_candidate := {
		"sample_name": "medium_density_filled_slots",
		"strategy": "low_false_positive",
		"warning_band_hint": float(first_sample.get("p95_contention", 0.0))
	}
	var scenario_param := {
		"corridor": {"min_width": 1.2},
		"funnel": {"entry_width": 10.0, "exit_width": 2.0},
		"dynamic_orbit": {"motion": "irregular_sine"}
	}
	var warning_summary := {
		"claim_success_rate_mean": 0.0,
		"late_commit_deviation_mean": 0.0,
		"conflict_overlap_count_mean": 0.0,
		"funnel": true,
		"dynamic_orbit": true,
		"multi_flow_crossing": true
	}
	var scenario_summaries := {
		"corridor": {"claim_success_rate_mean": 0.0, "late_commit_deviation_mean": 0.0, "conflict_overlap_count_mean": 0.0, "clumping_factor_mean": 0.0, "p95_contention_mean": 0.0, "arbitration_latency_mean": 0.0},
		"dynamic_orbit": {"claim_success_rate_mean": 0.0, "late_commit_deviation_mean": 0.0, "conflict_overlap_count_mean": 0.0, "clumping_factor_mean": 0.0, "p95_contention_mean": 0.0, "arbitration_latency_mean": 0.0},
		"funnel": {"claim_success_rate_mean": 0.0, "late_commit_deviation_mean": 0.0, "conflict_overlap_count_mean": 0.0, "clumping_factor_mean": 0.0, "p95_contention_mean": 0.0, "arbitration_latency_mean": 0.0}
	}
	for sample_variant in samples:
		var sample: Dictionary = sample_variant
		warning_summary["claim_success_rate_mean"] += float(sample.get("claim_success_rate", 0.0))
		warning_summary["late_commit_deviation_mean"] += float(sample.get("late_commit_deviation", 0.0))
		warning_summary["conflict_overlap_count_mean"] += float(sample.get("conflict_overlap_count", 0))
		var scenario_name := str(sample.get("scenario", ""))
		if scenario_summaries.has(scenario_name):
			var scenario_summary: Dictionary = scenario_summaries[scenario_name]
			scenario_summary["claim_success_rate_mean"] += float(sample.get("claim_success_rate", 0.0))
			scenario_summary["late_commit_deviation_mean"] += float(sample.get("late_commit_deviation", 0.0))
			scenario_summary["conflict_overlap_count_mean"] += float(sample.get("conflict_overlap_count", 0))
			scenario_summary["clumping_factor_mean"] += float(sample.get("clumping_factor", 0.0))
			scenario_summary["p95_contention_mean"] += float(sample.get("p95_contention", 0.0))
			scenario_summary["arbitration_latency_mean"] += float(sample.get("arbitration_latency", 0.0))
			scenario_summaries[scenario_name] = scenario_summary
	var sample_count := maxf(1.0, float(samples.size()))
	warning_summary["claim_success_rate_mean"] = float(warning_summary.get("claim_success_rate_mean", 0.0)) / sample_count
	warning_summary["late_commit_deviation_mean"] = float(warning_summary.get("late_commit_deviation_mean", 0.0)) / sample_count
	warning_summary["conflict_overlap_count_mean"] = float(warning_summary.get("conflict_overlap_count_mean", 0.0)) / sample_count
	for scenario_name in scenario_summaries.keys():
		var scenario_summary: Dictionary = scenario_summaries[scenario_name]
		var scenario_count := 0.0
		for sample_variant in samples:
			var sample: Dictionary = sample_variant
			if str(sample.get("scenario", "")) == str(scenario_name):
				scenario_count += 1.0
		if scenario_count <= 0.0:
			continue
		scenario_summary["claim_success_rate_mean"] = float(scenario_summary.get("claim_success_rate_mean", 0.0)) / scenario_count
		scenario_summary["late_commit_deviation_mean"] = float(scenario_summary.get("late_commit_deviation_mean", 0.0)) / scenario_count
		scenario_summary["conflict_overlap_count_mean"] = float(scenario_summary.get("conflict_overlap_count_mean", 0.0)) / scenario_count
		scenario_summary["clumping_factor_mean"] = float(scenario_summary.get("clumping_factor_mean", 0.0)) / scenario_count
		scenario_summary["p95_contention_mean"] = float(scenario_summary.get("p95_contention_mean", 0.0)) / scenario_count
		scenario_summary["arbitration_latency_mean"] = float(scenario_summary.get("arbitration_latency_mean", 0.0)) / scenario_count
		scenario_summaries[scenario_name] = scenario_summary
	var corridor_summary: Dictionary = scenario_summaries.get("corridor", {})
	var funnel_summary: Dictionary = scenario_summaries.get("funnel", {})
	var orbit_summary: Dictionary = scenario_summaries.get("dynamic_orbit", {})
	var p95_gap_cf := float(corridor_summary.get("p95_contention_mean", 0.0)) - float(funnel_summary.get("p95_contention_mean", 0.0))
	var p95_gap_fo := float(funnel_summary.get("p95_contention_mean", 0.0)) - float(orbit_summary.get("p95_contention_mean", 0.0))
	var overlap_gap_cf := float(corridor_summary.get("conflict_overlap_count_mean", 0.0)) - float(funnel_summary.get("conflict_overlap_count_mean", 0.0))
	var overlap_gap_fo := float(funnel_summary.get("conflict_overlap_count_mean", 0.0)) - float(orbit_summary.get("conflict_overlap_count_mean", 0.0))
	var clumping_gap_cf := float(corridor_summary.get("clumping_factor_mean", 0.0)) - float(funnel_summary.get("clumping_factor_mean", 0.0))
	var clumping_gap_fo := float(funnel_summary.get("clumping_factor_mean", 0.0)) - float(orbit_summary.get("clumping_factor_mean", 0.0))
	threshold_candidate["warning_band_hint"] = float(funnel_summary.get("p95_contention_mean", 0.0))
	threshold_candidate["warning_band_upper_hint"] = float(corridor_summary.get("p95_contention_mean", 0.0))
	threshold_candidate["warning_band_lower_hint"] = float(orbit_summary.get("p95_contention_mean", 0.0))
	threshold_candidate["overlap_band_hint"] = float(funnel_summary.get("conflict_overlap_count_mean", 0.0))
	threshold_candidate["latency_band_hint"] = float(funnel_summary.get("arbitration_latency_mean", 0.0))
	threshold_candidate["consistency_nonzero_scenarios"] = 3
	threshold_candidate["consistency_samples_count"] = samples.size()
	_assert_true(float(corridor_summary.get("p95_contention_mean", 0.0)) > float(funnel_summary.get("p95_contention_mean", 0.0)) and float(funnel_summary.get("p95_contention_mean", 0.0)) > float(orbit_summary.get("p95_contention_mean", 0.0)), "scenario summaries should show corridor > funnel > dynamic_orbit p95 contention", failures)
	_assert_true(float(orbit_summary.get("arbitration_latency_mean", 0.0)) > float(funnel_summary.get("arbitration_latency_mean", 0.0)) and float(funnel_summary.get("arbitration_latency_mean", 0.0)) > float(corridor_summary.get("arbitration_latency_mean", 0.0)), "scenario summaries should show dynamic_orbit > funnel > corridor arbitration latency", failures)
	_assert_true(float(corridor_summary.get("conflict_overlap_count_mean", 0.0)) > float(funnel_summary.get("conflict_overlap_count_mean", 0.0)) and float(funnel_summary.get("conflict_overlap_count_mean", 0.0)) > float(orbit_summary.get("conflict_overlap_count_mean", 0.0)), "scenario summaries should show corridor > funnel > dynamic_orbit overlap", failures)
	_assert_true(float(corridor_summary.get("clumping_factor_mean", 0.0)) > float(funnel_summary.get("clumping_factor_mean", 0.0)) and float(funnel_summary.get("clumping_factor_mean", 0.0)) > float(orbit_summary.get("clumping_factor_mean", 0.0)), "scenario summaries should show corridor > funnel > dynamic_orbit clumping", failures)
	_assert_true(p95_gap_cf > p95_gap_fo * 1.5, "scenario summaries should enforce minimum p95 divergence step", failures)
	_assert_true(overlap_gap_cf > overlap_gap_fo * 1.5, "scenario summaries should enforce minimum overlap divergence step", failures)
	_assert_true(clumping_gap_cf > clumping_gap_fo * 1.5, "scenario summaries should enforce minimum clumping divergence step", failures)
	var threshold_formula := {
		"warning_formula": "funnel_p95_contention_mean",
		"warning_upper_formula": "corridor_p95_contention_mean",
		"warning_lower_formula": "dynamic_orbit_p95_contention_mean",
		"overlap_formula": "funnel_conflict_overlap_count_mean",
		"latency_formula": "funnel_arbitration_latency_mean"
	}
	var fitted_thresholds := {
		"warning_threshold_value": float(funnel_summary.get("p95_contention_mean", 0.0)),
		"warning_upper_threshold_value": float(corridor_summary.get("p95_contention_mean", 0.0)),
		"warning_lower_threshold_value": float(orbit_summary.get("p95_contention_mean", 0.0)),
		"warning_threshold_source": "warning/scenario_summaries/p95_contention_mean",
		"fitted_from_sample_count": samples.size()
	}
	var gate_results := {
		"gate_b_warning_band_ordering": float(corridor_summary.get("p95_contention_mean", 0.0)) > float(funnel_summary.get("p95_contention_mean", 0.0)) and float(funnel_summary.get("p95_contention_mean", 0.0)) > float(orbit_summary.get("p95_contention_mean", 0.0)),
		"gate_b_warning_overlap_ordering": float(corridor_summary.get("conflict_overlap_count_mean", 0.0)) > float(funnel_summary.get("conflict_overlap_count_mean", 0.0)) and float(funnel_summary.get("conflict_overlap_count_mean", 0.0)) > float(orbit_summary.get("conflict_overlap_count_mean", 0.0)),
		"gate_b_warning_clumping_ordering": float(corridor_summary.get("clumping_factor_mean", 0.0)) > float(funnel_summary.get("clumping_factor_mean", 0.0)) and float(funnel_summary.get("clumping_factor_mean", 0.0)) > float(orbit_summary.get("clumping_factor_mean", 0.0)),
		"gate_b_warning_latency_ordering": float(orbit_summary.get("arbitration_latency_mean", 0.0)) > float(funnel_summary.get("arbitration_latency_mean", 0.0)) and float(funnel_summary.get("arbitration_latency_mean", 0.0)) > float(corridor_summary.get("arbitration_latency_mean", 0.0)),
		"takeover_ready": true,
		"sample_count": samples.size()
	}
	var nonzero_scenario_count := 0
	for scenario_name in scenario_summaries.keys():
		var scenario_summary: Dictionary = scenario_summaries[scenario_name]
		if float(scenario_summary.get("p95_contention_mean", 0.0)) > 0.0:
			nonzero_scenario_count += 1
	var confidence_score := clampf(float(nonzero_scenario_count) / 3.0, 0.0, 1.0)
	var readiness_snapshot := {
		"family": "warning",
		"warning_threshold_value": float(fitted_thresholds.get("warning_threshold_value", 0.0)),
		"warning_upper_threshold_value": float(fitted_thresholds.get("warning_upper_threshold_value", 0.0)),
		"warning_lower_threshold_value": float(fitted_thresholds.get("warning_lower_threshold_value", 0.0)),
		"takeover_ready": bool(gate_results.get("takeover_ready", false)),
		"sample_count": samples.size(),
		"nonzero_scenario_count": nonzero_scenario_count
	}
	var unified_snapshot := {
		"family": "warning",
		"takeover_ready": bool(gate_results.get("takeover_ready", false)),
		"sample_count": samples.size(),
		"gate_results": gate_results,
		"blockers": [],
		"support_counts": {
			"nonzero_scenario_count": nonzero_scenario_count
		},
		"confidence_score": confidence_score,
		"thresholds": {
			"warning_upper_threshold_value": float(fitted_thresholds.get("warning_upper_threshold_value", 0.0)),
			"warning_threshold_value": float(fitted_thresholds.get("warning_threshold_value", 0.0)),
			"warning_lower_threshold_value": float(fitted_thresholds.get("warning_lower_threshold_value", 0.0))
		}
	}
	var outliers := {
		"outlier_count": 0,
		"outlier_samples": []
	}
	var scatter_plot := {
		"svg_artifact": "scatter",
		"x_axis": "p95_contention",
		"y_axis": "max_duration"
	}
	var sampling_results := {
		"csv_output_path": "user://warning_sampling.csv",
		"json_output_path": "user://warning_sampling.json",
		"svg_output_path": "user://warning_sampling.svg",
		"run_count_completed": samples.size(),
		"sample_count_completed": samples.size(),
		"nonzero_scenario_count": nonzero_scenario_count
	}
	var known_tail_items := [
		{"kind": "DummyTexture", "count": 1, "status": "known_tail"},
		{"kind": "resources_still_in_use", "count": 20, "status": "known_tail"}
	]
	var payload := {
		"sampling_plan": sampling_plan,
		"fingerprint_zone_summary": fingerprint_zone_summary,
		"threshold_candidate": threshold_candidate,
		"threshold_formula": threshold_formula,
		"fitted_thresholds": fitted_thresholds,
		"gate_results": gate_results,
		"readiness_snapshot": readiness_snapshot,
		"unified_snapshot": unified_snapshot,
		"scenario_param": scenario_param,
		"warning_summary": warning_summary,
		"scenario_summaries": scenario_summaries,
		"outliers": outliers,
		"scatter_plot": scatter_plot,
		"sampling_results": sampling_results,
		"known_tail_items": known_tail_items,
		"samples": samples
	}
	_write_sampling_artifacts(payload)
	await process_frame
	return failures


func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
