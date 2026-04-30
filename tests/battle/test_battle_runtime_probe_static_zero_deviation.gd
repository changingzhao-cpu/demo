extends SceneTree

const BATTLE_SCENE_PATH := "res://scenes/battle/battle_scene.tscn"

func run() -> Array[String]:
	var failures: Array[String] = []
	var scene: PackedScene = load(BATTLE_SCENE_PATH)
	if scene == null:
		failures.append("static zero deviation fixture should load battle scene")
		return failures
	var instance: Node = scene.instantiate()
	get_root().add_child(instance)
	await process_frame
	var controller = instance.get_node_or_null("BattleController")
	if controller != null and controller.has_method("debug_force_simulation_backend"):
		controller.call("debug_force_simulation_backend", "v4")
	await process_frame
	await process_frame
	for _i in range(8):
		await create_timer(0.05).timeout
	var runtime_trace_payload: Dictionary = controller.call("debug_get_runtime_trace_payload") if controller != null and controller.has_method("debug_get_runtime_trace_payload") else {}
	var probe: Dictionary = runtime_trace_payload.get("probe", {})
	_assert_true(not probe.is_empty(), "static zero deviation fixture should capture non-empty probe", failures)
	_assert_true(float(probe.get("late_commit_deviation", -1.0)) == 0.0, "static zero deviation fixture should keep late_commit_deviation at zero", failures)
	var shadow_warning := {
		"sample_name": "static_zero_deviation",
		"warning_type": "contention_shadow_hit",
		"contention_index": float(probe.get("contention_index", 0.0)),
		"late_commit_deviation": float(probe.get("late_commit_deviation", 0.0)),
		"claim_success_rate": float(probe.get("claim_success_rate", 0.0)),
		"legacy_escape_hit": false
	}
	var sampling_plan := {
		"family": "comfort",
		"family_arg": "--family=comfort",
		"density_level": "comfort",
		"sample_count": 10
	}
	var fingerprint_zone_summary := {
		"sample_name": "static_zero_deviation",
		"artifact_format": "csv",
		"artifact_format_json": "json",
		"run_id": 0,
		"zone": "comfort",
		"density_level": "comfort",
		"sample_count": 1,
		"max_continuous_contention_ticks": 0,
		"contention_index_min": float(probe.get("contention_index", 0.0)),
		"contention_index_mean": float(probe.get("contention_index", 0.0)),
		"contention_index_max": float(probe.get("contention_index", 0.0)),
		"late_commit_deviation_min": float(probe.get("late_commit_deviation", 0.0)),
		"late_commit_deviation_mean": float(probe.get("late_commit_deviation", 0.0)),
		"late_commit_deviation_max": float(probe.get("late_commit_deviation", 0.0)),
		"claim_success_rate_min": float(probe.get("claim_success_rate", 0.0)),
		"claim_success_rate_mean": float(probe.get("claim_success_rate", 0.0)),
		"claim_success_rate_max": float(probe.get("claim_success_rate", 0.0)),
		"assignment_count_min": int(probe.get("assignments", {}).size()) if probe.get("assignments", {}) is Dictionary else 0,
		"assignment_count_mean": int(probe.get("assignments", {}).size()) if probe.get("assignments", {}) is Dictionary else 0,
		"assignment_count_max": int(probe.get("assignments", {}).size()) if probe.get("assignments", {}) is Dictionary else 0
	}
	var threshold_candidate := {
		"sample_name": "static_zero_deviation",
		"strategy": "low_false_positive",
		"comfort_upper_bound": float(fingerprint_zone_summary.get("contention_index_max", 0.0))
	}
	var gate_results := {
		"fast_false_positive_rate": 0.0,
		"takeover_ready": false
	}
	if float(shadow_warning.get("contention_index", 0.0)) > 0.0 or float(shadow_warning.get("late_commit_deviation", 0.0)) > 0.0:
		push_warning("contention_shadow_hit=%s" % JSON.stringify(shadow_warning))
	var anomaly_scan: Dictionary = controller.call("get_last_tick_report").get("anomaly_scan", {}) if controller != null and controller.has_method("get_last_tick_report") else {}
	_assert_true(int(anomaly_scan.get("attack_rebind_escape_count", 0)) == 0, "static zero deviation fixture should not report attack rebind escapes", failures)
	instance.queue_free()
	await process_frame
	return failures

func _initialize() -> void:
	var failures := await run()
	for failure in failures:
		printerr("[FAIL] battle/test_battle_runtime_probe_static_zero_deviation: %s" % failure)
	quit(1 if not failures.is_empty() else 0)

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
