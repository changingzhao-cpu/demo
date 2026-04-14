extends RefCounted

const BattleControllerScript = preload("res://scripts/battle/battle_controller.gd")
const UnitViewScript = preload("res://scripts/presentation/unit_view.gd")
const WAVE_DEFS_PATH := "res://data/wave_defs.json"

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_sync_unit_views_updates_positions(failures)
	_test_sync_unit_views_hides_dead_entities(failures)
	_test_sync_unit_views_keeps_visual_radius_small_and_pulses_bounded(failures)
	_test_battle_scene_screen_payloads_preserve_runtime_spread(failures)
	return failures

func _test_sync_unit_views_updates_positions(failures: Array[String]) -> void:
	var controller = BattleControllerScript.new(WAVE_DEFS_PATH)
	controller.start_run()
	_assert_true(controller.has_method("register_unit_view"), "battle controller should expose register_unit_view", failures)
	_assert_true(controller.has_method("sync_unit_views"), "battle controller should expose sync_unit_views", failures)
	if not controller.has_method("register_unit_view") or not controller.has_method("sync_unit_views"):
		controller.free()
		return
	var live_entity_ids: Array = controller.call("get_live_entity_ids")
	if live_entity_ids.is_empty():
		failures.append("battle controller should create live entities before syncing views")
		controller.free()
		return
	var entity_id := int(live_entity_ids[0])
	var store = controller.call("get_entity_store")
	store.position_x[entity_id] = 21.5
	store.position_y[entity_id] = -4.25
	var view = UnitViewScript.new()
	controller.call("register_unit_view", entity_id, view)
	controller.call("sync_unit_views")
	_assert_eq(view.global_position, Vector2(21.5, -4.25), "sync_unit_views should push entity position into bound views", failures)
	_assert_true(view.visible, "sync_unit_views should keep live bound views visible", failures)
	view.free()
	controller.free()

func _test_sync_unit_views_hides_dead_entities(failures: Array[String]) -> void:
	var controller = BattleControllerScript.new(WAVE_DEFS_PATH)
	controller.start_run()
	if not controller.has_method("register_unit_view") or not controller.has_method("sync_unit_views"):
		failures.append("battle controller should expose runtime view sync methods")
		controller.free()
		return
	var live_entity_ids: Array = controller.call("get_live_entity_ids")
	if live_entity_ids.is_empty():
		failures.append("battle controller should create live entities before syncing dead views")
		controller.free()
		return
	var entity_id := int(live_entity_ids[0])
	var store = controller.call("get_entity_store")
	var view = UnitViewScript.new()
	controller.call("register_unit_view", entity_id, view)
	store.alive[entity_id] = 0
	controller.call("sync_unit_views")
	_assert_false(view.visible, "sync_unit_views should hide views for dead entities", failures)
	view.free()
	controller.free()

func _test_sync_unit_views_keeps_visual_radius_small_and_pulses_bounded(failures: Array[String]) -> void:
	var controller = BattleControllerScript.new(WAVE_DEFS_PATH)
	controller.start_run()
	var live_entity_ids: Array = controller.call("get_live_entity_ids")
	if live_entity_ids.size() < 7:
		failures.append("battle controller should create ally and enemy entities before visual bound checks")
		controller.free()
		return
	var ally_id := int(live_entity_ids[0])
	var enemy_id := int(live_entity_ids[6])
	var ally_view = UnitViewScript.new()
	var enemy_view = UnitViewScript.new()
	controller.call("register_unit_view", ally_id, ally_view)
	controller.call("register_unit_view", enemy_id, enemy_view)
	controller.call("sync_unit_views")
	_assert_true(ally_view.has_method("get_visual_radius"), "unit view should expose get_visual_radius for visual bound checks", failures)
	_assert_true(enemy_view.has_method("get_visual_radius"), "enemy unit view should expose get_visual_radius for visual bound checks", failures)
	if ally_view.has_method("get_visual_radius"):
		_assert_true(float(ally_view.call("get_visual_radius")) <= 3.4, "ally unit visuals should keep a small radius to avoid giant battlefield blobs", failures)
	if enemy_view.has_method("get_visual_radius"):
		_assert_true(float(enemy_view.call("get_visual_radius")) <= 3.4, "enemy unit visuals should keep a small radius to avoid swarm blobs", failures)
	ally_view.call("trigger_attack_pulse")
	enemy_view.call("trigger_hit_pulse")
	_assert_true(float(ally_view.call("get_visual_radius")) <= 3.4, "attack pulses should not increase ally base visual radius", failures)
	_assert_true(float(enemy_view.call("get_visual_radius")) <= 3.4, "hit pulses should not increase enemy base visual radius", failures)
	_assert_true(float(ally_view.call("get_visual_motion_strength")) <= 1.5, "ally pulse feedback should remain visually bounded instead of exploding scale", failures)
	_assert_true(float(enemy_view.call("get_visual_motion_strength")) <= 1.5, "enemy pulse feedback should remain visually bounded instead of exploding scale", failures)
	ally_view.free()
	enemy_view.free()
	controller.free()

func _test_battle_scene_screen_payloads_preserve_runtime_spread(failures: Array[String]) -> void:
	var controller = BattleControllerScript.new(WAVE_DEFS_PATH)
	controller.start_run()
	if not controller.has_method("get_visible_entity_screen_payloads"):
		failures.append("battle controller should expose battle scene screen payloads")
		controller.free()
		return
	var payloads: Array = controller.call("get_visible_entity_screen_payloads", 32, Vector2(640.0, 392.0), Vector2(28.0, 20.0))
	var ally_positions: Array[Vector2] = []
	var enemy_positions: Array[Vector2] = []
	for payload_variant in payloads:
		var payload: Dictionary = payload_variant
		var position: Vector2 = payload.get("position", Vector2.ZERO)
		if int(payload.get("team_id", -1)) == 0:
			ally_positions.append(position)
		elif int(payload.get("team_id", -1)) == 1:
			enemy_positions.append(position)
	_assert_true(_x_spread(ally_positions) >= 180.0, "battle scene ally screen payloads should preserve visible horizontal spread instead of collapsing near one anchor", failures)
	_assert_true(_x_spread(enemy_positions) >= 180.0, "battle scene enemy screen payloads should preserve visible horizontal spread instead of collapsing near one anchor", failures)
	controller.free()

func _x_spread(positions: Array[Vector2]) -> float:
	if positions.is_empty():
		return 0.0
	var min_x := positions[0].x
	var max_x := positions[0].x
	for position in positions:
		min_x = minf(min_x, position.x)
		max_x = maxf(max_x, position.x)
	return max_x - min_x

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)

func _assert_false(value: bool, message: String, failures: Array[String]) -> void:
	if value:
		failures.append(message)

func _assert_eq(actual, expected, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s (expected=%s, actual=%s)" % [message, str(expected), str(actual)])
