extends RefCounted

const UnitViewScript = preload("res://scripts/presentation/unit_view.gd")

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_visual_radius_stays_compact_for_dense_battles(failures)
	_test_attack_pulse_temporarily_boosts_motion_feedback(failures)
	return failures

func _test_visual_radius_stays_compact_for_dense_battles(failures: Array[String]) -> void:
	var view = UnitViewScript.new()
	_assert_true(view.call("get_visual_radius") <= 8.0, "unit view radius should stay compact to reduce overlap in dense battles", failures)

func _test_attack_pulse_temporarily_boosts_motion_feedback(failures: Array[String]) -> void:
	var view = UnitViewScript.new()
	view.call("bind_entity", 1)
	view.call("set_visual_motion", 1.0, 1.0)
	var baseline := float(view.call("get_visual_motion_strength"))
	if view.has_method("trigger_attack_pulse"):
		view.call("trigger_attack_pulse")
	_assert_true(view.has_method("trigger_attack_pulse"), "unit view should expose an attack pulse hook for combat readability", failures)
	_assert_true(float(view.call("get_visual_motion_strength")) >= baseline, "attack pulse should not reduce readable motion strength", failures)

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
