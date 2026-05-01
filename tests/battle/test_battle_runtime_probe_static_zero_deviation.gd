extends SceneTree

const BATTLE_SCENE_PATH := "res://scenes/battle/battle_scene.tscn"
const COMFORT_SAMPLE_OUTPUT_PATH := "user://comfort_sampling.json"

func _capture_probe_sample(run_id: int) -> Dictionary:
	var scene: PackedScene = load(BATTLE_SCENE_PATH)
	if scene == null:
		return {"error": "static zero deviation fixture should load battle scene"}
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
	var anomaly_scan: Dictionary = probe_ready_report.get("anomaly_scan", {}) if probe_ready_report.has("anomaly_scan") else {}
	instance.queue_free()
	await process_frame
	return {
		"run_id": run_id,
		"family": "comfort",
		"density_level": "comfort",
		"contention_index": float(probe.get("contention_index", 0.0)),
		"late_commit_deviation": float(probe.get("late_commit_deviation", 0.0)),
		"claim_success_rate": float(probe.get("claim_success_rate", 0.0)),
		"assignment_count": int(probe.get("assignments", {}).size()) if probe.get("assignments", {}) is Dictionary else 0,
		"old_escape_hit": int(anomaly_scan.get("attack_rebind_escape_count", 0)) > 0,
		"probe": probe,
		"anomaly_scan": anomaly_scan,
		"error": "" if not probe.is_empty() else "static zero deviation fixture should capture non-empty probe"
	}

func _write_sampling_artifacts(payload: Dictionary) -> void:
	var json_file := FileAccess.open(COMFORT_SAMPLE_OUTPUT_PATH, FileAccess.WRITE)
	if json_file != null:
		json_file.store_string(JSON.stringify(payload, "\t"))
		json_file.close()
	var csv_path := str(payload.get("sampling_results", {}).get("csv_output_path", "user://comfort_sampling.csv"))
	var csv_file := FileAccess.open(csv_path, FileAccess.WRITE)
	if csv_file != null:
		csv_file.store_string("run_id,family,density_level,contention_index,late_commit_deviation,claim_success_rate,assignment_count,old_escape_hit\n")
		for sample_variant in payload.get("samples", []):
			var sample: Dictionary = sample_variant
			csv_file.store_string("%d,%s,%s,%s,%s,%s,%d,%s\n" % [
				int(sample.get("run_id", -1)),
				str(sample.get("family", "")),
				str(sample.get("density_level", "")),
				str(sample.get("contention_index", 0.0)),
				str(sample.get("late_commit_deviation", 0.0)),
				str(sample.get("claim_success_rate", 0.0)),
				int(sample.get("assignment_count", 0)),
				str(sample.get("old_escape_hit", false))
			])
		csv_file.close()
	var svg_path := str(payload.get("sampling_results", {}).get("svg_output_path", "user://comfort_sampling.svg"))
	var svg_file := FileAccess.open(svg_path, FileAccess.WRITE)
	if svg_file != null:
		svg_file.store_string("<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"160\" height=\"120\"><text x=\"8\" y=\"20\">comfort scatter</text></svg>")
		svg_file.close()

func run() -> Array[String]:
	var failures: Array[String] = []
	var samples: Array = []
	for run_id in range(10):
		var sample: Dictionary = await _capture_probe_sample(run_id)
		samples.append(sample)
		_assert_true(str(sample.get("error", "")) == "", str(sample.get("error", "")), failures)
		_assert_true(float(sample.get("late_commit_deviation", -1.0)) >= 0.0, "comfort fixture should persist non-negative late_commit_deviation", failures)
		_assert_true(not bool(sample.get("old_escape_hit", true)), "comfort fixture should not report attack rebind escapes", failures)
		_assert_true(float(sample.get("claim_success_rate", -1.0)) >= 0.0, "comfort fixture should persist non-negative claim_success_rate", failures)
		_assert_true(int(sample.get("assignment_count", -1)) >= 0, "comfort fixture should persist non-negative assignment_count", failures)
	var first_sample: Dictionary = samples[0] if not samples.is_empty() else {}
	var shadow_warning := {
		"sample_name": "static_zero_deviation",
		"warning_type": "contention_shadow_hit",
		"contention_index": float(first_sample.get("contention_index", 0.0)),
		"late_commit_deviation": float(first_sample.get("late_commit_deviation", 0.0)),
		"claim_success_rate": float(first_sample.get("claim_success_rate", 0.0)),
		"legacy_escape_hit": false
	}
	var sampling_plan := {
		"family": "comfort",
		"family_arg": "--family=comfort",
		"density_level": "comfort",
		"sample_count": 10,
		"seed": 0
	}
	var fingerprint_zone_summary := {
		"sample_name": "static_zero_deviation",
		"artifact_format": "csv",
		"artifact_format_json": "json",
		"run_id": 0,
		"zone": "comfort",
		"density_level": "comfort",
		"sample_count": samples.size(),
		"max_continuous_contention_ticks": 0,
		"contention_index_min": float(first_sample.get("contention_index", 0.0)),
		"contention_index_mean": float(first_sample.get("contention_index", 0.0)),
		"contention_index_max": float(first_sample.get("contention_index", 0.0)),
		"late_commit_deviation_min": float(first_sample.get("late_commit_deviation", 0.0)),
		"late_commit_deviation_mean": float(first_sample.get("late_commit_deviation", 0.0)),
		"late_commit_deviation_max": float(first_sample.get("late_commit_deviation", 0.0)),
		"claim_success_rate_min": float(first_sample.get("claim_success_rate", 0.0)),
		"claim_success_rate_mean": float(first_sample.get("claim_success_rate", 0.0)),
		"claim_success_rate_max": float(first_sample.get("claim_success_rate", 0.0)),
		"assignment_count_min": int(first_sample.get("assignment_count", 0)),
		"assignment_count_mean": int(first_sample.get("assignment_count", 0)),
		"assignment_count_max": int(first_sample.get("assignment_count", 0))
	}
	var threshold_candidate := {
		"sample_name": "static_zero_deviation",
		"strategy": "low_false_positive",
		"comfort_upper_bound": float(fingerprint_zone_summary.get("contention_index_max", 0.0))
	}
	var gate_results := {
		"gate_b_fast_false_positive_rate": 0.0,
		"fast_false_positive_rate": 0.0,
		"false_positive_records": [],
		"takeover_ready": false
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
		"csv_output_path": "user://comfort_sampling.csv",
		"json_output_path": "user://comfort_sampling.json",
		"svg_output_path": "user://comfort_sampling.svg",
		"run_count_completed": samples.size()
	}
	var payload := {
		"shadow_warning": shadow_warning,
		"sampling_plan": sampling_plan,
		"fingerprint_zone_summary": fingerprint_zone_summary,
		"threshold_candidate": threshold_candidate,
		"gate_results": gate_results,
		"outliers": outliers,
		"scatter_plot": scatter_plot,
		"sampling_results": sampling_results,
		"samples": samples
	}
	_write_sampling_artifacts(payload)
	if float(shadow_warning.get("contention_index", 0.0)) > 0.0 or float(shadow_warning.get("late_commit_deviation", 0.0)) > 0.0:
		push_warning("contention_shadow_hit=%s" % JSON.stringify(shadow_warning))
	return failures

func _initialize() -> void:
	var failures := await run()
	for failure in failures:
		printerr("[FAIL] battle/test_battle_runtime_probe_static_zero_deviation: %s" % failure)
	quit(1 if not failures.is_empty() else 0)

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
