extends RefCounted

const UNIT_DEFS_PATH := "res://data/unit_defs.json"
const REQUIRED_KEYS := [
	"id",
	"name",
	"archetype",
	"max_hp",
	"move_speed",
	"attack_interval",
	"attack_range",
	"radius",
	"base_damage",
	"sprite_key"
]
const ALLOWED_ARCHETYPES := {
	"melee": true,
	"caster": true,
	"support": true,
	"assassin": true
}

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_unit_defs_file_exists(failures)
	_test_unit_defs_json_parses_to_array(failures)
	_test_unit_defs_have_required_fields(failures)
	_test_unit_defs_use_supported_archetypes(failures)
	return failures

func _test_unit_defs_file_exists(failures: Array[String]) -> void:
	_assert_true(FileAccess.file_exists(UNIT_DEFS_PATH), "unit defs file should exist", failures)

func _test_unit_defs_json_parses_to_array(failures: Array[String]) -> void:
	var parsed: Variant = _load_unit_defs(failures)
	if parsed == null:
		return
	_assert_true(parsed is Array, "unit defs should parse to Array", failures)
	if parsed is Array:
		_assert_true(not parsed.is_empty(), "unit defs should contain at least one unit", failures)

func _test_unit_defs_have_required_fields(failures: Array[String]) -> void:
	var parsed: Variant = _load_unit_defs(failures)
	if not parsed is Array:
		return
	for entry in parsed:
		if not _assert_true(entry is Dictionary, "each unit definition should be a Dictionary", failures):
			continue
		for key in REQUIRED_KEYS:
			_assert_true(entry.has(key), "unit definition missing key '%s'" % key, failures)

func _test_unit_defs_use_supported_archetypes(failures: Array[String]) -> void:
	var parsed: Variant = _load_unit_defs(failures)
	if not parsed is Array:
		return
	for entry in parsed:
		if not entry is Dictionary:
			continue
		if not entry.has("archetype"):
			continue
		var archetype := str(entry["archetype"])
		_assert_true(ALLOWED_ARCHETYPES.has(archetype), "unsupported archetype '%s' in unit defs" % archetype, failures)

func _load_unit_defs(failures: Array[String]):
	if not FileAccess.file_exists(UNIT_DEFS_PATH):
		return null
	var file := FileAccess.open(UNIT_DEFS_PATH, FileAccess.READ)
	if file == null:
		failures.append("unit defs file should be readable")
		return null
	var content := file.get_as_text()
	var parsed: Variant = JSON.parse_string(content)
	if parsed == null:
		failures.append("unit defs should contain valid JSON")
		return null
	return parsed

func _assert_true(value: bool, message: String, failures: Array[String]) -> bool:
	if not value:
		failures.append(message)
	return value
