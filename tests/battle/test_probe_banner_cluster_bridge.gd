extends RefCounted

const SCRIPT_PATH := "res://tests/test_runner.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(SCRIPT_PATH)
	var banner_chain_index := source.find('"battle/test_probe_banner_chain"')
	var banner_bridge_index := source.find('"battle/test_probe_contract_banner_bridge"')
	var contract_chain_index := source.find('"battle/test_probe_contract_ordering_chain"')
	_assert_true(banner_chain_index != -1, "test_runner should include battle/test_probe_banner_chain", failures)
	_assert_true(banner_bridge_index != -1, "test_runner should include battle/test_probe_contract_banner_bridge", failures)
	_assert_true(contract_chain_index != -1, "test_runner should include battle/test_probe_contract_ordering_chain", failures)
	if banner_chain_index != -1 and banner_bridge_index != -1:
		_assert_true(banner_bridge_index > banner_chain_index, "probe contract banner bridge should stay after the banner chain", failures)
	if banner_bridge_index != -1 and contract_chain_index != -1:
		_assert_true(contract_chain_index > banner_bridge_index, "probe contract ordering chain should stay after the banner bridge", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
