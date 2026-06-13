extends RefCounted

const WARNING_TRACE_PATH := "user://warning_variation_trace.log"
const WARNING_SAMPLER_CORE := preload("res://tests/battle/battle_warning_sampler_core.gd")

func run() -> Array[String]:
	_clear_trace()
	_trace("VARIATION_RUN_START")
	var failures: Array[String] = []
	var samples_variant: Array = []
	for scenario in ["corridor", "dynamic_orbit", "funnel"]:
		for run_id in range(6):
			_trace("CORE_SAMPLE %s:%d" % [scenario, run_id])
			var sampler_core = WARNING_SAMPLER_CORE.new(scenario, run_id)
			var probe := {
				"p95_contention": float(run_id + 1) * (3.0 if scenario == "corridor" else 2.0 if scenario == "funnel" else 1.0),
				"conflict_overlap_count": int(run_id + 1) * (3 if scenario == "corridor" else 2 if scenario == "funnel" else 1),
				"arbitration_latency": float(run_id + 1) * (0.30 if scenario == "corridor" else 0.20 if scenario == "funnel" else 0.10),
				"clumping_factor": float(run_id + 1) * (0.15 if scenario == "corridor" else 0.10 if scenario == "funnel" else 0.05),
				"claim_success_rate": 0.25,
				"assignments": {1: {"assigned_slot_index": 0}}
			}
			samples_variant.append(sampler_core.sample(probe))
	_trace("CORE_SAMPLE_DONE")
	var scenario_metric_values := {
		"corridor": {"p95_contention": {}, "conflict_overlap_count": {}, "arbitration_latency": {}, "clumping_factor": {}},
		"dynamic_orbit": {"p95_contention": {}, "conflict_overlap_count": {}, "arbitration_latency": {}, "clumping_factor": {}},
		"funnel": {"p95_contention": {}, "conflict_overlap_count": {}, "arbitration_latency": {}, "clumping_factor": {}}
	}
	for sample_variant in samples_variant:
		if not (sample_variant is Dictionary):
			continue
		var sample: Dictionary = sample_variant
		var scenario := str(sample.get("scenario", ""))
		if not scenario_metric_values.has(scenario):
			continue
		var metric_values: Dictionary = scenario_metric_values[scenario]
		_register_metric_value(metric_values, "p95_contention", sample.get("p95_contention", null))
		_register_metric_value(metric_values, "conflict_overlap_count", sample.get("conflict_overlap_count", null))
		_register_metric_value(metric_values, "arbitration_latency", sample.get("arbitration_latency", null))
		_register_metric_value(metric_values, "clumping_factor", sample.get("clumping_factor", null))
	for scenario in ["corridor", "dynamic_orbit", "funnel"]:
		var metric_values: Dictionary = scenario_metric_values[scenario]
		var has_runtime_variation := false
		for metric_name in ["p95_contention", "conflict_overlap_count", "arbitration_latency", "clumping_factor"]:
			var value_set: Dictionary = metric_values[metric_name]
			if value_set.size() > 1:
				has_runtime_variation = true
				break
		_assert_true(has_runtime_variation, "%s should expose runtime variation in at least one warning metric" % scenario, failures)
	return failures

func _register_metric_value(metric_values: Dictionary, metric_name: String, value: Variant) -> void:
	var value_set: Dictionary = metric_values.get(metric_name, {})
	value_set[str(value)] = true
	metric_values[metric_name] = value_set

func _clear_trace() -> void:
	var file := FileAccess.open(WARNING_TRACE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string("")
		file.close()

func _trace(message: String) -> void:
	var file := FileAccess.open(WARNING_TRACE_PATH, FileAccess.READ_WRITE)
	if file == null:
		return
	file.seek_end()
	file.store_line(message)
	file.close()

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
