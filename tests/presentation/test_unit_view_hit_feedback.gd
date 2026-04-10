extends RefCounted

const UnitViewScript = preload("res://scripts/presentation/unit_view.gd")

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_hit_pulse_temporarily_boosts_motion_feedback(failures)
	return failures

func _test_hit_pulse_temporarily_boosts_motion_feedback(failures: Array[String]) -> void:
	var view = UnitViewScript.new()
	view.call("bind_entity", 3)
	view.call("set_visual_motion", 1.0, 0.5)
	var baseline := float(view.call("get_visual_motion_strength"))
	_assert_true(view.has_method("trigger_hit_pulse"), "unit view should expose a hit pulse hook for target feedback", failures)
	if view.has_method("trigger_hit_pulse"):
		view.call("trigger_hit_pulse")
		_assert_true(float(view.call("get_visual_motion_strength")) > baseline, "hit pulse should temporarily increase readable motion strength", failures)

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
