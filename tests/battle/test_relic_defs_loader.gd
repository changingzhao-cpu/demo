extends RefCounted

const RELIC_DEFS_PATH := "res://data/relic_defs.json"
const REQUIRED_KEYS := [
	"id",
	"name",
	"category",
	"weight",
	"tags",
	"modifiers"
]
const ALLOWED_CATEGORIES := {
	"unit": true,
	"count": true,
	"relic": true
}

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_relic_defs_file_exists(failures)
	_test_relic_defs_json_parses_to_array(failures)
	_test_relic_defs_have_required_fields(failures)
	_test_relic_defs_use_supported_categories(failures)
	_test_relic_defs_weights_are_positive(failures)
	return failures

func _test_relic_defs_file_exists(failures: Array[String]) -> void:
	_assert_true(FileAccess.file_exists(RELIC_DEFS_PATH), "relic defs file should exist", failures)

func _test_relic_defs_json_parses_to_array(failures: Array[String]) -> void:
	var parsed: Variant = _load_relic_defs(failures)
	if parsed == null:
		return
	_assert_true(parsed is Array, "relic defs should parse to Array", failures)
	if parsed is Array:
		_assert_true(not parsed.is_empty(), "relic defs should contain at least one relic", failures)

func _test_relic_defs_have_required_fields(failures: Array[String]) -> void:
	var parsed: Variant = _load_relic_defs(failures)
	if not parsed is Array:
		return
	for entry in parsed:
		if not _assert_true(entry is Dictionary, "each relic definition should be a Dictionary", failures):
			continue
		for key in REQUIRED_KEYS:
			_assert_true(entry.has(key), "relic definition missing key '%s'" % key, failures)

func _test_relic_defs_use_supported_categories(failures: Array[String]) -> void:
	var parsed: Variant = _load_relic_defs(failures)
	if not parsed is Array:
		return
	for entry in parsed:
		if not entry is Dictionary:
			continue
		var category := str(entry.get("category", ""))
		_assert_true(ALLOWED_CATEGORIES.has(category), "unsupported category '%s' in relic defs" % category, failures)

func _test_relic_defs_weights_are_positive(failures: Array[String]) -> void:
	var parsed: Variant = _load_relic_defs(failures)
	if not parsed is Array:
		return
	for entry in parsed:
		if not entry is Dictionary:
			continue
		var weight: float = float(entry.get("weight", 0.0))
		_assert_true(weight > 0.0, "relic weight should be positive", failures)

func _load_relic_defs(failures: Array[String]):
	if not FileAccess.file_exists(RELIC_DEFS_PATH):
		return null
	var file := FileAccess.open(RELIC_DEFS_PATH, FileAccess.READ)
	if file == null:
		failures.append("relic defs file should be readable")
		return null
	var content := file.get_as_text()
	var parsed: Variant = JSON.parse_string(content)
	if parsed == null:
		failures.append("relic defs should contain valid JSON")
		return null
	return parsed

func _assert_true(value: bool, message: String, failures: Array[String]) -> bool:
	if not value:
		failures.append(message)
	return value
