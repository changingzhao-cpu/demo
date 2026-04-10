extends RefCounted

const MainScene = preload("res://scenes/main/main_scene.tscn")

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_battle_scene_remains_inside_main_frame_after_scale_adjustments(failures)
	return failures

func _test_battle_scene_remains_inside_main_frame_after_scale_adjustments(failures: Array[String]) -> void:
	var instance = MainScene.instantiate()
	var frame = instance.get_node_or_null("BattleSceneFrame")
	var battle_scene = instance.get_node_or_null("BattleScene")
	_assert_true(frame != null, "main scene should expose BattleSceneFrame for readability checks", failures)
	_assert_true(battle_scene != null, "main scene should expose BattleScene instance for readability checks", failures)
	if frame != null and battle_scene != null:
		_assert_true(frame.size.x >= 1200.0, "main scene frame should remain wide enough after camera adjustments", failures)
		_assert_true(battle_scene.position.y >= 90.0, "battle scene should remain visually centered inside the frame after scale changes", failures)
	instance.free()

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
