extends RefCounted

const TRACE_CONTRACT_PATH := "res://tests/battle/test_battle_runtime_probe_trace_contract.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(TRACE_CONTRACT_PATH)
	_assert_true(source.contains('preload("res://tests/battle/trace_sampler_core.gd")'), "trace contract should depend on trace sampler core", failures)
	_assert_true(not source.contains('get_root().add_child(instance)'), "trace contract should not embed SceneTree shell steps", failures)
	_assert_true(not source.contains('await process_frame'), "trace contract should not await SceneTree frames directly", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
