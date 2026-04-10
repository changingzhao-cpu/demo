extends RefCounted

const UnitViewScript = preload("res://scripts/presentation/unit_view.gd")

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_visual_sync_exposes_facing_and_motion(failures)
	_test_dead_visual_sync_keeps_motion_feedback_observable(failures)
	return failures

func _test_visual_sync_exposes_facing_and_motion(failures: Array[String]) -> void:
	var view = UnitViewScript.new()
	view.bind_entity(5)
	_assert_true(view.has_method("sync_from_entity_visual"), "unit view should expose sync_from_entity_visual for richer runtime feedback", failures)
	_assert_true(view.has_method("get_visual_facing_sign"), "unit view should expose visual facing sign", failures)
	_assert_true(view.has_method("get_visual_motion_strength"), "unit view should expose visual motion strength", failures)
	if view.has_method("sync_from_entity_visual"):
		view.call("sync_from_entity_visual", Vector2(4.0, 1.5), true, 0, 2.0, 1.0)
		_assert_eq(view.global_position, Vector2(4.0, 1.5), "visual sync should still move the view", failures)
		_assert_eq(float(view.call("get_visual_facing_sign")), 1.0, "ally visual sync should preserve positive facing", failures)
		_assert_true(float(view.call("get_visual_motion_strength")) > 0.0, "moving unit should expose positive motion strength", failures)
	view.free()

func _test_dead_visual_sync_keeps_motion_feedback_observable(failures: Array[String]) -> void:
	var view = UnitViewScript.new()
	view.bind_entity(11)
	view.call("enable_death_feedback", true)
	if view.has_method("sync_from_entity_visual"):
		view.call("sync_from_entity_visual", Vector2(-3.0, 6.0), false, 1, 1.25, -1.0)
		_assert_true(view.visible, "dead visual sync should remain visible when death feedback is enabled", failures)
		_assert_true(bool(view.call("is_showing_death_state")), "dead visual sync should still report death state", failures)
		_assert_eq(float(view.call("get_visual_facing_sign")), -1.0, "enemy visual sync should preserve negative facing", failures)
		_assert_true(float(view.call("get_visual_motion_strength")) > 0.0, "dead visual sync should keep the last motion intensity observable", failures)
	view.free()

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)

func _assert_eq(actual, expected, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s (expected=%s, actual=%s)" % [message, str(expected), str(actual)])
