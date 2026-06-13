extends RefCounted

const TARGET_PATH := "res://tests/battle/test_probe_schema_contract.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string(TARGET_PATH)
	_assert_true(source.contains('probe schema should include p95_contention'), "warning runtime signal contract should now be enforced by probe schema contract for p95_contention", failures)
	_assert_true(source.contains('probe schema should include conflict_overlap_count'), "warning runtime signal contract should now be enforced by probe schema contract for conflict_overlap_count", failures)
	_assert_true(source.contains('probe schema should include clumping_factor'), "warning runtime signal contract should now be enforced by probe schema contract for clumping_factor", failures)
	_assert_true(source.contains('probe schema should include arbitration_latency'), "warning runtime signal contract should now be enforced by probe schema contract for arbitration_latency", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
