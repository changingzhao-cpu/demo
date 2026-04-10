extends RefCounted

const BattleControllerScript = preload("res://scripts/battle/battle_controller.gd")
const UnitViewScript = preload("res://scripts/presentation/unit_view.gd")
const WAVE_DEFS_PATH := "res://data/wave_defs.json"

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_sync_unit_views_updates_positions(failures)
	_test_sync_unit_views_hides_dead_entities(failures)
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

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)

func _assert_false(value: bool, message: String, failures: Array[String]) -> void:
	if value:
		failures.append(message)

func _assert_eq(actual, expected, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s (expected=%s, actual=%s)" % [message, str(expected), str(actual)])
