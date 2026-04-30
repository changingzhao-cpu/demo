extends SceneTree

func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/battle/battle_scene.tscn")
	if scene == null:
		printerr("scene_load_failed")
		quit(1)
		return
	var instance: Node = scene.instantiate()
	get_root().add_child(instance)
	await process_frame
	var controller = instance.get_node_or_null("BattleController")
	if controller == null:
		printerr("missing_controller")
		quit(1)
		return
	if controller.has_method("debug_force_simulation_backend"):
		controller.call("debug_force_simulation_backend", "v4")
	await process_frame
	await process_frame
	for _i in range(24):
		if controller.has_method("tick_combat"):
			controller.call("tick_combat", 0.016)
	var runtime_snapshot: Dictionary = controller.call("debug_get_runtime_snapshot") if controller.has_method("debug_get_runtime_snapshot") else {}
	var trace_payload: Dictionary = controller.call("debug_get_runtime_anomaly_trace") if controller.has_method("debug_get_runtime_anomaly_trace") else {}
	var runtime_trace_payload: Dictionary = controller.call("debug_get_runtime_trace_payload") if controller.has_method("debug_get_runtime_trace_payload") else {}
	var v4_probe: Dictionary = runtime_trace_payload.get("probe", {})
	if not v4_probe.has("claim_success_rate"):
		printerr("missing_claim_success_rate")
		quit(1)
		return
	if not v4_probe.has("contention_index"):
		printerr("missing_contention_index")
		quit(1)
		return
	if not v4_probe.has("late_commit_deviation"):
		printerr("missing_late_commit_deviation")
		quit(1)
		return
	var v4_probe_fingerprint := {
		"claim_success_rate": v4_probe.get("claim_success_rate", null),
		"contention_index": v4_probe.get("contention_index", null),
		"late_commit_deviation": v4_probe.get("late_commit_deviation", null),
		"assignment_count": int(v4_probe.get("assignments", {}).size()) if v4_probe.get("assignments", {}) is Dictionary else -1
	}
	var v4_probe_baseline := "claim_success_rate=%s contention_index=%s late_commit_deviation=%s assignment_count=%s" % [
		str(v4_probe_fingerprint.get("claim_success_rate", "missing")),
		str(v4_probe_fingerprint.get("contention_index", "missing")),
		str(v4_probe_fingerprint.get("late_commit_deviation", "missing")),
		str(v4_probe_fingerprint.get("assignment_count", "missing"))
	]
	var contract: Dictionary = controller.call("debug_get_authoritative_battle_contract") if controller.has_method("debug_get_authoritative_battle_contract") else {}
	var tick_report: Dictionary = controller.call("get_last_tick_report") if controller.has_method("get_last_tick_report") else {}
	print(JSON.stringify({
		"runtime_snapshot": runtime_snapshot,
		"trace_payload": trace_payload,
		"runtime_trace_payload": runtime_trace_payload,
		"v4_probe": v4_probe,
		"v4_probe_fingerprint": v4_probe_fingerprint,
		"v4_probe_baseline": v4_probe_baseline,
		"contract": contract,
		"tick_report": tick_report
	}))
	instance.queue_free()
	await process_frame
	quit()
