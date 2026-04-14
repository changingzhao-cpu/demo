extends RefCounted

const UnitViewScript = preload("res://scripts/presentation/unit_view.gd")

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_visual_sync_exposes_facing_and_motion(failures)
	_test_dead_visual_sync_keeps_motion_feedback_observable(failures)
	_test_death_sync_overrides_attack_position_lock(failures)
	_test_motion_feedback_stays_bounded_and_keeps_unit_readable(failures)
	_test_attack_hold_locks_position_updates(failures)
	_test_alive_label_reflects_bound_and_death_state(failures)
	_test_dead_runtime_sync_hides_view_and_marks_label_dead(failures)
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

func _test_death_sync_overrides_attack_position_lock(failures: Array[String]) -> void:
	var view = UnitViewScript.new()
	view.bind_entity(31)
	view.call("sync_from_entity_visual", Vector2(10.0, 10.0), true, 0, 0.0, 1.0, 0)
	view.call("trigger_attack_pulse")
	view.call("sync_from_entity_visual", Vector2(40.0, 10.0), false, 0, 0.0, 1.0, 0)
	_assert_true(not view.visible, "death sync should hide a unit even if an attack position lock is active", failures)
	_assert_eq(view.global_position, Vector2(40.0, 10.0), "death sync should still update to the final death position instead of freezing at the pre-attack lock position", failures)
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

func _test_alive_label_reflects_bound_and_death_state(failures: Array[String]) -> void:
	var view = UnitViewScript.new()
	view.bind_entity(42)
	await_if_needed(view)
	var label = view.get_node_or_null("AliveLabel")
	_assert_true(label is Label, "unit view should create an AliveLabel for head-top status debugging", failures)
	if label is Label:
		_assert_eq(label.text, "42:1", "bound living unit should show entity id and alive state above its head", failures)
	view.call("sync_from_entity_visual", Vector2(5.0, 5.0), false, 0, 0.0, 1.0, 0)
	if label is Label:
		_assert_eq(label.text, "42:0", "dead unit should show entity id and dead state above its head", failures)
		_assert_true(label.visible, "alive label should remain visible after death so the debug marker can be inspected", failures)
	view.free()

func _test_dead_runtime_sync_hides_view_and_marks_label_dead(failures: Array[String]) -> void:
	var view = UnitViewScript.new()
	view.bind_entity(17)
	await_if_needed(view)
	view.call("set_visual_alive_state", false)
	var label = view.get_node_or_null("AliveLabel")
	_assert_true(not view.visible, "dead runtime sync should hide the unit view instead of leaving a visible corpse placeholder", failures)
	if label is Label:
		_assert_eq(label.text, "17:0", "dead runtime sync should flip the debug label to entity_id:0", failures)
		_assert_true(label.visible, "dead runtime sync should keep the debug label visible for inspection", failures)
	view.free()

func await_if_needed(_view) -> void:
	pass

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)

func _assert_eq(actual, expected, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s (expected=%s, actual=%s)" % [message, str(expected), str(actual)])
