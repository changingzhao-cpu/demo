extends SceneTree

func run() -> Array[String]:
	var failures: Array[String] = []
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
		"sample_count": 1,
		"max_continuous_contention_ticks": 0
	}
	return failures

func _initialize() -> void:
	var failures := await run()
	for failure in failures:
		printerr("[FAIL] battle/test_battle_runtime_probe_medium_density_filled_slots: %s" % failure)
	quit(1 if not failures.is_empty() else 0)
