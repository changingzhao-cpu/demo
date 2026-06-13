extends RefCounted

const SCRIPT_PATH := "res://tests/test_runner.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(SCRIPT_PATH)
	var banner_to_contract_index := source.find('"battle/test_probe_banner_to_contract_ordering"')
	var banner_chain_index := source.find('"battle/test_probe_banner_chain"')
	var contract_banner_bridge_index := source.find('"battle/test_probe_contract_banner_bridge"')
	_assert_true(banner_to_contract_index != -1, "test_runner should include battle/test_probe_banner_to_contract_ordering", failures)
	_assert_true(banner_chain_index != -1, "test_runner should include battle/test_probe_banner_chain", failures)
	_assert_true(contract_banner_bridge_index != -1, "test_runner should include battle/test_probe_contract_banner_bridge", failures)
	if banner_to_contract_index != -1 and banner_chain_index != -1:
		_assert_true(banner_chain_index > banner_to_contract_index, "probe banner chain should stay after probe banner-to-contract ordering", failures)
	if banner_chain_index != -1 and contract_banner_bridge_index != -1:
		_assert_true(contract_banner_bridge_index > banner_chain_index, "probe contract banner bridge should stay after the probe banner chain", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
