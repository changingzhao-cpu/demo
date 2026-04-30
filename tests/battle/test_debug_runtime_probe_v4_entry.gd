extends RefCounted

const BattleController = preload("res://scripts/battle/battle_controller.gd")

func run() -> Array[String]:
	var failures: Array[String] = []
	var controller = BattleController.new()
	controller.debug_force_simulation_backend("v4")
	controller.start_run()
	for _step in range(4):
		controller.tick_combat(0.016)
	var runtime_trace_payload: Dictionary = controller.debug_get_runtime_trace_payload()
	var probe: Dictionary = runtime_trace_payload.get("probe", {})
	_assert_true(not probe.is_empty(), "debug runtime probe entry should read non-empty v4 probe payload", failures)
	_assert_true(probe.has("claim_success_rate"), "debug runtime probe entry should expose claim_success_rate", failures)
	_assert_true(probe.has("contention_index"), "debug runtime probe entry should expose contention_index", failures)
	_assert_true(probe.has("late_commit_deviation"), "debug runtime probe entry should expose late_commit_deviation", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
