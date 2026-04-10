extends RefCounted

const BattleScene = preload("res://scenes/battle/battle_scene.tscn")

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_combat_hud_shows_wave_and_state(failures)
	_test_reward_hud_switches_when_wave_clears(failures)
	_test_settle_hud_switches_when_run_fails(failures)
	_test_combat_hud_stays_compact_and_avoids_extra_overlay_labels(failures)
	return failures

func _test_combat_hud_shows_wave_and_state(failures: Array[String]) -> void:
	var main_loop: SceneTree = Engine.get_main_loop()
	var instance = BattleScene.instantiate()
	main_loop.root.add_child(instance)
	await main_loop.process_frame
	var state_label = instance.get_node_or_null("UiLayer/StateLabel")
	var wave_label = instance.get_node_or_null("UiLayer/WaveLabel")
	var phase_hint = instance.get_node_or_null("UiLayer/PhaseHint")
	_assert_true(state_label != null, "battle scene should expose a StateLabel in the HUD", failures)
	_assert_true(wave_label != null, "battle scene should expose a WaveLabel in the HUD", failures)
	_assert_true(phase_hint != null, "battle scene should expose a PhaseHint in the HUD", failures)
	if state_label != null:
		_assert_true(String(state_label.text).contains("combat"), "combat HUD should show the combat state", failures)
	if wave_label != null:
		_assert_true(String(wave_label.text).contains("Wave 1"), "combat HUD should show wave 1 on boot", failures)
	if phase_hint != null:
		_assert_true(String(phase_hint.text).contains("Auto battle"), "combat HUD should explain that battle is running automatically", failures)
	main_loop.root.remove_child(instance)
	instance.free()

func _test_reward_hud_switches_when_wave_clears(failures: Array[String]) -> void:
	var main_loop: SceneTree = Engine.get_main_loop()
	var instance = BattleScene.instantiate()
	main_loop.root.add_child(instance)
	await main_loop.process_frame
	var controller = instance.get_node_or_null("BattleController")
	var state_label = instance.get_node_or_null("UiLayer/StateLabel")
	var phase_hint = instance.get_node_or_null("UiLayer/PhaseHint")
	if controller == null or state_label == null or phase_hint == null:
		failures.append("battle scene should expose controller and HUD labels before reward HUD checks")
		if instance.get_parent() != null:
			main_loop.root.remove_child(instance)
		instance.free()
		return
	controller.call("handle_wave_clear")
	await main_loop.process_frame
	_assert_true(String(state_label.text).contains("reward"), "reward HUD should show the reward state", failures)
	_assert_true(String(phase_hint.text).contains("Choose a reward"), "reward HUD should ask the player to choose a reward", failures)
	main_loop.root.remove_child(instance)
	instance.free()

func _test_settle_hud_switches_when_run_fails(failures: Array[String]) -> void:
	var main_loop: SceneTree = Engine.get_main_loop()
	var instance = BattleScene.instantiate()
	main_loop.root.add_child(instance)
	await main_loop.process_frame
	var controller = instance.get_node_or_null("BattleController")
	var state_label = instance.get_node_or_null("UiLayer/StateLabel")
	var phase_hint = instance.get_node_or_null("UiLayer/PhaseHint")
	if controller == null or state_label == null or phase_hint == null:
		failures.append("battle scene should expose controller and HUD labels before settle HUD checks")
		if instance.get_parent() != null:
			main_loop.root.remove_child(instance)
		instance.free()
		return
	controller.call("handle_run_failed")
	await main_loop.process_frame
	_assert_true(String(state_label.text).contains("settle"), "settle HUD should show the settle state", failures)
	_assert_true(String(phase_hint.text).contains("Run ended"), "settle HUD should explain that the run has ended", failures)
	main_loop.root.remove_child(instance)
	instance.free()

func _test_combat_hud_stays_compact_and_avoids_extra_overlay_labels(failures: Array[String]) -> void:
	var main_loop: SceneTree = Engine.get_main_loop()
	var instance = BattleScene.instantiate()
	main_loop.root.add_child(instance)
	await main_loop.process_frame
	var phase_hint = instance.get_node_or_null("UiLayer/PhaseHint")
	var frontline_label = instance.get_node_or_null("UiLayer/FrontlineLabel")
	var legend_allies = instance.get_node_or_null("UiLayer/LegendAllies")
	var legend_enemies = instance.get_node_or_null("UiLayer/LegendEnemies")
	var tempo_banner = instance.get_node_or_null("UiLayer/TempoBanner")
	var arena_flavor = instance.get_node_or_null("UiLayer/ArenaFlavor")
	if phase_hint == null:
		failures.append("battle scene should expose PhaseHint before HUD compactness checks")
		if instance.get_parent() != null:
			main_loop.root.remove_child(instance)
		instance.free()
		return
	var phase_text := String(phase_hint.text)
	_assert_true(phase_text.length() <= 36, "PhaseHint should stay compact instead of using long stitched guidance text", failures)
	_assert_false(phase_text.contains("Arena:"), "PhaseHint should not append arena flavor copy into the core HUD hint", failures)
	_assert_hidden_or_missing(frontline_label, "FrontlineLabel should not remain as a prominent overlay label", failures)
	_assert_hidden_or_missing(legend_allies, "LegendAllies should not remain as a prominent overlay label", failures)
	_assert_hidden_or_missing(legend_enemies, "LegendEnemies should not remain as a prominent overlay label", failures)
	_assert_hidden_or_missing(tempo_banner, "TempoBanner should not remain as a prominent overlay label", failures)
	_assert_hidden_or_missing(arena_flavor, "ArenaFlavor should not remain as a prominent overlay label", failures)
	main_loop.root.remove_child(instance)
	instance.free()

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)

func _assert_false(value: bool, message: String, failures: Array[String]) -> void:
	if value:
		failures.append(message)

func _assert_hidden_or_missing(node: Node, message: String, failures: Array[String]) -> void:
	if node == null:
		return
	if node is CanvasItem and node.visible:
		failures.append(message)
