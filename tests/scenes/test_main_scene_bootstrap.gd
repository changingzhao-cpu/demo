extends RefCounted

const TestCleanup = preload("res://tests/test_cleanup.gd")
const MAIN_SCENE_PATH := "res://scenes/main/main_scene.tscn"

func _load_main_scene() -> PackedScene:
	return load(MAIN_SCENE_PATH)

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_main_scene_instantiates(failures)
	_test_main_scene_contains_battle_scene(failures)
	_test_main_scene_boots_battle_demo_on_ready(failures)
	return failures

func _test_main_scene_instantiates(failures: Array[String]) -> void:
	var main_scene = _load_main_scene()
	_assert_true(main_scene != null, "main scene should load", failures)
	if main_scene == null:
		return
	var instance = main_scene.instantiate()
	_assert_true(instance != null, "main scene should instantiate", failures)
	if instance != null:
		instance.queue_free()

func _test_main_scene_contains_battle_scene(failures: Array[String]) -> void:
	var main_scene = _load_main_scene()
	if main_scene == null:
		failures.append("main scene should load before checking battle scene structure")
		return
	var instance = main_scene.instantiate()
	var battle_scene = instance.get_node_or_null("BattleScene")
	_assert_true(battle_scene != null, "main scene should contain a BattleScene child", failures)
	instance.free()

func _test_main_scene_boots_battle_demo_on_ready(failures: Array[String]) -> void:
	var main_scene = _load_main_scene()
	if main_scene == null:
		failures.append("main scene should load before runtime bootstrap checks")
		return
	var main_loop: SceneTree = Engine.get_main_loop()
	var instance = main_scene.instantiate()
	main_loop.root.add_child(instance)
	await main_loop.process_frame
	var battle_scene = instance.get_node_or_null("BattleScene")
	_assert_true(battle_scene != null, "main scene should expose BattleScene after entering tree", failures)
	if battle_scene != null:
		var controller = battle_scene.get_node_or_null("BattleController")
		_assert_true(controller != null, "BattleScene should contain BattleController after bootstrap", failures)
		if controller != null:
			var current_wave = controller.call("get_current_wave")
			_assert_eq(int(current_wave.get("wave", -1)), 1, "main scene should boot battle demo into wave 1", failures)
			_assert_eq(str(controller.call("get_state")), "combat", "main scene should boot battle demo into combat state", failures)
	await TestCleanup.release_tree_instance(main_loop, instance)

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)

func _assert_eq(actual, expected, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s (expected=%s, actual=%s)" % [message, str(expected), str(actual)])
