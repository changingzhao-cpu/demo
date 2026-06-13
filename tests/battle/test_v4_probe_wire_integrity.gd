extends RefCounted

const BattleController = preload("res://scripts/battle/battle_controller.gd")

func run() -> Array[String]:
	var failures: Array[String] = []
	var controller = BattleController.new()
	controller.debug_force_simulation_backend("v4")
	controller.start_run()
	for _step in range(4):
		controller.tick_combat(0.016)
	var runtime_snapshot: Dictionary = controller.get_runtime_snapshot()
	var last_tick_report: Dictionary = controller.get_last_tick_report()
	var runtime_trace_payload: Dictionary = controller.debug_get_runtime_trace_payload()
	_assert_eq(str(runtime_snapshot.get("backend", "")), "v4", "runtime snapshot should report v4 backend", failures)
	_assert_eq(str(runtime_snapshot.get("state", "")), "combat", "runtime snapshot should stay in combat during wire fixture", failures)
	_assert_true(int(last_tick_report.get("processed", 0)) > 0, "last tick report should show a processed combat tick", failures)
	_assert_true(runtime_trace_payload.has("probe"), "runtime trace payload should expose probe dictionary", failures)
	var probe: Dictionary = runtime_trace_payload.get("probe", {})
	_assert_true(not probe.is_empty(), "runtime trace probe should be non-empty after combat tick", failures)
	_assert_true(probe.has("claim_success_rate"), "runtime trace probe should expose claim_success_rate", failures)
	_assert_true(probe.has("contention_index"), "runtime trace probe should expose contention_index", failures)
	_assert_true(probe.has("late_commit_deviation"), "runtime trace probe should expose late_commit_deviation", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)

func _assert_eq(actual, expected, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s (expected=%s, actual=%s)" % [message, str(expected), str(actual)])
