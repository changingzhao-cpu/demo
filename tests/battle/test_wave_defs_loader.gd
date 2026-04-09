extends RefCounted

const WAVE_DEFS_PATH := "res://data/wave_defs.json"
const REQUIRED_KEYS := [
	"wave",
	"enemy_count",
	"enemy_comp",
	"spawn_batch_size",
	"tags"
]

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_wave_defs_file_exists(failures)
	_test_wave_defs_json_parses_to_array(failures)
	_test_wave_defs_have_required_fields(failures)
	_test_wave_defs_cover_twelve_waves(failures)
	_test_wave_enemy_counts_increase_over_run(failures)
	return failures

func _test_wave_defs_file_exists(failures: Array[String]) -> void:
	_assert_true(FileAccess.file_exists(WAVE_DEFS_PATH), "wave defs file should exist", failures)

func _test_wave_defs_json_parses_to_array(failures: Array[String]) -> void:
	var parsed: Variant = _load_wave_defs(failures)
	if parsed == null:
		return
	_assert_true(parsed is Array, "wave defs should parse to Array", failures)
	if parsed is Array:
		_assert_true(parsed.size() == 12, "wave defs should contain exactly 12 waves", failures)

func _test_wave_defs_have_required_fields(failures: Array[String]) -> void:
	var parsed: Variant = _load_wave_defs(failures)
	if not parsed is Array:
		return
	for entry in parsed:
		if not _assert_true(entry is Dictionary, "each wave definition should be a Dictionary", failures):
			continue
		for key in REQUIRED_KEYS:
			_assert_true(entry.has(key), "wave definition missing key '%s'" % key, failures)

func _test_wave_defs_cover_twelve_waves(failures: Array[String]) -> void:
	var parsed: Variant = _load_wave_defs(failures)
	if not parsed is Array:
		return
	for index in range(parsed.size()):
		var entry = parsed[index]
		if not entry is Dictionary:
			continue
		_assert_true(entry.get("wave", -1) == index + 1, "wave definitions should be numbered sequentially from 1 to 12", failures)

func _test_wave_enemy_counts_increase_over_run(failures: Array[String]) -> void:
	var parsed: Variant = _load_wave_defs(failures)
	if not parsed is Array:
		return
	if parsed.size() < 2:
		return
	var first_wave = parsed[0]
	var last_wave = parsed[parsed.size() - 1]
	if not (first_wave is Dictionary and last_wave is Dictionary):
		return
	var first_count: int = int(first_wave.get("enemy_count", 0))
	var last_count: int = int(last_wave.get("enemy_count", 0))
	_assert_true(first_count >= 5, "first wave should start near the 5v5 baseline", failures)
	_assert_true(last_count > first_count, "later waves should have more enemies than early waves", failures)

func _load_wave_defs(failures: Array[String]):
	if not FileAccess.file_exists(WAVE_DEFS_PATH):
		return null
	var file := FileAccess.open(WAVE_DEFS_PATH, FileAccess.READ)
	if file == null:
		failures.append("wave defs file should be readable")
		return null
	var content := file.get_as_text()
	var parsed: Variant = JSON.parse_string(content)
	if parsed == null:
		failures.append("wave defs should contain valid JSON")
		return null
	return parsed

func _assert_true(value: bool, message: String, failures: Array[String]) -> bool:
	if not value:
		failures.append(message)
	return value
