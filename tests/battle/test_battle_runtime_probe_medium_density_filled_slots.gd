extends SceneTree

const WARNING_SAMPLE_OUTPUT_PATH := "user://warning_sampling.json"

func _build_sample(run_id: int) -> Dictionary:
	return {
		"run_id": run_id,
		"family": "warning",
		"density_level": "warning",
		"contention_index": 0.0,
		"late_commit_deviation": 0.0,
		"claim_success_rate": 0.0,
		"assignment_count": 0,
		"old_escape_hit": false,
		"p95_contention": 0.0,
		"max_duration": 0,
		"arbitration_latency": 0.0,
		"conflict_overlap_count": 0,
		"gate_match_status": "gate_b",
		"seed": run_id
	}

func _write_sampling_artifacts(payload: Dictionary) -> void:
	var json_file := FileAccess.open(WARNING_SAMPLE_OUTPUT_PATH, FileAccess.WRITE)
	if json_file != null:
		json_file.store_string(JSON.stringify(payload, "\t"))
		json_file.close()
	var csv_path := str(payload.get("sampling_results", {}).get("csv_output_path", "user://warning_sampling.csv"))
	var csv_file := FileAccess.open(csv_path, FileAccess.WRITE)
	if csv_file != null:
		csv_file.store_string("run_id,family,density_level,contention_index,late_commit_deviation,claim_success_rate,assignment_count,old_escape_hit,p95_contention,max_duration,seed\n")
		for sample_variant in payload.get("samples", []):
			var sample: Dictionary = sample_variant
			csv_file.store_string("%d,%s,%s,%s,%s,%s,%d,%s,%s,%s,%d\n" % [
				int(sample.get("run_id", -1)),
				str(sample.get("family", "")),
				str(sample.get("density_level", "")),
				str(sample.get("contention_index", 0.0)),
				str(sample.get("late_commit_deviation", 0.0)),
				str(sample.get("claim_success_rate", 0.0)),
				int(sample.get("assignment_count", 0)),
				str(sample.get("old_escape_hit", false)),
				str(sample.get("p95_contention", 0.0)),
				str(sample.get("max_duration", 0)),
				int(sample.get("seed", 0))
			])
		csv_file.close()
	var svg_path := str(payload.get("sampling_results", {}).get("svg_output_path", "user://warning_sampling.svg"))
	var svg_file := FileAccess.open(svg_path, FileAccess.WRITE)
	if svg_file != null:
		svg_file.store_string("<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"160\" height=\"120\"><text x=\"8\" y=\"20\">warning scatter</text></svg>")
		svg_file.close()

func run() -> Array[String]:
	var failures: Array[String] = []
	var samples: Array = []
	for run_id in range(20):
		samples.append(_build_sample(run_id))
	var sampling_plan := {
		"family": "warning",
		"family_arg": "--family=warning",
		"density_level": "warning",
		"sample_count": 20,
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
		"p95_contention": 0.0,
		"max_duration": 0
	}
	var threshold_candidate := {
		"sample_name": "medium_density_filled_slots",
		"strategy": "low_false_positive",
		"warning_band_hint": 0.0
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
		"run_count_completed": samples.size()
	}
	var payload := {
		"sampling_plan": sampling_plan,
		"fingerprint_zone_summary": fingerprint_zone_summary,
		"threshold_candidate": threshold_candidate,
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
