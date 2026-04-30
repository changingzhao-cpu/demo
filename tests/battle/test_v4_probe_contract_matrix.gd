extends RefCounted

const TARGETS := [
	{"label": "backend trace", "path": "res://tests/battle/debug_probe_backend_trace.gd"},
	{"label": "identity trace", "path": "res://tests/battle/debug_probe_identity_trace.gd"},
	{"label": "debug runtime probe", "path": "res://tests/debug_runtime_probe.gd"},
	{"label": "oscillation fixture", "path": "res://tests/battle/test_battle_runtime_probe_contact_oscillation.gd"}
]

const REQUIRED_TOKENS := [
	'"v4_probe_fingerprint"',
	'"v4_probe_baseline"',
	'claim_success_rate=',
	'contention_index=',
	'late_commit_deviation=',
	'assignment_count='
]

func run() -> Array[String]:
	var failures: Array[String] = []
	for target_variant in TARGETS:
		var target: Dictionary = target_variant
		var label := str(target.get("label", "target"))
		var path := str(target.get("path", ""))
		var source := FileAccess.get_file_as_string(path)
		for token_variant in REQUIRED_TOKENS:
			var token := str(token_variant)
			_assert_true(source.contains(token), "%s should contain %s" % [label, token], failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
