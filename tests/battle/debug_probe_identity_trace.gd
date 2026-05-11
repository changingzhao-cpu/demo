extends SceneTree

const WARNING_ARTIFACT_PATH := "user://warning_sampling.json"
const CRITICAL_ARTIFACT_PATH := "user://critical_sampling.json"

func _read_unified_snapshot_summary(path: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(path)
	if text == "":
		return {}
	var json := JSON.new()
	if json.parse(text) != OK:
		return {}
	var payload: Dictionary = json.data
	var unified_snapshot: Dictionary = payload.get("unified_snapshot", {})
	return {
		"family": str(unified_snapshot.get("family", "")),
		"takeover_ready": bool(unified_snapshot.get("takeover_ready", false)),
		"sample_count": int(unified_snapshot.get("sample_count", 0)),
		"confidence_score": float(unified_snapshot.get("confidence_score", -1.0)),
		"thresholds": unified_snapshot.get("thresholds", {}),
		"support_counts": unified_snapshot.get("support_counts", {}),
		"blockers": unified_snapshot.get("blockers", [])
	}

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
	var simulation: Variant = controller.get("_simulation")
	var simulation_script: Variant = simulation.get_script() if simulation != null else null
	var simulation_path: String = simulation_script.resource_path if simulation_script != null else ""
	var backend_name: Variant = simulation.call("get_backend_name") if simulation != null and simulation.has_method("get_backend_name") else "missing"
	var tick_report: Dictionary = controller.call("get_last_tick_report") if controller.has_method("get_last_tick_report") else {}
	var trace_payload: Dictionary = controller.call("debug_get_runtime_trace_payload") if controller.has_method("debug_get_runtime_trace_payload") else {}
	var v4_probe: Dictionary = trace_payload.get("probe", {})
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
	var warning_unified_snapshot := _read_unified_snapshot_summary(WARNING_ARTIFACT_PATH)
	var critical_unified_snapshot := _read_unified_snapshot_summary(CRITICAL_ARTIFACT_PATH)
	if warning_unified_snapshot.is_empty():
		printerr("missing_warning_unified_snapshot")
		quit(1)
		return
	if critical_unified_snapshot.is_empty():
		printerr("missing_critical_unified_snapshot")
		quit(1)
		return
	print(JSON.stringify({
		"backend_name": backend_name,
		"simulation_script_path": simulation_path,
		"tick_report": tick_report,
		"trace_payload": trace_payload,
		"v4_probe": v4_probe,
		"v4_probe_fingerprint": v4_probe_fingerprint,
		"v4_probe_baseline": v4_probe_baseline,
		"warning_unified_snapshot": warning_unified_snapshot,
		"critical_unified_snapshot": critical_unified_snapshot
	}))
	instance.queue_free()
	await process_frame
	quit()
