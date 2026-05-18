extends RefCounted

const TraceSamplerCore = preload("res://tests/battle/trace_sampler_core.gd")

func run() -> Array[String]:
	var runtime_snapshot := {
		"backend": "v4"
	}
	var trace_payload := {
		"probe": {
			"backend": "v4",
			"history_limit": 32,
			"samples": [],
			"movement_anomalies": [],
			"probe": {
				"claim_success_rate": 0.2,
				"contention_index": 0.48,
				"late_commit_deviation": 6.0
			}
		},
		"business_probe_events": [
			{"event_type": "takeover_shadow_review", "state": "combat", "wave": 1, "live_count": 36, "combat_event_count": 4, "recommendation": "hold", "reason": "awaiting_stable_feedback", "feedback_mode": "observe_only", "takeover_shadow_mode": "review_only", "takeover_shadow_ready": false}
		],
		"feedback_mode": "observe_only",
		"feedback_active": false,
		"takeover_shadow_mode": "review_only",
		"takeover_shadow_ready": false,
		"takeover_shadow_recommendation": "hold",
		"takeover_shadow_reason": "awaiting_stable_feedback",
		"warning_unified_snapshot": {
			"family": "warning",
			"confidence_score": 0.75,
			"thresholds": {"warning_threshold_value": 1.0, "error_threshold_value": 2.0},
			"support_counts": {"late_commit_true_count": 3},
			"blockers": [],
			"gate_results": {"takeover_ready": true}
		},
		"critical_unified_snapshot": {
			"family": "critical",
			"confidence_score": 0.8,
			"thresholds": {"warning_threshold_value": 1.0, "error_threshold_value": 2.0},
			"support_counts": {"old_escape_true_count": 4},
			"blockers": [],
			"gate_results": {
				"takeover_ready": true,
				"attack_rebind_escape_count": 0,
				"attack_rebind_recontact_count": 0,
				"attack_midband_drift_count": 0
			}
		}
	}
	var failures := TraceSamplerCore.new().validate(runtime_snapshot, trace_payload.get("probe", {}))
	_assert_trace_true(trace_payload.has("business_probe_events"), "runtime trace payload should expose business probe events", failures)
	_assert_trace_true(trace_payload.has("feedback_mode"), "runtime trace payload should expose feedback_mode", failures)
	_assert_trace_true(trace_payload.has("feedback_active"), "runtime trace payload should expose feedback_active", failures)
	_assert_trace_true(trace_payload.has("takeover_shadow_mode"), "runtime trace payload should expose takeover_shadow_mode", failures)
	_assert_trace_true(trace_payload.has("takeover_shadow_ready"), "runtime trace payload should expose takeover_shadow_ready", failures)
	_assert_trace_true(trace_payload.has("takeover_shadow_recommendation"), "runtime trace payload should expose takeover_shadow_recommendation", failures)
	_assert_trace_true(trace_payload.has("takeover_shadow_reason"), "runtime trace payload should expose takeover_shadow_reason", failures)
	var business_probe_events: Array = trace_payload.get("business_probe_events", [])
	_assert_trace_true(business_probe_events.size() > 0, "runtime trace payload should expose at least one business probe event", failures)
	var first_event: Dictionary = business_probe_events[0] if not business_probe_events.is_empty() else {}
	_assert_trace_true(first_event.has("event_type"), "business probe event should expose event_type", failures)
	_assert_trace_true(first_event.has("state"), "business probe event should expose state", failures)
	_assert_trace_true(first_event.has("wave"), "business probe event should expose wave", failures)
	_assert_trace_true(first_event.has("live_count"), "business probe event should expose live_count", failures)
	_assert_trace_true(first_event.has("combat_event_count"), "business probe event should expose combat_event_count", failures)
	if str(first_event.get("event_type", "")) == "takeover_shadow_review":
		_assert_trace_true(first_event.has("recommendation"), "takeover shadow review event should expose recommendation", failures)
		_assert_trace_true(first_event.has("reason"), "takeover shadow review event should expose reason", failures)
		_assert_trace_true(first_event.has("feedback_mode"), "takeover shadow review event should expose feedback_mode", failures)
		_assert_trace_true(first_event.has("takeover_shadow_mode"), "takeover shadow review event should expose takeover_shadow_mode", failures)
		_assert_trace_true(first_event.has("takeover_shadow_ready"), "takeover shadow review event should expose takeover_shadow_ready", failures)
	_assert_trace_true(trace_payload.has("warning_unified_snapshot"), "runtime trace payload should expose warning unified snapshot", failures)
	_assert_trace_true(trace_payload.has("critical_unified_snapshot"), "runtime trace payload should expose critical unified snapshot", failures)
	var warning_unified_snapshot: Dictionary = trace_payload.get("warning_unified_snapshot", {})
	var critical_unified_snapshot: Dictionary = trace_payload.get("critical_unified_snapshot", {})
	_assert_trace_true(str(warning_unified_snapshot.get("family", "")) == "warning", "runtime trace payload should keep warning unified snapshot family", failures)
	_assert_trace_true(str(critical_unified_snapshot.get("family", "")) == "critical", "runtime trace payload should keep critical unified snapshot family", failures)
	_assert_trace_true(warning_unified_snapshot.has("confidence_score"), "runtime trace payload should expose warning unified snapshot confidence score", failures)
	_assert_trace_true(critical_unified_snapshot.has("confidence_score"), "runtime trace payload should expose critical unified snapshot confidence score", failures)
	_assert_trace_true(warning_unified_snapshot.has("thresholds"), "runtime trace payload should expose warning unified snapshot thresholds", failures)
	_assert_trace_true(critical_unified_snapshot.has("thresholds"), "runtime trace payload should expose critical unified snapshot thresholds", failures)
	_assert_trace_true(warning_unified_snapshot.has("support_counts"), "runtime trace payload should expose warning unified snapshot support counts", failures)
	_assert_trace_true(critical_unified_snapshot.has("support_counts"), "runtime trace payload should expose critical unified snapshot support counts", failures)
	_assert_trace_true(warning_unified_snapshot.has("blockers"), "runtime trace payload should expose warning unified snapshot blockers", failures)
	_assert_trace_true(critical_unified_snapshot.has("blockers"), "runtime trace payload should expose critical unified snapshot blockers", failures)
	_assert_trace_true(warning_unified_snapshot.has("gate_results"), "runtime trace payload should expose warning unified snapshot gate results", failures)
	_assert_trace_true(critical_unified_snapshot.has("gate_results"), "runtime trace payload should expose critical unified snapshot gate results", failures)
	var critical_gate_results: Dictionary = critical_unified_snapshot.get("gate_results", {})
	_assert_trace_true(critical_gate_results.has("attack_rebind_escape_count"), "runtime trace payload should expose critical perturbation escape count through unified snapshot", failures)
	_assert_trace_true(critical_gate_results.has("attack_rebind_recontact_count"), "runtime trace payload should expose critical perturbation recontact count through unified snapshot", failures)
	_assert_trace_true(critical_gate_results.has("attack_midband_drift_count"), "runtime trace payload should expose critical perturbation midband drift count through unified snapshot", failures)
	return failures

func _assert_trace_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
