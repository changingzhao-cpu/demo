extends RefCounted

const MAIN_SCENE_PATH := "res://scenes/main/main_scene.tscn"

func _load_main_scene() -> PackedScene:
	return load(MAIN_SCENE_PATH)

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_main_scene_contains_player_readable_shell_nodes(failures)
	_test_main_scene_boot_shows_playable_context_without_debug_tools(failures)
	return failures

func _test_main_scene_contains_player_readable_shell_nodes(failures: Array[String]) -> void:
	var main_scene = _load_main_scene()
	_assert_true(main_scene != null, "main scene should load", failures)
	if main_scene == null:
		return
	var instance = main_scene.instantiate()
	_assert_true(instance.get_node_or_null("TitleLabel") != null, "main scene should contain a TitleLabel", failures)
	_assert_true(instance.get_node_or_null("SubtitleLabel") != null, "main scene should contain a SubtitleLabel", failures)
	_assert_true(instance.get_node_or_null("RunHintLabel") != null, "main scene should contain a RunHintLabel", failures)
	_assert_true(instance.get_node_or_null("BattleSceneFrame") != null, "main scene should contain a BattleSceneFrame", failures)
	_assert_true(instance.get_node_or_null("SettleAnchor") != null, "main scene should keep a SettleAnchor node", failures)
	instance.free()

func _test_main_scene_boot_shows_playable_context_without_debug_tools(failures: Array[String]) -> void:
	var main_scene = _load_main_scene()
	_assert_true(main_scene != null, "main scene should load before readability runtime checks", failures)
	if main_scene == null:
		return
	var main_loop: SceneTree = Engine.get_main_loop()
	var instance = main_scene.instantiate()
	main_loop.root.add_child(instance)
	await main_loop.process_frame
	var battle_scene = instance.get_node_or_null("BattleScene")
	var title_label = instance.get_node_or_null("TitleLabel")
	var run_hint_label = instance.get_node_or_null("RunHintLabel")
	_assert_true(battle_scene != null, "main scene should expose BattleScene after entering tree", failures)
	_assert_true(title_label != null, "main scene should expose TitleLabel after entering tree", failures)
	_assert_true(run_hint_label != null, "main scene should expose RunHintLabel after entering tree", failures)
	if battle_scene != null:
		var hud_state = battle_scene.get_node_or_null("UiLayer/StateLabel")
		var hud_wave = battle_scene.get_node_or_null("UiLayer/WaveLabel")
		_assert_true(hud_state != null, "main scene should expose battle HUD state label", failures)
		_assert_true(hud_wave != null, "main scene should expose battle HUD wave label", failures)
	if title_label != null:
		_assert_true(String(title_label.text).contains("Battle Demo"), "main scene title should identify the battle demo", failures)
	if run_hint_label != null:
		_assert_true(String(run_hint_label.text).contains("Reward"), "main scene hint should mention reward flow", failures)
	main_loop.root.remove_child(instance)
	instance.free()

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
