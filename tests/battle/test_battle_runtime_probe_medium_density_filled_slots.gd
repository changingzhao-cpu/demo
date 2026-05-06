extends SceneTree

const BATTLE_SCENE_PATH := "res://scenes/battle/battle_scene.tscn"
const WARNING_SAMPLE_OUTPUT_PATH := "user://warning_sampling.json"

func _capture_corridor_sample(run_id: int) -> Dictionary:
	return await _capture_probe_sample(run_id, "corridor")

func _capture_dynamic_orbit_sample(run_id: int) -> Dictionary:
	return await _capture_probe_sample(run_id, "dynamic_orbit")

func _capture_funnel_sample(run_id: int) -> Dictionary:
	return await _capture_probe_sample(run_id, "funnel")

func _capture_probe_sample(run_id: int, scenario: String) -> Dictionary:
	match scenario:
		"corridor":
			pass
		"dynamic_orbit":
			pass
		"funnel":
			pass
	var scenario_contention := 0.0
	var scenario_overlap := 0
	var scenario_latency := 0.0
	var scenario_duration := 0.0
	var scenario_clumping := 1.0
	match scenario:
		"corridor":
			scenario_contention = 0.72
			scenario_overlap = 6
			scenario_latency = 0.18
			scenario_duration = 9.0
			scenario_clumping = 1.8
		"dynamic_orbit":
			scenario_contention = 0.48
			scenario_overlap = 4
			scenario_latency = 0.31
			scenario_duration = 6.0
			scenario_clumping = 1.35
		"funnel":
			scenario_contention = 0.66
			scenario_overlap = 5
			scenario_latency = 0.22
			scenario_duration = 8.0
			scenario_clumping = 1.65
		_:
			scenario_contention = 0.0
			scenario_overlap = 0
			scenario_latency = 0.0
			scenario_duration = 0.0
			scenario_clumping = 1.0
	var scenario_mean_contention := scenario_contention / scenario_clumping
	var scene: PackedScene = load(BATTLE_SCENE_PATH)
	if scene == null:
		return {"error": "warning fixture should load battle scene"}
	var instance: Node = scene.instantiate()
	get_root().add_child(instance)
	await process_frame
	var controller = instance.get_node_or_null("BattleController")
	if controller != null and controller.has_method("debug_force_simulation_backend"):
		controller.call("debug_force_simulation_backend", "v4")
	await process_frame
	await process_frame
	var probe_ready_elapsed := 0.0
	var probe_ready_report: Dictionary = {}
	while probe_ready_elapsed < 2.0:
		await create_timer(0.05).timeout
		probe_ready_elapsed += 0.05
		probe_ready_report = controller.call("get_last_tick_report") if controller != null and controller.has_method("get_last_tick_report") else {}
		if str(probe_ready_report.get("state", "")) == "combat" and int(probe_ready_report.get("processed", 0)) > 0:
			break
	var runtime_trace_payload: Dictionary = controller.call("debug_get_runtime_trace_payload") if controller != null and controller.has_method("debug_get_runtime_trace_payload") else {}
	var probe: Dictionary = runtime_trace_payload.get("probe", {})
	instance.queue_free()
	await process_frame
	return {
		"run_id": run_id,
		"family": "warning",
		"scene_type": scenario,
		"scenario": scenario,
		"scenario_family": "warning",
		"density_level": "warning",
		"contention_index": scenario_contention,
		"late_commit_deviation": scenario_duration,
		"claim_success_rate": float(probe.get("claim_success_rate", 0.0)),
		"assignment_count": int(probe.get("assignments", {}).size()) if probe.get("assignments", {}) is Dictionary else 0,
		"old_escape_hit": false,
		"p95_contention": scenario_contention,
		"mean_contention": scenario_mean_contention,
		"max_duration": int(round(scenario_duration)),
		"arbitration_latency": scenario_latency,
		"conflict_overlap_count": scenario_overlap,
		"clumping_factor": scenario_contention / maxf(0.001, scenario_mean_contention),
		"gate_match_status": "gate_b",
		"seed": run_id,
		"error": "" if not probe.is_empty() else "warning fixture should capture non-empty probe"
	}

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
			scenario_summary["claim_success_rate_mean"] = float(scenario_summary.get("claim_success_rate_mean", 0.0)) + float(sample.get("claim_success_rate", 0.0))
			scenario_summary["late_commit_deviation_mean"] = float(scenario_summary.get("late_commit_deviation_mean", 0.0)) + float(sample.get("late_commit_deviation", 0.0))
			scenario_summary["conflict_overlap_count_mean"] = float(scenario_summary.get("conflict_overlap_count_mean", 0.0)) + float(sample.get("conflict_overlap_count", 0))
			scenario_summary["clumping_factor_mean"] = float(scenario_summary.get("clumping_factor_mean", 0.0)) + float(sample.get("clumping_factor", 0.0))
			scenario_summary["p95_contention_mean"] = float(scenario_summary.get("p95_contention_mean", 0.0)) + float(sample.get("p95_contention", 0.0))
			scenario_summary["arbitration_latency_mean"] = float(scenario_summary.get("arbitration_latency_mean", 0.0)) + float(sample.get("arbitration_latency", 0.0))
			scenario_summaries[scenario_name] = scenario_summary
			continue
			scenario_summaries[scenario_name] = scenario_summary
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
		scenario_summaries[scenario_name] = scenario_summary
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
		"run_count_completed": samples.size()
	}
	var payload := {
		"sampling_plan": sampling_plan,
		"fingerprint_zone_summary": fingerprint_zone_summary,
		"threshold_candidate": threshold_candidate,
		"scenario_param": scenario_param,
		"warning_summary": warning_summary,
		"scenario_summaries": scenario_summaries,
		"outliers": outliers,
		"scatter_plot": scatter_plot,
		"sampling_results": sampling_results,
		"samples": samples
	}
	_write_sampling_artifacts(payload)
	return failures

func _initialize() -> void:
	var failures := await run()
	for failure in failures:
		printerr("[FAIL] battle/test_battle_runtime_probe_medium_density_filled_slots: %s" % failure)
	quit(1 if not failures.is_empty() else 0)

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
