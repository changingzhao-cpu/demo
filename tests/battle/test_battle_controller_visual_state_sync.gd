extends RefCounted

const BattleControllerScript = preload("res://scripts/battle/battle_controller.gd")
const WAVE_DEFS_PATH := "res://data/wave_defs.json"

class RecordingView:
	extends RefCounted

	var last_position := Vector2.ZERO
	var last_alive := true
	var last_team := -1
	var last_speed := 0.0
	var last_facing := 0.0
	var sync_calls := 0

	func bind_entity(_entity_id: int) -> void:
		pass

	func sync_from_entity_visual(world_position: Vector2, is_alive: bool, team_id: int, move_speed: float, facing_sign: float) -> void:
		last_position = world_position
		last_alive = is_alive
		last_team = team_id
		last_speed = move_speed
		last_facing = facing_sign
		sync_calls += 1

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_sync_unit_views_pushes_visual_runtime_state(failures)
	_test_sync_unit_views_marks_dead_visual_state(failures)
	_test_sync_unit_views_faces_target_direction_even_before_movement(failures)
	return failures

func _test_sync_unit_views_pushes_visual_runtime_state(failures: Array[String]) -> void:
	var controller = BattleControllerScript.new(WAVE_DEFS_PATH)
	controller.start_run()
	var live_entity_ids: Array = controller.call("get_live_entity_ids")
	_assert_true(not live_entity_ids.is_empty(), "battle controller should create live entities before visual sync", failures)
	if live_entity_ids.is_empty():
		controller.free()
		return
	var entity_id := int(live_entity_ids[0])
	var store = controller.call("get_entity_store")
	store.position_x[entity_id] = 14.0
	store.position_y[entity_id] = -3.5
	store.move_speed[entity_id] = 2.75
	var view = RecordingView.new()
	controller.call("register_unit_view", entity_id, view)
	controller.call("sync_unit_views")
	_assert_eq(view.last_position, Vector2(14.0, -3.5), "visual sync should push entity position into runtime views", failures)
	_assert_true(view.last_alive, "visual sync should mark live entities as alive", failures)
	_assert_eq(view.last_team, 0, "visual sync should expose ally team id", failures)
	_assert_eq(view.last_speed, 2.75, "visual sync should expose move speed for presentation", failures)
	_assert_eq(view.last_facing, 1.0, "visual sync should expose ally-facing direction", failures)
	_assert_true(view.sync_calls > 0, "visual sync should call the visual sync method", failures)
	controller.free()

func _test_sync_unit_views_marks_dead_visual_state(failures: Array[String]) -> void:
	var controller = BattleControllerScript.new(WAVE_DEFS_PATH)
	controller.start_run()
	var live_entity_ids: Array = controller.call("get_live_entity_ids")
	_assert_true(live_entity_ids.size() > 6, "battle controller should create an enemy entity for visual dead-state checks", failures)
	if live_entity_ids.size() <= 6:
		controller.free()
		return
	var entity_id := int(live_entity_ids[6])
	var store = controller.call("get_entity_store")
	store.alive[entity_id] = 0
	store.position_x[entity_id] = -6.0
	store.position_y[entity_id] = 9.5
	store.move_speed[entity_id] = 1.25
	var view = RecordingView.new()
	controller.call("register_unit_view", entity_id, view)
	controller.call("sync_unit_views")
	_assert_false(view.last_alive, "visual sync should report dead entities as dead", failures)
	_assert_eq(view.last_team, 1, "visual sync should preserve enemy team id for dead views", failures)
	_assert_eq(view.last_position, Vector2(-6.0, 9.5), "visual sync should preserve the latest entity position for death feedback", failures)
	_assert_eq(view.last_facing, -1.0, "visual sync should expose enemy-facing direction", failures)
	controller.free()

func _test_sync_unit_views_faces_target_direction_even_before_movement(failures: Array[String]) -> void:
	var controller = BattleControllerScript.new(WAVE_DEFS_PATH)
	controller.start_run()
	var live_entity_ids: Array = controller.call("get_live_entity_ids")
	_assert_true(live_entity_ids.size() > 6, "battle controller should create enough entities for facing-direction checks", failures)
	if live_entity_ids.size() <= 6:
		controller.free()
		return
	var ally_id := int(live_entity_ids[0])
	var enemy_id := int(live_entity_ids[6])
	var store = controller.call("get_entity_store")
	store.position_x[ally_id] = 0.0
	store.position_y[ally_id] = 0.0
	store.velocity_x[ally_id] = 0.0
	store.velocity_y[ally_id] = 0.0
	store.target_id[ally_id] = enemy_id
	store.position_x[enemy_id] = 5.0
	store.position_y[enemy_id] = 0.0
	var right_view = RecordingView.new()
	controller.call("register_unit_view", ally_id, right_view)
	controller.call("sync_unit_views")
	_assert_eq(right_view.last_facing, 1.0, "visual sync should face right as soon as the target is on the right even before movement starts", failures)
	store.position_x[enemy_id] = -5.0
	var left_view = RecordingView.new()
	controller.call("register_unit_view", ally_id, left_view)
	controller.call("sync_unit_views")
	_assert_eq(left_view.last_facing, -1.0, "visual sync should face left as soon as the target is on the left even before movement starts", failures)
	controller.free()

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)

func _assert_false(value: bool, message: String, failures: Array[String]) -> void:
	if value:
		failures.append(message)

func _assert_eq(actual, expected, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s (expected=%s, actual=%s)" % [message, str(expected), str(actual)])
