extends RefCounted

const BattleControllerScript = preload("res://scripts/battle/battle_controller.gd")
const WAVE_DEFS_PATH := "res://data/wave_defs.json"

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_start_run_enters_combat_and_returns_wave(failures)
	_test_handle_wave_clear_enters_reward_and_exposes_current_wave(failures)
	_test_claim_reward_advances_back_to_combat(failures)
	_test_handle_run_failed_enters_settle(failures)
	_test_v4_probe_bridge_exists_and_updates_trace_payload(failures)
	return failures

func _test_start_run_enters_combat_and_returns_wave(failures: Array[String]) -> void:
	var controller = BattleControllerScript.new(WAVE_DEFS_PATH)
	var wave: Dictionary = controller.start_run()
	_assert_eq(controller.get_state(), "combat", "start_run should enter combat state", failures)
	_assert_eq(int(wave.get("wave", -1)), 1, "start_run should return wave 1", failures)
	_assert_eq(int(controller.get_current_wave().get("wave", -1)), 1, "current wave should track the active wave", failures)
	controller.free()

func _test_handle_wave_clear_enters_reward_and_exposes_current_wave(failures: Array[String]) -> void:
	var controller = BattleControllerScript.new(WAVE_DEFS_PATH)
	controller.start_run()
	controller.handle_wave_clear()
	_assert_eq(controller.get_state(), "reward", "handle_wave_clear should enter reward state", failures)
	_assert_eq(int(controller.get_current_wave().get("wave", -1)), 1, "reward state should still reference the cleared wave until claim", failures)
	controller.free()

func _test_claim_reward_advances_back_to_combat(failures: Array[String]) -> void:
	var controller = BattleControllerScript.new(WAVE_DEFS_PATH)
	controller.start_run()
	controller.handle_wave_clear()
	var next_wave: Dictionary = controller.claim_reward_and_advance()
	_assert_eq(controller.get_state(), "combat", "claim_reward_and_advance should return to combat", failures)
	_assert_eq(int(next_wave.get("wave", -1)), 2, "claim_reward_and_advance should return wave 2", failures)
	_assert_eq(int(controller.get_current_wave().get("wave", -1)), 2, "current wave should advance after reward claim", failures)
	controller.free()

func _test_handle_run_failed_enters_settle(failures: Array[String]) -> void:
	var controller = BattleControllerScript.new(WAVE_DEFS_PATH)
	controller.start_run()
	controller.handle_run_failed()
	_assert_eq(controller.get_state(), "settle", "handle_run_failed should enter settle state", failures)
	controller.free()

func _test_v4_probe_bridge_exists_and_updates_trace_payload(failures: Array[String]) -> void:
	var controller = BattleControllerScript.new(WAVE_DEFS_PATH)
	_controller_start_and_emit_probe(controller)
	_assert_true(controller.has_method("emit_v4_probe_event"), "battle controller should expose emit_v4_probe_event bridge", failures)
	var payload: Dictionary = controller.debug_get_runtime_trace_payload()
	_assert_true(payload.has("business_probe_events"), "battle controller runtime trace payload should expose business_probe_events", failures)
	var events: Array = payload.get("business_probe_events", [])
	_assert_true(events.size() == 1, "battle controller probe bridge should append one event", failures)
	_assert_true(str(events[0].get("event_type", "")) == "integration_test", "battle controller probe bridge should preserve event_type", failures)
	controller.free()

func _controller_start_and_emit_probe(controller) -> void:
	controller.start_run()
	controller.emit_v4_probe_event({"event_type": "integration_test", "state": controller.get_state()})

func _assert_eq(actual, expected, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s (expected=%s, actual=%s)" % [message, str(expected), str(actual)])

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
