extends RefCounted

const TraceSamplerCore = preload("res://tests/battle/trace_sampler_core.gd")

func run() -> Array[String]:
	var runtime_snapshot := {
		"backend": "v4"
	}
	var trace_payload := {
		"backend": "v4",
		"history_limit": 32,
		"samples": [],
		"movement_anomalies": [],
		"probe": {
			"claim_success_rate": 0.2,
			"contention_index": 0.48,
			"late_commit_deviation": 6.0
		}
	}
	var core := TraceSamplerCore.new()
	return core.validate(runtime_snapshot, trace_payload)
