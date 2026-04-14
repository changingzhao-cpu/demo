extends RefCounted

const UnitViewScript = preload("res://scripts/presentation/unit_view.gd")

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_visual_sync_exposes_facing_and_motion(failures)
	_test_dead_visual_sync_keeps_motion_feedback_observable(failures)
	_test_motion_feedback_stays_bounded_and_keeps_unit_readable(failures)
	_test_attack_hold_locks_position_updates(failures)
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
		_assert_true(not view.visible, "dead visual sync should stop rendering the unit once it has died", failures)
		_assert_true(not bool(view.call("is_showing_death_state")), "dead visual sync should not keep reporting an active visible death state", failures)
		_assert_eq(float(view.call("get_visual_facing_sign")), -1.0, "enemy visual sync should preserve negative facing", failures)
		_assert_eq(float(view.call("get_visual_motion_strength")), 0.0, "dead visual sync should clear motion intensity once the unit is gone", failures)
	view.free()

func _test_motion_feedback_stays_bounded_and_keeps_unit_readable(failures: Array[String]) -> void:
	var ally_view = UnitViewScript.new()
	ally_view.bind_entity(1)
	ally_view.call("sync_from_entity_visual", Vector2.ZERO, true, 0, 2.0, 1.0)
	ally_view.call("trigger_attack_pulse")
	_assert_true(float(ally_view.call("get_visual_motion_strength")) <= 1.35, "ally motion feedback should stay bounded instead of ballooning into a blob", failures)
	_assert_true(float(ally_view.call("get_visual_radius")) <= 3.2, "ally moving unit should keep a compact readable radius", failures)
	_assert_eq(float(ally_view.call("get_visual_facing_sign")), 1.0, "ally motion feedback should preserve readable forward facing", failures)
	ally_view.free()
	var enemy_view = UnitViewScript.new()
	enemy_view.bind_entity(2)
	enemy_view.call("sync_from_entity_visual", Vector2.ZERO, true, 1, 2.0, -1.0)
	enemy_view.call("trigger_hit_pulse")
	_assert_true(float(enemy_view.call("get_visual_motion_strength")) <= 1.4, "enemy motion feedback should stay bounded instead of ballooning into a blob", failures)
	_assert_true(float(enemy_view.call("get_visual_radius")) <= 3.2, "enemy moving unit should keep a compact readable radius", failures)
	_assert_eq(float(enemy_view.call("get_visual_facing_sign")), -1.0, "enemy motion feedback should preserve readable reverse facing", failures)
	enemy_view.free()

func _test_attack_hold_locks_position_updates(failures: Array[String]) -> void:
	var view = UnitViewScript.new()
	view.bind_entity(21)
	view.call("sync_from_entity_visual", Vector2(10.0, 10.0), true, 0, 0.0, 1.0, 0)
	view.call("trigger_attack_pulse")
	view.call("sync_from_entity_visual", Vector2(40.0, 10.0), true, 0, 6.0, 1.0, 3)
	_assert_eq(view.global_position, Vector2(10.0, 10.0), "unit should hold its current screen position while the attack pose is still active", failures)
	view.free()

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)

func _assert_eq(actual, expected, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s (expected=%s, actual=%s)" % [message, str(expected), str(actual)])
