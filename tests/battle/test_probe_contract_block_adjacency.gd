extends RefCounted

const SCRIPT_PATH := "res://tests/test_runner.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(SCRIPT_PATH)
	var lines := source.split("\n")
	var indexes := {}
	for i in range(lines.size()):
		var line := lines[i]
		if line.contains('"battle/test_debug_runtime_probe_fingerprint_contract"'):
			indexes["runtime"] = i
		elif line.contains('"battle/test_runtime_probe_oscillation_fingerprint_contract"'):
			indexes["oscillation"] = i
		elif line.contains('"battle/test_v4_probe_contract_matrix"'):
			indexes["matrix"] = i
	_assert_true(indexes.has("runtime") and indexes.has("oscillation") and indexes.has("matrix"), "test_runner should include the probe contract block entries", failures)
	if indexes.has("runtime") and indexes.has("oscillation"):
		_assert_true(int(indexes["oscillation"]) == int(indexes["runtime"]) + 1, "oscillation fingerprint contract should stay adjacent to runtime probe fingerprint contract", failures)
	if indexes.has("oscillation") and indexes.has("matrix"):
		_assert_true(int(indexes["matrix"]) == int(indexes["oscillation"]) + 1, "probe contract matrix should stay adjacent to oscillation fingerprint contract", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
