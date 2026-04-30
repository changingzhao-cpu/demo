extends RefCounted

const SCRIPT_PATH := "res://tests/test_runner.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(SCRIPT_PATH)
	var entry_to_fingerprint_index := source.find('"battle/test_probe_entry_to_fingerprint_transition"')
	var entry_block_adjacency_index := source.find('"battle/test_probe_entry_block_adjacency"')
	var entry_internal_adjacency_index := source.find('"battle/test_probe_entry_internal_adjacency"')
	_assert_true(entry_to_fingerprint_index != -1, "test_runner should include battle/test_probe_entry_to_fingerprint_transition", failures)
	_assert_true(entry_block_adjacency_index != -1, "test_runner should include battle/test_probe_entry_block_adjacency", failures)
	_assert_true(entry_internal_adjacency_index != -1, "test_runner should include battle/test_probe_entry_internal_adjacency", failures)
	if entry_to_fingerprint_index != -1 and entry_block_adjacency_index != -1:
		_assert_true(entry_block_adjacency_index > entry_to_fingerprint_index, "probe entry block adjacency should stay after entry-to-fingerprint transition", failures)
	if entry_block_adjacency_index != -1 and entry_internal_adjacency_index != -1:
		_assert_true(entry_internal_adjacency_index > entry_block_adjacency_index, "probe entry internal adjacency should stay after probe entry block adjacency", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
