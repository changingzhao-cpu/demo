extends RefCounted

const SCRIPT_PATH := "res://tests/test_runner.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(SCRIPT_PATH)
	var lines := source.split("\n")
	var first_contract_index := -1
	var last_contract_index := -1
	var projection_index := -1
	for i in range(lines.size()):
		var line := lines[i]
		if line.contains('"battle/test_debug_runtime_probe_fingerprint_contract"') and first_contract_index == -1:
			first_contract_index = i
		if line.contains('"battle/test_runner_contract_cluster"'):
			last_contract_index = i
		if line.contains('"battle/test_battle_projection"'):
			projection_index = i
	_assert_true(first_contract_index != -1, "test_runner should contain the first probe contract entry", failures)
	_assert_true(last_contract_index != -1, "test_runner should contain the last probe contract cluster entry", failures)
	_assert_true(projection_index != -1, "test_runner should contain battle/test_battle_projection", failures)
	if first_contract_index != -1 and last_contract_index != -1:
		_assert_true(first_contract_index < last_contract_index, "probe contract block should have a valid start/end ordering", failures)
	if last_contract_index != -1 and projection_index != -1:
		_assert_true(last_contract_index < projection_index, "probe contract block should stay before battle/test_battle_projection", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
