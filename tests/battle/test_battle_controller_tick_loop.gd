extends RefCounted

const BattleControllerScript = preload("res://scripts/battle/battle_controller.gd")
const WAVE_DEFS_PATH := "res://data/wave_defs.json"

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_tick_combat_advances_simulation_work(failures)
	_test_tick_enters_reward_when_enemies_are_gone(failures)
	_test_tick_enters_settle_when_all_allies_are_gone(failures)
	_test_tick_preserves_recent_death_data_before_cleanup(failures)
	_test_attack_lock_blocks_immediate_movement(failures)
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

func _test_tick_preserves_recent_death_data_before_cleanup(failures: Array[String]) -> void:
	var controller = BattleControllerScript.new(WAVE_DEFS_PATH)
	controller.start_run()
	var store = controller.call("get_entity_store")
	var live_entity_ids: Array = controller.call("get_live_entity_ids")
	var expected_team := -1
	var expected_position := Vector2.ZERO
	var forced_enemy_id := -1
	for entity_id_variant in live_entity_ids:
		var entity_id := int(entity_id_variant)
		if store.team_id[entity_id] == 1:
			expected_team = store.team_id[entity_id]
			expected_position = Vector2(store.position_x[entity_id], store.position_y[entity_id])
			forced_enemy_id = entity_id
			break
	if forced_enemy_id != -1:
		store.alive[forced_enemy_id] = 0
	controller.call("tick_combat", 0.016)
	var death_events: Array = controller.call("get_recently_died_entities")
	_assert_true(not death_events.is_empty(), "tick_combat should retain recent death events after a kill", failures)
	if not death_events.is_empty():
		var death_event: Dictionary = death_events[0]
		_assert_eq(str(death_event.get("team", "")), "enemy" if expected_team == 1 else "ally", "death event should preserve the killed unit team before cleanup", failures)
		_assert_true(death_event.get("position", Vector2.ZERO) != Vector2.ZERO, "death event should preserve the killed unit position before cleanup", failures)
		_assert_true(Vector2(death_event.get("position", Vector2.ZERO)).distance_to(expected_position) < 0.8, "death event should stay near the killed unit's last position", failures)
	controller.free()

func _test_attack_lock_blocks_immediate_movement(failures: Array[String]) -> void:
	var controller = BattleControllerScript.new(WAVE_DEFS_PATH)
	controller.start_run()
	var store = controller.call("get_entity_store")
	var live_entity_ids: Array = controller.call("get_live_entity_ids")
	var attacker_id := -1
	var target_id := -1
	for entity_id_variant in live_entity_ids:
		var entity_id := int(entity_id_variant)
		if store.team_id[entity_id] == 0:
			attacker_id = entity_id
			break
	for entity_id_variant in live_entity_ids:
		var entity_id := int(entity_id_variant)
		if store.team_id[entity_id] == 1:
			target_id = entity_id
			break
	if attacker_id == -1 or target_id == -1:
		failures.append("tick loop attack lock test requires ally and enemy entities")
		controller.free()
		return
	store.position_x[attacker_id] = 0.0
	store.position_y[attacker_id] = 0.0
	store.position_x[target_id] = 1.0
	store.position_y[target_id] = 0.0
	store.target_id[attacker_id] = target_id
	store.attack_cd[attacker_id] = 0.0
	controller.call("tick_combat", 0.016)
	var locked_position := Vector2(store.position_x[attacker_id], store.position_y[attacker_id])
	controller.call("tick_combat", 0.016)
	var after_followup_tick := Vector2(store.position_x[attacker_id], store.position_y[attacker_id])
	_assert_true(locked_position.distance_to(after_followup_tick) <= 0.001, "unit should remain locked in place immediately after attacking instead of moving before the attack pose finishes", failures)
	controller.free()

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)

func _assert_eq(actual, expected, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s (expected=%s, actual=%s)" % [message, str(expected), str(actual)])
