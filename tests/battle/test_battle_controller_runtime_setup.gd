extends RefCounted

const BattleControllerScript = preload("res://scripts/battle/battle_controller.gd")
const WAVE_DEFS_PATH := "res://data/wave_defs.json"

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_start_run_creates_runtime_dependencies(failures)
	_test_start_run_seeds_friendly_and_enemy_units(failures)
	_test_controller_can_switch_to_battle_simulation_v2(failures)
	return failures

func _test_start_run_creates_runtime_dependencies(failures: Array[String]) -> void:
	var controller = BattleControllerScript.new(WAVE_DEFS_PATH)
	controller.start_run()
	_assert_true(controller.has_method("get_entity_store"), "battle controller should expose get_entity_store", failures)
	_assert_true(controller.has_method("get_spatial_grid"), "battle controller should expose get_spatial_grid", failures)
	_assert_true(controller.has_method("get_simulation"), "battle controller should expose get_simulation", failures)
	if controller.has_method("get_entity_store"):
		_assert_true(controller.call("get_entity_store") != null, "start_run should create an entity store", failures)
	if controller.has_method("get_spatial_grid"):
		_assert_true(controller.call("get_spatial_grid") != null, "start_run should create a spatial grid", failures)
	if controller.has_method("get_simulation"):
		_assert_true(controller.call("get_simulation") != null, "start_run should create a battle simulation", failures)
	controller.free()

func _test_start_run_seeds_friendly_and_enemy_units(failures: Array[String]) -> void:
	var controller = BattleControllerScript.new(WAVE_DEFS_PATH)
	var wave: Dictionary = controller.start_run()
	_assert_true(controller.has_method("get_live_entity_ids"), "battle controller should expose live runtime entities", failures)
	if not controller.has_method("get_entity_store") or not controller.has_method("get_live_entity_ids"):
		controller.free()
		return
	var store = controller.call("get_entity_store")
	var live_entity_ids: Array = controller.call("get_live_entity_ids")
	_assert_true(store != null, "entity store should exist after start_run", failures)
	_assert_eq(store.active_count, live_entity_ids.size(), "active_count should match live runtime entities", failures)
	_assert_true(live_entity_ids.size() > int(wave.get("enemy_count", 0)), "runtime setup should include allied units in addition to enemies", failures)
	var ally_count := 0
	var enemy_count := 0
	for entity_id_variant in live_entity_ids:
		var entity_id := int(entity_id_variant)
		if store.team_id[entity_id] == 0:
			ally_count += 1
		elif store.team_id[entity_id] == 1:
			enemy_count += 1
	_assert_true(ally_count > 0, "runtime setup should seed at least one allied unit", failures)
	_assert_eq(enemy_count, int(wave.get("enemy_count", -1)), "runtime setup should seed the current wave enemy count", failures)
	controller.free()

func _test_controller_can_switch_to_battle_simulation_v2(failures: Array[String]) -> void:
	var controller = BattleControllerScript.new(WAVE_DEFS_PATH)
	controller.call("debug_force_simulation_backend", "v2")
	controller.start_run()
	var contract: Dictionary = controller.call("debug_get_authoritative_battle_contract")
	_assert_true(str(contract.get("ticksource", "")) == "battle_simulation_v2", "battle controller should expose v2 authoritative contract when backend is switched to v2", failures)
	controller.free()

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)

func _assert_eq(actual, expected, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s (expected=%s, actual=%s)" % [message, str(expected), str(actual)])
