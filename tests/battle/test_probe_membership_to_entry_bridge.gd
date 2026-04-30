extends RefCounted

const SCRIPT_PATH := "res://tests/test_runner.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(SCRIPT_PATH)
	var membership_bridge_index := source.find('"battle/test_probe_membership_to_banner_transition"')
	var entry_cluster_bridge_index := source.find('"battle/test_probe_entry_cluster_to_contract_cluster"')
	_assert_true(membership_bridge_index != -1, "test_runner should include battle/test_probe_membership_to_banner_transition", failures)
	_assert_true(entry_cluster_bridge_index != -1, "test_runner should include battle/test_probe_entry_cluster_to_contract_cluster", failures)
	if membership_bridge_index != -1 and entry_cluster_bridge_index != -1:
		_assert_true(entry_cluster_bridge_index > membership_bridge_index, "probe entry cluster bridge should stay after the membership bridge", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
