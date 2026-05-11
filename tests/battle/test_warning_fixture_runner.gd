# [SKIP_IN_CI] Manual debug runner for full Scene/Runtime Warning fixture.
extends SceneTree

const TEST_SUITES := [
	{"name": "battle/test_battle_runtime_probe_medium_density_filled_slots", "path": "res://tests/battle/test_battle_runtime_probe_medium_density_filled_slots.gd"}
]

var _failure_count := 0
var _test_count := 0

func _initialize() -> void:
	print("[TEST] Starting Warning fixture runner...")
	for suite_def in TEST_SUITES:
		await _run_suite(str(suite_def.name), str(suite_def.path))
	if _failure_count == 0:
		print("[TEST] All %d Warning fixture suite(s) passed." % _test_count)
		quit(0)
		return
	printerr("[TEST] %d failure(s) across %d Warning fixture suite(s)." % [_failure_count, _test_count])
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
	var result: Variant = await suite.run()
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
