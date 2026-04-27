extends RefCounted

const BattleController = preload("res://scripts/battle/battle_controller.gd")

func run() -> Array[String]:
	var failures: Array[String] = []
	var controller = BattleController.new()
	controller.debug_force_simulation_backend("v4")
	controller.start_run()
	for _step in range(4):
		controller.tick_combat(0.016)
	var simulation: Variant = controller.get("_simulation")
	var simulation_script: Variant = simulation.get_script() if simulation != null else null
	var simulation_path: String = simulation_script.resource_path if simulation_script != null else ""
	var trace_payload: Dictionary = controller.debug_get_runtime_trace_payload()
	var probe: Dictionary = trace_payload.get("probe", {})
	_assert_eq(simulation_path, "res://scripts/battle/battle_simulation_v4.gd", "controller should instantiate battle_simulation_v4.gd for v4 backend", failures)
	_assert_true(not probe.is_empty(), "v4 backend routing should expose non-empty probe payload", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)

func _assert_eq(actual, expected, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s (expected=%s, actual=%s)" % [message, str(expected), str(actual)])
