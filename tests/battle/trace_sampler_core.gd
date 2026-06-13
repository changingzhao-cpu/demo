extends RefCounted
class_name TraceSamplerCore

func validate(runtime_snapshot: Dictionary, trace_payload: Dictionary) -> Array[String]:
	var failures: Array[String] = []
	var probe: Dictionary = trace_payload.get("probe", {})
	_assert_eq(str(runtime_snapshot.get("backend", "")), "v4", "runtime snapshot should report v4 backend", failures)
	_assert_true(trace_payload.has("backend"), "runtime anomaly trace should expose backend", failures)
	_assert_eq(str(trace_payload.get("backend", "")), "v4", "runtime anomaly trace should report v4 backend", failures)
	_assert_true(trace_payload.has("history_limit"), "runtime anomaly trace should expose history_limit", failures)
	_assert_true(trace_payload.has("samples"), "runtime anomaly trace should expose bounded samples", failures)
	_assert_true(trace_payload.has("movement_anomalies"), "runtime anomaly trace should expose movement anomalies", failures)
	_assert_true(not probe.is_empty(), "runtime anomaly trace should expose non-empty v4 probe", failures)
	_assert_true(probe.has("claim_success_rate"), "runtime anomaly trace should expose v4 claim_success_rate", failures)
	_assert_true(probe.has("contention_index"), "runtime anomaly trace should expose v4 contention_index", failures)
	_assert_true(probe.has("late_commit_deviation"), "runtime anomaly trace should expose v4 late_commit_deviation", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)

func _assert_eq(actual, expected, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s (expected=%s, actual=%s)" % [message, str(expected), str(actual)])
