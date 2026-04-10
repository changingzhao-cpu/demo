extends RefCounted

const UnitViewScript = preload("res://scripts/presentation/unit_view.gd")

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_rebind_replaces_previous_entity_binding(failures)
	_test_unbind_clears_binding_for_reuse(failures)
	_test_sync_keeps_rebound_view_visible(failures)
	return failures

func _test_rebind_replaces_previous_entity_binding(failures: Array[String]) -> void:
	var view = UnitViewScript.new()
	view.bind_entity(2)
	view.bind_entity(5)
	_assert_eq(view.get_entity_id(), 5, "bind_entity should replace the previous entity binding", failures)
	_assert_true(view.visible, "rebound view should remain visible", failures)
	view.free()

func _test_unbind_clears_binding_for_reuse(failures: Array[String]) -> void:
	var view = UnitViewScript.new()
	view.bind_entity(9)
	view.unbind_entity()
	view.bind_entity(11)
	_assert_eq(view.get_entity_id(), 11, "view should be reusable after unbind_entity", failures)
	_assert_true(view.visible, "reused view should become visible after bind_entity", failures)
	view.free()

func _test_sync_keeps_rebound_view_visible(failures: Array[String]) -> void:
	var view = UnitViewScript.new()
	view.bind_entity(4)
	view.unbind_entity()
	view.bind_entity(8)
	view.sync_from_entity(Vector2(-3.0, 6.5), true)
	_assert_eq(view.global_position, Vector2(-3.0, 6.5), "sync_from_entity should update reused views", failures)
	_assert_true(view.visible, "sync_from_entity should keep rebound live views visible", failures)
	view.free()

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)

func _assert_eq(actual, expected, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s (expected=%s, actual=%s)" % [message, str(expected), str(actual)])
