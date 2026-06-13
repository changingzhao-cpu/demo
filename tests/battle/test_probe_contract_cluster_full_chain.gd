extends RefCounted

const SCRIPT_PATH := "res://tests/test_runner.gd"
const REQUIRED_ORDER := [
	'battle/test_probe_contract_ordering',
	'battle/test_probe_contract_block_adjacency',
	'battle/test_runner_contract_cluster',
	'battle/test_probe_contract_block_bounds',
	'battle/test_probe_contract_projection_boundary',
	'battle/test_probe_contract_late_chain',
	'battle/test_probe_contract_tail_adjacency',
	'battle/test_probe_contract_block_before_core_tests',
	'battle/test_probe_contract_cluster_ordering',
	'battle/test_probe_contract_final_block_order',
	'battle/test_probe_contract_to_core_transition'
]

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(SCRIPT_PATH)
	var previous_index := -1
	for suite_name_variant in REQUIRED_ORDER:
		var suite_name := str(suite_name_variant)
		var current_index := source.find('"%s"' % suite_name)
		_assert_true(current_index != -1, "test_runner should include %s" % suite_name, failures)
		if previous_index != -1 and current_index != -1:
			_assert_true(current_index > previous_index, "%s should stay after the previous contract chain entry" % suite_name, failures)
		previous_index = current_index
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
