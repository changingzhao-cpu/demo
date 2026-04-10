extends RefCounted

const BattleControllerScript = preload("res://scripts/battle/battle_controller.gd")
const WAVE_DEFS_PATH := "res://data/wave_defs.json"

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_tick_combat_advances_simulation_work(failures)
	_test_tick_enters_reward_when_enemies_are_gone(failures)
	_test_tick_enters_settle_when_all_allies_are_gone(failures)
	return failures

func _test_tick_combat_advances_simulation_work(failures: Array[String]) -> void:
	var controller = BattleControllerScript.new(WAVE_DEFS_PATH)
	controller.start_run()
	_assert_true(controller.has_method("tick_combat"), "battle controller should expose tick_combat", failures)
	_assert_true(controller.has_method("get_last_tick_report"), "battle controller should expose get_last_tick_report", failures)
	if not controller.has_method("tick_combat") or not controller.has_method("get_last_tick_report"):
		controller.free()
		return
	controller.call("tick_combat", 0.016)
	var report: Dictionary = controller.call("get_last_tick_report")
	_assert_true(int(report.get("processed", 0)) > 0, "tick_combat should process at least one entity during combat", failures)
	_assert_eq(str(controller.get_state()), "combat", "tick_combat should keep combat state while both teams remain alive", failures)
	controller.free()

func _test_tick_enters_reward_when_enemies_are_gone(failures: Array[String]) -> void:
	var controller = BattleControllerScript.new(WAVE_DEFS_PATH)
	controller.start_run()
	if not controller.has_method("tick_combat"):
		failures.append("battle controller should expose tick_combat before reward transition checks")
		controller.free()
		return
	var store = controller.call("get_entity_store")
	var live_entity_ids: Array = controller.call("get_live_entity_ids")
	for entity_id_variant in live_entity_ids:
		var entity_id := int(entity_id_variant)
		if store.team_id[entity_id] == 1:
			store.alive[entity_id] = 0
	controller.call("tick_combat", 0.016)
	_assert_eq(str(controller.get_state()), "reward", "tick_combat should enter reward when all enemies are gone", failures)
	controller.free()

func _test_tick_enters_settle_when_all_allies_are_gone(failures: Array[String]) -> void:
	var controller = BattleControllerScript.new(WAVE_DEFS_PATH)
	controller.start_run()
	if not controller.has_method("tick_combat"):
		failures.append("battle controller should expose tick_combat before settle transition checks")
		controller.free()
		return
	var store = controller.call("get_entity_store")
	var live_entity_ids: Array = controller.call("get_live_entity_ids")
	for entity_id_variant in live_entity_ids:
		var entity_id := int(entity_id_variant)
		if store.team_id[entity_id] == 0:
			store.alive[entity_id] = 0
	controller.call("tick_combat", 0.016)
	_assert_eq(str(controller.get_state()), "settle", "tick_combat should enter settle when all allies are gone", failures)
	controller.free()

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)

func _assert_eq(actual, expected, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s (expected=%s, actual=%s)" % [message, str(expected), str(actual)])
