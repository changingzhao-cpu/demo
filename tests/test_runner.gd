extends SceneTree

const TEST_SUITES := [
	{"name": "battle/test_entity_store", "path": "res://tests/battle/test_entity_store.gd"},
	{"name": "battle/test_spatial_grid", "path": "res://tests/battle/test_spatial_grid.gd"},
	{"name": "battle/test_object_pool", "path": "res://tests/battle/test_object_pool.gd"},
	{"name": "battle/test_push_resolver", "path": "res://tests/battle/test_push_resolver.gd"},
	{"name": "battle/test_attack_resolver_basic", "path": "res://tests/battle/test_attack_resolver_basic.gd"},
	{"name": "battle/test_battle_simulation_targeting", "path": "res://tests/battle/test_battle_simulation_targeting.gd"},
	{"name": "battle/test_unit_defs_loader", "path": "res://tests/battle/test_unit_defs_loader.gd"},
	{"name": "battle/test_wave_defs_loader", "path": "res://tests/battle/test_wave_defs_loader.gd"},
	{"name": "battle/test_relic_defs_loader", "path": "res://tests/battle/test_relic_defs_loader.gd"},
	{"name": "battle/test_reward_generator", "path": "res://tests/battle/test_reward_generator.gd"},
	{"name": "battle/test_wave_controller", "path": "res://tests/battle/test_wave_controller.gd"},
	{"name": "game/test_game_state_machine", "path": "res://tests/game/test_game_state_machine.gd"},
	{"name": "game/test_game_manager", "path": "res://tests/game/test_game_manager.gd"},
	{"name": "presentation/test_unit_view_binding", "path": "res://tests/presentation/test_unit_view_binding.gd"},
	{"name": "presentation/test_effect_pool", "path": "res://tests/presentation/test_effect_pool.gd"},
	{"name": "battle/test_attack_resolver_cleave", "path": "res://tests/battle/test_attack_resolver_cleave.gd"},
	{"name": "battle/test_attack_resolver_support", "path": "res://tests/battle/test_attack_resolver_support.gd"},
	{"name": "battle/test_battle_simulation_performance_hooks", "path": "res://tests/battle/test_battle_simulation_performance_hooks.gd"},
	{"name": "battle/test_corpse_policy", "path": "res://tests/battle/test_corpse_policy.gd"},
	{"name": "battle/test_battle_controller_integration", "path": "res://tests/battle/test_battle_controller_integration.gd"},
	{"name": "battle/test_battle_scene_bootstrap", "path": "res://tests/battle/test_battle_scene_bootstrap.gd"}
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
		print("[PASS] %s" % suite_name)
		return

	if result is Array:
		for failure in result:
			_failure_count += 1
			printerr("[FAIL] %s: %s" % [suite_name, str(failure)])
		return

	_failure_count += 1
	printerr("[FAIL] %s: run() must return Array[String]" % suite_name)
