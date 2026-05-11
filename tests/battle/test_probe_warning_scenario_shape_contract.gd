extends RefCounted

const TARGET_PATH := "res://tests/battle/test_warning_aggregation_contract.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(TARGET_PATH)
	_assert_true(source.contains('aggregation contract should preserve p95 contention gradient'), "corridor should remain the densest scenario via aggregation contract", failures)
	_assert_true(source.contains('aggregation contract should preserve claim success gradient'), "dynamic orbit should remain the highest claim-success scenario via aggregation contract", failures)
	_assert_true(source.contains('aggregation contract should preserve late commit deviation gradient'), "corridor should remain the highest late-commit-deviation scenario via aggregation contract", failures)
	_assert_true(source.contains('aggregation contract should preserve arbitration latency ordering'), "dynamic orbit should remain the highest-latency scenario via aggregation contract", failures)
	_assert_true(source.contains('aggregation contract should preserve overlap gradient'), "funnel should remain the middle overlap scenario via aggregation contract", failures)
	_assert_true(source.contains('aggregation contract should preserve clumping gradient'), "funnel should remain the middle clumping scenario via aggregation contract", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
