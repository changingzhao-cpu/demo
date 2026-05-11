extends RefCounted

const TARGET_SCRIPT := preload("res://tests/battle/test_probe_warning_runtime_variation_contract.gd")

func run() -> Array[String]:
	var suite = TARGET_SCRIPT.new()
	if suite == null:
		return ["variation runner should instantiate target suite"]
	if not suite.has_method("run"):
		return ["variation runner target should expose run()"]
	var failures: Array[String] = await suite.run()
	return failures
