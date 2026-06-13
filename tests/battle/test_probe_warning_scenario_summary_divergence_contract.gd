extends RefCounted

const ARTIFACT_PATH := "user://warning_sampling.json"

func run() -> Array[String]:
	var failures: Array[String] = []
	var text := FileAccess.get_file_as_string(ARTIFACT_PATH)
	_assert_true(text != "", "warning artifact should exist before scenario divergence checks", failures)
	if text == "":
		return failures
	var json := JSON.new()
	var parse_result := json.parse(text)
	_assert_true(parse_result == OK, "warning artifact should parse as json", failures)
	if parse_result != OK:
		return failures
	var payload: Dictionary = json.data
	var scenario_summaries: Dictionary = payload.get("scenario_summaries", {})
	var corridor: Dictionary = scenario_summaries.get("corridor", {})
	var funnel: Dictionary = scenario_summaries.get("funnel", {})
	var orbit: Dictionary = scenario_summaries.get("dynamic_orbit", {})
	var p95_gap_cf := float(corridor.get("p95_contention_mean", 0.0)) - float(funnel.get("p95_contention_mean", 0.0))
	var p95_gap_fo := float(funnel.get("p95_contention_mean", 0.0)) - float(orbit.get("p95_contention_mean", 0.0))
	var overlap_gap_cf := float(corridor.get("conflict_overlap_count_mean", 0.0)) - float(funnel.get("conflict_overlap_count_mean", 0.0))
	var overlap_gap_fo := float(funnel.get("conflict_overlap_count_mean", 0.0)) - float(orbit.get("conflict_overlap_count_mean", 0.0))
	var clumping_gap_cf := float(corridor.get("clumping_factor_mean", 0.0)) - float(funnel.get("clumping_factor_mean", 0.0))
	var clumping_gap_fo := float(funnel.get("clumping_factor_mean", 0.0)) - float(orbit.get("clumping_factor_mean", 0.0))
	_assert_true(p95_gap_cf > p95_gap_fo * 2.0, "warning artifact should keep a stronger corridor→funnel p95 step than funnel→orbit", failures)
	_assert_true(p95_gap_cf > 3.0, "warning artifact should keep a large corridor→orbit p95 spread", failures)
	_assert_true(overlap_gap_cf > overlap_gap_fo * 2.0, "warning artifact should keep a stronger corridor→funnel overlap step than funnel→orbit", failures)
	_assert_true(overlap_gap_cf >= 4.0, "warning artifact should keep a large corridor→orbit overlap spread", failures)
	_assert_true(clumping_gap_cf > clumping_gap_fo * 2.0, "warning artifact should keep a stronger corridor→funnel clumping step than funnel→orbit", failures)
	_assert_true(clumping_gap_cf > 0.45, "warning artifact should keep a large corridor→orbit clumping spread", failures)
	_assert_true(float(orbit.get("arbitration_latency_mean", 0.0)) - float(corridor.get("arbitration_latency_mean", 0.0)) > 0.7, "warning artifact should keep a large orbit→corridor latency spread", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
