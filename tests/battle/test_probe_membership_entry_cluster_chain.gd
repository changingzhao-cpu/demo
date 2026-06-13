extends RefCounted

const SCRIPT_PATH := "res://tests/test_runner.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(SCRIPT_PATH)
	var membership_cluster_index := source.find('"battle/test_probe_membership_cluster_ordering"')
	var membership_to_banner_index := source.find('"battle/test_probe_membership_to_banner_transition"')
	var membership_to_entry_index := source.find('"battle/test_probe_membership_to_entry_bridge"')
	var entry_cluster_index := source.find('"battle/test_probe_entry_cluster_to_contract_cluster"')
	_assert_true(membership_cluster_index != -1, "test_runner should include battle/test_probe_membership_cluster_ordering", failures)
	_assert_true(membership_to_banner_index != -1, "test_runner should include battle/test_probe_membership_to_banner_transition", failures)
	_assert_true(membership_to_entry_index != -1, "test_runner should include battle/test_probe_membership_to_entry_bridge", failures)
	_assert_true(entry_cluster_index != -1, "test_runner should include battle/test_probe_entry_cluster_to_contract_cluster", failures)
	if membership_cluster_index != -1 and membership_to_banner_index != -1:
		_assert_true(membership_to_banner_index > membership_cluster_index, "membership-to-banner bridge should stay after membership cluster ordering", failures)
	if membership_to_banner_index != -1 and membership_to_entry_index != -1:
		_assert_true(membership_to_entry_index > membership_to_banner_index, "membership-to-entry bridge should stay after membership-to-banner bridge", failures)
	if membership_to_entry_index != -1 and entry_cluster_index != -1:
		_assert_true(entry_cluster_index > membership_to_entry_index, "entry cluster bridge should stay after membership-to-entry bridge", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
