extends RefCounted

const BattleScene = preload("res://scenes/battle/battle_scene.tscn")

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_scene_conveys_side_angle_arena_readability(failures)
	return failures

func _test_scene_conveys_side_angle_arena_readability(failures: Array[String]) -> void:
	var instance = BattleScene.instantiate()
	_assert_true(instance.get_node_or_null("BattlefieldBackdrop") != null, "battle scene should keep a dedicated battlefield backdrop", failures)
	_assert_true(instance.get_node_or_null("BattlefieldFrame") != null, "battle scene should keep a dedicated battlefield frame", failures)
	_assert_true(instance.get_node_or_null("FrontlineMarker") != null, "battle scene should still expose a frontline reference node", failures)
	_assert_true(instance.get_node_or_null("SpawnBandLeft") != null, "battle scene should still expose an ally-side staging reference node", failures)
	_assert_true(instance.get_node_or_null("SpawnBandRight") != null, "battle scene should still expose an enemy-side staging reference node", failures)
	var arena_shadow = instance.get_node_or_null("ArenaShadow")
	var arena_floor = instance.get_node_or_null("ArenaFloor")
	var arena_rim = instance.get_node_or_null("ArenaRim")
	_assert_true(arena_shadow == null or (arena_shadow is CanvasItem and not arena_shadow.visible), "battle scene should keep ArenaShadow hidden when only ArenaFloor is used", failures)
	_assert_true(arena_floor is CanvasItem and arena_floor.visible, "battle scene should expose a visible ArenaFloor node for arena readability", failures)
	_assert_true(arena_rim is CanvasItem and arena_rim.visible, "battle scene should expose a visible ArenaRim node for arena boundary readability", failures)
	if arena_floor is Polygon2D:
		_assert_true(arena_floor.texture != null, "ArenaFloor should render with the arena floor texture", failures)
		_assert_true(is_equal_approx(arena_floor.color.a, 1.0), "ArenaFloor should render at full opacity", failures)
	var unit_layer = instance.get_node_or_null("UnitLayer")
	var camera = instance.get_node_or_null("Camera2D")
	_assert_true(unit_layer is Node2D, "battle scene should expose UnitLayer", failures)
	_assert_true(camera is Camera2D, "battle scene should expose Camera2D", failures)
	if unit_layer is Node2D:
		_assert_true(unit_layer.position == Vector2.ZERO, "unit layer should stay neutral while scene runtime maps world positions into screen space", failures)
		_assert_true(is_equal_approx(unit_layer.scale.x, 1.0) and is_equal_approx(unit_layer.scale.y, 1.0), "unit layer should keep neutral scale while scene runtime applies screen mapping", failures)
	if camera is Camera2D:
		_assert_true(is_equal_approx(camera.zoom.x, 1.0) and is_equal_approx(camera.zoom.y, 1.0), "camera should stay neutral while unit/effect layers provide the presentation scale", failures)
	instance.free()

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
