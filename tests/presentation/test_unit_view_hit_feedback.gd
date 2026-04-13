extends RefCounted

const UnitViewScript = preload("res://scripts/presentation/unit_view.gd")

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_hit_pulse_temporarily_boosts_motion_feedback(failures)
	_test_attack_pulse_holds_attack_pose_long_enough_to_read(failures)
	_test_goose_attack_pose_is_visibly_distinct_from_idle(failures)
	_test_depth_anchor_sorting_uses_foot_points(failures)
	return failures

func _test_depth_anchor_sorting_uses_foot_points(failures: Array[String]) -> void:
	var front_goose = UnitViewScript.new()
	front_goose.call("bind_entity", 21)
	front_goose.call("sync_from_entity_visual", Vector2(100.0, 140.0), true, 1, 0.0, -1.0)
	var back_goose = UnitViewScript.new()
	back_goose.call("bind_entity", 22)
	back_goose.call("sync_from_entity_visual", Vector2(100.0, 100.0), true, 1, 0.0, -1.0)
	front_goose.call("refresh_depth_sort")
	back_goose.call("refresh_depth_sort")
	_assert_true(int(front_goose.z_index) > int(back_goose.z_index), "the lower goose should sort in front based on its foot anchor", failures)
	var soldier = UnitViewScript.new()
	soldier.call("bind_entity", 23)
	soldier.call("sync_from_entity_visual", Vector2(100.0, 120.0), true, 0, 0.0, 1.0)
	soldier.call("refresh_depth_sort")
	_assert_true(float(soldier.call("get_depth_anchor_global_y")) != float(front_goose.call("get_depth_anchor_global_y")) or int(soldier.z_index) != int(front_goose.z_index), "different unit types should still derive depth from their own foot anchors", failures)

func _test_hit_pulse_temporarily_boosts_motion_feedback(failures: Array[String]) -> void:
	var view = UnitViewScript.new()
	view.call("bind_entity", 3)
	view.call("set_visual_motion", 1.0, 0.5)
	var baseline := float(view.call("get_visual_motion_strength"))
	_assert_true(view.has_method("trigger_hit_pulse"), "unit view should expose a hit pulse hook for target feedback", failures)
	if view.has_method("trigger_hit_pulse"):
		view.call("trigger_hit_pulse")
		_assert_true(float(view.call("get_visual_motion_strength")) > baseline, "hit pulse should temporarily increase readable motion strength", failures)

func _test_attack_pulse_holds_attack_pose_long_enough_to_read(failures: Array[String]) -> void:
	var view = UnitViewScript.new()
	view.call("bind_entity", 7)
	view.call("sync_from_entity_visual", Vector2.ZERO, true, 0, 6.0, -1.0)
	view.call("_ensure_sprite_nodes")
	_assert_true(view.get_node_or_null("BodySprite") != null, "unit view should expose a body sprite node for readable attack art", failures)
	if view.get_node_or_null("BodySprite") != null and view.has_method("trigger_attack_pulse"):
		view.call("trigger_attack_pulse")
		var attack_texture = view.get_node("BodySprite").texture
		view.call("set_visual_motion", -1.0, 0.0)
		_assert_true(view.get_node("BodySprite").texture == attack_texture, "attack pose should stay visible long enough to read instead of flashing away immediately", failures)
		_assert_true(view.get_node("BodySprite").scale.x < 0.0, "soldier sprite should flip with facing so attack direction is readable", failures)

func _test_goose_attack_pose_is_visibly_distinct_from_idle(failures: Array[String]) -> void:
	var view = UnitViewScript.new()
	view.call("bind_entity", 11)
	view.call("sync_from_entity_visual", Vector2.ZERO, true, 1, 0.0, -1.0)
	view.call("_ensure_sprite_nodes")
	var body = view.get_node_or_null("BodySprite")
	_assert_true(body != null, "unit view should expose a goose body sprite before attack readability checks", failures)
	if body != null and view.has_method("trigger_attack_pulse"):
		var idle_rotation := float(body.rotation)
		var idle_position := Vector2(body.position)
		view.call("trigger_attack_pulse")
		_assert_true(absf(float(body.rotation) - idle_rotation) > 0.05 or body.position.distance_to(idle_position) > 0.05, "goose attack should visibly change pose instead of looking identical to idle", failures)

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
