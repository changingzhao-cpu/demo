extends RefCounted

const WaveControllerScript = preload("res://scripts/battle/wave_controller.gd")
const WAVE_DEFS_PATH := "res://data/wave_defs.json"

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_start_wave_uses_first_wave_definition(failures)
	_test_complete_wave_advances_index_and_flags_reward(failures)
	_test_last_wave_completion_sets_finished(failures)
	return failures

func _test_start_wave_uses_first_wave_definition(failures: Array[String]) -> void:
	var controller = WaveControllerScript.new(WAVE_DEFS_PATH)
	var wave: Dictionary = controller.start_run()
	_assert_eq(controller.current_wave_index(), 0, "start_run should begin at wave index 0", failures)
	_assert_eq(int(wave.get("wave", -1)), 1, "start_run should return wave 1", failures)
	_assert_false(controller.is_finished(), "controller should not be finished at start", failures)
	_assert_false(controller.is_reward_pending(), "reward should not be pending at run start", failures)

func _test_complete_wave_advances_index_and_flags_reward(failures: Array[String]) -> void:
	var controller = WaveControllerScript.new(WAVE_DEFS_PATH)
	controller.start_run()
	controller.complete_current_wave(true)
	_assert_true(controller.is_reward_pending(), "winning a wave should enter reward state", failures)
	var next_wave: Dictionary = controller.advance_after_reward()
	_assert_eq(controller.current_wave_index(), 1, "advance_after_reward should move to next wave", failures)
	_assert_eq(int(next_wave.get("wave", -1)), 2, "advance_after_reward should return wave 2", failures)
	_assert_false(controller.is_reward_pending(), "reward flag should clear after advancing", failures)

func _test_last_wave_completion_sets_finished(failures: Array[String]) -> void:
	var controller = WaveControllerScript.new(WAVE_DEFS_PATH)
	controller.start_run()
	for _i in range(11):
		controller.complete_current_wave(true)
		controller.advance_after_reward()
	controller.complete_current_wave(true)
	_assert_true(controller.is_finished(), "controller should finish after final wave victory", failures)
	_assert_false(controller.has_next_wave(), "controller should have no next wave after final victory", failures)

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)

func _assert_false(value: bool, message: String, failures: Array[String]) -> void:
	if value:
		failures.append(message)

func _assert_eq(actual, expected, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s (expected=%s, actual=%s)" % [message, str(expected), str(actual)])
