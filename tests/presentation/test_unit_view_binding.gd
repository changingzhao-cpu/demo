extends RefCounted

const UnitViewScript = preload("res://scripts/presentation/unit_view.gd")

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_bind_sets_entity_and_shows_view(failures)
	_test_bind_creates_visible_body_sprite(failures)
	_test_sync_position_updates_global_position(failures)
	_test_unbind_hides_view_and_clears_entity(failures)
	return failures

func _test_bind_creates_visible_body_sprite(failures: Array[String]) -> void:
	var view = UnitViewScript.new()
	view.bind_entity(8)
	var snapshot: Dictionary = view.call("debug_get_sprite_snapshot")
	_assert_true(bool(snapshot.get("body_exists", false)), "bind_entity should create a BodySprite immediately", failures)
	_assert_true(bool(snapshot.get("body_visible", false)), "bind_entity should make BodySprite visible immediately", failures)
	_assert_true(String(snapshot.get("body_texture", "")) != "", "bind_entity should assign a body texture immediately", failures)
	view.free()

func _test_bind_sets_entity_and_shows_view(failures: Array[String]) -> void:
	var view = UnitViewScript.new()
	view.bind_entity(7)
	_assert_eq(view.get_entity_id(), 7, "bind_entity should store the entity id", failures)
	_assert_true(view.visible, "bind_entity should show the view", failures)
	view.free()

func _test_sync_position_updates_global_position(failures: Array[String]) -> void:
	var view = UnitViewScript.new()
	view.bind_entity(3)
	view.sync_from_entity(Vector2(12.5, -8.0), true)
	_assert_eq(view.global_position, Vector2(12.5, -8.0), "sync_from_entity should update global_position", failures)
	_assert_true(view.visible, "sync_from_entity should keep bound live entities visible", failures)
	view.free()

func _test_unbind_hides_view_and_clears_entity(failures: Array[String]) -> void:
	var view = UnitViewScript.new()
	view.bind_entity(9)
	view.unbind_entity()
	_assert_eq(view.get_entity_id(), -1, "unbind_entity should clear the entity id", failures)
	_assert_false(view.visible, "unbind_entity should hide the view", failures)
	view.free()

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)

func _assert_false(value: bool, message: String, failures: Array[String]) -> void:
	if value:
		failures.append(message)

func _assert_eq(actual, expected, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s (expected=%s, actual=%s)" % [message, str(expected), str(actual)])
