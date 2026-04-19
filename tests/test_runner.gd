extends SceneTree

const TEST_SUITES := [
	{"name": "battle/test_entity_store", "path": "res://tests/battle/test_entity_store.gd"},
	{"name": "battle/test_spatial_grid", "path": "res://tests/battle/test_spatial_grid.gd"},
	{"name": "battle/test_object_pool", "path": "res://tests/battle/test_object_pool.gd"},
	{"name": "battle/test_push_resolver", "path": "res://tests/battle/test_push_resolver.gd"},
	{"name": "battle/test_attack_resolver_basic", "path": "res://tests/battle/test_attack_resolver_basic.gd"},
	{"name": "battle/test_battle_simulation_targeting", "path": "res://tests/battle/test_battle_simulation_targeting.gd"},
	{"name": "battle/test_battle_simulation_attacks", "path": "res://tests/battle/test_battle_simulation_attacks.gd"},
	{"name": "battle/test_battle_simulation_combat_report", "path": "res://tests/battle/test_battle_simulation_combat_report.gd"},
	{"name": "battle/test_battle_simulation_v2_duel", "path": "res://tests/battle/test_battle_simulation_v2_duel.gd"},
	{"name": "battle/test_unit_defs_loader", "path": "res://tests/battle/test_unit_defs_loader.gd"},
	{"name": "battle/test_wave_defs_loader", "path": "res://tests/battle/test_wave_defs_loader.gd"},
	{"name": "battle/test_relic_defs_loader", "path": "res://tests/battle/test_relic_defs_loader.gd"},
	{"name": "battle/test_reward_generator", "path": "res://tests/battle/test_reward_generator.gd"},
	{"name": "battle/test_wave_controller", "path": "res://tests/battle/test_wave_controller.gd"},
	{"name": "game/test_game_state_machine", "path": "res://tests/game/test_game_state_machine.gd"},
	{"name": "game/test_game_manager", "path": "res://tests/game/test_game_manager.gd"},
	{"name": "presentation/test_unit_view_binding", "path": "res://tests/presentation/test_unit_view_binding.gd"},
	{"name": "presentation/test_effect_pool", "path": "res://tests/presentation/test_effect_pool.gd"},
	{"name": "presentation/test_unit_view_motion_feedback", "path": "res://tests/presentation/test_unit_view_motion_feedback.gd"},
	{"name": "battle/test_attack_resolver_cleave", "path": "res://tests/battle/test_attack_resolver_cleave.gd"},
	{"name": "battle/test_attack_resolver_support", "path": "res://tests/battle/test_attack_resolver_support.gd"},
	{"name": "battle/test_battle_simulation_performance_hooks", "path": "res://tests/battle/test_battle_simulation_performance_hooks.gd"},
	{"name": "battle/test_corpse_policy", "path": "res://tests/battle/test_corpse_policy.gd"},
	{"name": "battle/test_battle_controller_integration", "path": "res://tests/battle/test_battle_controller_integration.gd"},
	{"name": "battle/test_battle_scene_bootstrap", "path": "res://tests/battle/test_battle_scene_bootstrap.gd"},
	{"name": "scenes/test_main_scene_bootstrap", "path": "res://tests/scenes/test_main_scene_bootstrap.gd"},
	{"name": "battle/test_battle_controller_runtime_setup", "path": "res://tests/battle/test_battle_controller_runtime_setup.gd"},
	{"name": "presentation/test_unit_view_pool_binding", "path": "res://tests/presentation/test_unit_view_pool_binding.gd"},
	{"name": "battle/test_battle_scene_runtime_binding", "path": "res://tests/battle/test_battle_scene_runtime_binding.gd"},
	{"name": "battle/test_battle_scene_visual_bootstrap", "path": "res://tests/battle/test_battle_scene_visual_bootstrap.gd"},
	{"name": "battle/test_battle_scene_effect_feedback", "path": "res://tests/battle/test_battle_scene_effect_feedback.gd"},
	{"name": "battle/test_battle_scene_combat_readability", "path": "res://tests/battle/test_battle_scene_combat_readability.gd"},
	{"name": "battle/test_battle_scene_viewport_visibility", "path": "res://tests/battle/test_battle_scene_viewport_visibility.gd"},
	{"name": "battle/test_battle_scene_formation_readability", "path": "res://tests/battle/test_battle_scene_formation_readability.gd"},
	{"name": "battle/test_battle_scene_side_angle_readability", "path": "res://tests/battle/test_battle_scene_side_angle_readability.gd"},
	{"name": "battle/test_battle_controller_scatter_spawn_layout", "path": "res://tests/battle/test_battle_controller_scatter_spawn_layout.gd"},
	{"name": "battle/test_battle_scene_charge_and_impact_readability", "path": "res://tests/battle/test_battle_scene_charge_and_impact_readability.gd"},
	{"name": "battle/test_battle_scene_skill_fx_feedback", "path": "res://tests/battle/test_battle_scene_skill_fx_feedback.gd"},
	{"name": "battle/test_battle_scene_enemy_swarm_pressure", "path": "res://tests/battle/test_battle_scene_enemy_swarm_pressure.gd"},
	{"name": "battle/test_battle_scene_reference_tempo_acceptance", "path": "res://tests/battle/test_battle_scene_reference_tempo_acceptance.gd"},
	{"name": "battle/test_battle_scene_randomized_spawn_readability", "path": "res://tests/battle/test_battle_scene_randomized_spawn_readability.gd"},
	{"name": "battle/test_battle_scene_death_event_binding", "path": "res://tests/battle/test_battle_scene_death_event_binding.gd"},
	{"name": "battle/test_battle_scene_first_seconds_acceptance", "path": "res://tests/battle/test_battle_scene_first_seconds_acceptance.gd"},
	{"name": "battle/test_battle_controller_view_sync", "path": "res://tests/battle/test_battle_controller_view_sync.gd"},
	{"name": "battle/test_battle_controller_visual_state_sync", "path": "res://tests/battle/test_battle_controller_visual_state_sync.gd"},
	{"name": "battle/test_battle_controller_combat_events", "path": "res://tests/battle/test_battle_controller_combat_events.gd"},
	{"name": "presentation/test_effect_pool_runtime_events", "path": "res://tests/presentation/test_effect_pool_runtime_events.gd"},
	{"name": "presentation/test_effect_pool_visual_events", "path": "res://tests/presentation/test_effect_pool_visual_events.gd"},
	{"name": "presentation/test_effect_pool_active_effects", "path": "res://tests/presentation/test_effect_pool_active_effects.gd"},
	{"name": "presentation/test_unit_view_scale_feedback", "path": "res://tests/presentation/test_unit_view_scale_feedback.gd"},
	{"name": "presentation/test_unit_view_hit_feedback", "path": "res://tests/presentation/test_unit_view_hit_feedback.gd"},
	{"name": "battle/test_battle_controller_tick_loop", "path": "res://tests/battle/test_battle_controller_tick_loop.gd"},
	{"name": "battle/test_battle_scene_hud_states", "path": "res://tests/battle/test_battle_scene_hud_states.gd"},
	{"name": "ui/test_reward_panel_flow", "path": "res://tests/ui/test_reward_panel_flow.gd"},
	{"name": "ui/test_reward_panel_stage_readability", "path": "res://tests/ui/test_reward_panel_stage_readability.gd"},
	{"name": "battle/test_battle_scene_reward_transition", "path": "res://tests/battle/test_battle_scene_reward_transition.gd"},
	{"name": "scenes/test_main_scene_run_loop", "path": "res://tests/scenes/test_main_scene_run_loop.gd"},
	{"name": "scenes/test_main_scene_player_readability", "path": "res://tests/scenes/test_main_scene_player_readability.gd"},
	{"name": "scenes/test_main_scene_acceptance_readability", "path": "res://tests/scenes/test_main_scene_acceptance_readability.gd"},
	{"name": "scenes/test_main_scene_camera_readability", "path": "res://tests/scenes/test_main_scene_camera_readability.gd"},
	{"name": "scenes/test_main_scene_end_to_end_acceptance", "path": "res://tests/scenes/test_main_scene_end_to_end_acceptance.gd"},
	{"name": "scenes/test_main_scene_reward_settle_end_to_end", "path": "res://tests/scenes/test_main_scene_reward_settle_end_to_end.gd"},
	{"name": "scenes/test_main_scene_reward_next_combat_end_to_end", "path": "res://tests/scenes/test_main_scene_reward_next_combat_end_to_end.gd"}
]

var _failure_count := 0
var _test_count := 0

func _initialize() -> void:
	print("[TEST] Starting test run...")
	for suite_def in TEST_SUITES:
		_run_suite(str(suite_def.name), str(suite_def.path))

	if _failure_count == 0:
		print("[TEST] All %d test suite(s) passed." % _test_count)
		quit(0)
		return

	printerr("[TEST] %d failure(s) across %d test suite(s)." % [_failure_count, _test_count])
	quit(1)

func _run_suite(suite_name: String, suite_path: String) -> void:
	_test_count += 1
	var suite_script: Variant = load(suite_path)
	if suite_script == null:
		_failure_count += 1
		printerr("[FAIL] %s: script failed to load (%s)" % [suite_name, suite_path])
		return
	if not (suite_script is GDScript):
		_failure_count += 1
		printerr("[FAIL] %s: loaded resource is not a GDScript (%s)" % [suite_name, suite_path])
		return

	var suite: Variant = suite_script.new()
	if suite == null:
		_failure_count += 1
		printerr("[FAIL] %s: script failed to instantiate" % suite_name)
		return

	if not suite.has_method("run"):
		_failure_count += 1
		printerr("[FAIL] %s: missing run() method" % suite_name)
		return

	var result: Variant = suite.run()
	if result is Array and result.is_empty():
		await process_frame
		print("[PASS] %s" % suite_name)
		return

	if result is Array:
		await process_frame
		for failure in result:
			_failure_count += 1
			printerr("[FAIL] %s: %s" % [suite_name, str(failure)])
		return

	_failure_count += 1
	printerr("[FAIL] %s: run() must return Array[String]" % suite_name)
