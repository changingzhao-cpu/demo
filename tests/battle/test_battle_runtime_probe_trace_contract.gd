extends SceneTree

func run() -> Array[String]:
	var failures: Array[String] = []
	var scene: PackedScene = load("res://scenes/battle/battle_scene.tscn")
	if scene == null:
		failures.append("trace contract fixture should load battle scene")
		return failures
	var instance: Node = scene.instantiate()
	get_root().add_child(instance)
	await process_frame
	var controller = instance.get_node_or_null("BattleController")
	if controller == null:
		failures.append("trace contract fixture should find BattleController")
		instance.queue_free()
		await process_frame
		return failures
	if controller.has_method("debug_force_simulation_backend"):
		controller.call("debug_force_simulation_backend", "v4")
	await process_frame
	await process_frame
	if controller.has_method("advance_debug_frames"):
		controller.call("advance_debug_frames", 24, 0.016)
	var runtime_snapshot: Dictionary = controller.call("debug_get_runtime_snapshot") if controller.has_method("debug_get_runtime_snapshot") else {}
	var trace_payload: Dictionary = controller.call("debug_get_runtime_anomaly_trace") if controller.has_method("debug_get_runtime_anomaly_trace") else {}
	var probe: Dictionary = trace_payload.get("probe", {})
	_assert_eq(str(runtime_snapshot.get("backend", "")), "v4", "runtime snapshot should report v4 backend", failures)
	_assert_true(trace_payload.has("backend"), "runtime anomaly trace should expose backend", failures)
	_assert_eq(str(trace_payload.get("backend", "")), "v4", "runtime anomaly trace should report v4 backend", failures)
	_assert_true(trace_payload.has("history_limit"), "runtime anomaly trace should expose history_limit", failures)
	_assert_true(trace_payload.has("samples"), "runtime anomaly trace should expose bounded samples", failures)
	_assert_true(trace_payload.has("movement_anomalies"), "runtime anomaly trace should expose movement anomalies", failures)
	_assert_true(not probe.is_empty(), "runtime anomaly trace should expose non-empty v4 probe", failures)
	_assert_true(probe.has("claim_success_rate"), "runtime anomaly trace should expose v4 claim_success_rate", failures)
	_assert_true(probe.has("contention_index"), "runtime anomaly trace should expose v4 contention_index", failures)
	_assert_true(probe.has("late_commit_deviation"), "runtime anomaly trace should expose v4 late_commit_deviation", failures)
	instance.queue_free()
	await process_frame
	return failures

func _initialize() -> void:
	var failures := await run()
	for failure in failures:
		printerr("[FAIL] battle/test_battle_runtime_probe_trace_contract: %s" % failure)
	quit(1 if not failures.is_empty() else 0)

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)

func _assert_eq(actual, expected, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s (expected=%s, actual=%s)" % [message, str(expected), str(actual)])
