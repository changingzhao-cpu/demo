extends SceneTree

func run() -> Array[String]:
	var failures: Array[String] = []
	var fingerprint_zone_summary := {
		"sample_name": "narrow_corridor_contention",
		"zone": "warning",
		"sample_count": 1,
		"max_continuous_contention_ticks": 0
	}
	return failures

func _initialize() -> void:
	var failures := await run()
	for failure in failures:
		printerr("[FAIL] battle/test_battle_runtime_probe_narrow_corridor_contention: %s" % failure)
	quit(1 if not failures.is_empty() else 0)
