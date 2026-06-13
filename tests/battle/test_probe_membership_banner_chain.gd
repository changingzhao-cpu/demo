extends RefCounted

const SCRIPT_PATH := "res://tests/test_runner.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(SCRIPT_PATH)
	var membership_cluster_index := source.find('"battle/test_probe_membership_cluster_ordering"')
	var membership_banner_index := source.find('"battle/test_probe_membership_to_banner_transition"')
	var runner_v4_banner_index := source.find('"battle/test_runner_v4_banner_contract"')
	_assert_true(membership_cluster_index != -1, "test_runner should include battle/test_probe_membership_cluster_ordering", failures)
	_assert_true(membership_banner_index != -1, "test_runner should include battle/test_probe_membership_to_banner_transition", failures)
	_assert_true(runner_v4_banner_index != -1, "test_runner should include battle/test_runner_v4_banner_contract", failures)
	if membership_cluster_index != -1 and membership_banner_index != -1:
		_assert_true(membership_banner_index > membership_cluster_index, "membership-to-banner transition should stay after membership cluster ordering", failures)
	if membership_banner_index != -1 and runner_v4_banner_index != -1:
		_assert_true(runner_v4_banner_index > membership_banner_index, "runner V4 banner contract should stay after membership-to-banner transition", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
