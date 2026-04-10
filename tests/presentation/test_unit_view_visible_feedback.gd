extends RefCounted

const UnitViewScript = preload("res://scripts/presentation/unit_view.gd")

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_bound_view_exposes_visible_placeholder_state(failures)
	_test_enemy_style_changes_visual_state(failures)
	_test_dead_entity_sync_marks_view_as_faded(failures)
	return failures

func _test_bound_view_exposes_visible_placeholder_state(failures: Array[String]) -> void:
	var view = UnitViewScript.new()
	view.bind_entity(12)
	_assert_true(view.has_method("get_visual_radius"), "unit view should expose placeholder radius for visible rendering", failures)
	_assert_true(view.has_method("get_visual_tint"), "unit view should expose placeholder tint for visible rendering", failures)
	_assert_true(view.has_method("is_showing_death_state"), "unit view should expose whether it is showing a death state", failures)
	_assert_true(float(view.call("get_visual_radius")) > 0.0, "bound unit view should report a positive visual radius", failures)
	_assert_eq(view.call("get_visual_tint"), Color(0.45, 0.85, 1.0, 1.0), "ally unit view should default to ally tint", failures)
	_assert_false(bool(view.call("is_showing_death_state")), "freshly bound unit view should not start in death state", failures)
	view.free()

func _test_enemy_style_changes_visual_state(failures: Array[String]) -> void:
	var view = UnitViewScript.new()
	view.bind_entity(4)
	view.apply_placeholder_style(true)
	_assert_eq(view.call("get_visual_tint"), Color(0.95, 0.4, 0.4, 1.0), "enemy placeholder style should switch to enemy tint", failures)
	_assert_true(view.visible, "enemy placeholder style should keep the bound view visible", failures)
	view.free()

func _test_dead_entity_sync_marks_view_as_faded(failures: Array[String]) -> void:
	var view = UnitViewScript.new()
	view.bind_entity(8)
	view.call("enable_death_feedback", true)
	view.sync_from_entity(Vector2(2.0, -5.0), false)
	_assert_eq(view.global_position, Vector2(2.0, -5.0), "dead entity sync should still move the view to the latest position", failures)
	_assert_true(view.visible, "dead entity sync should keep the placeholder visible for death feedback", failures)
	_assert_true(bool(view.call("is_showing_death_state")), "dead entity sync should mark the placeholder as dead", failures)
	_assert_eq(view.call("get_visual_tint"), Color(0.45, 0.85, 1.0, 0.35), "dead ally placeholder should fade instead of disappearing instantly", failures)
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
