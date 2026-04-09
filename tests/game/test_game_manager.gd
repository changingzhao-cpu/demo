extends RefCounted

const GameManagerScript = preload("res://scripts/game/game_manager.gd")
const WAVE_DEFS_PATH := "res://data/wave_defs.json"

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_start_run_initializes_state_and_wave(failures)
	_test_handle_wave_clear_moves_to_reward(failures)
	_test_claim_reward_advances_to_next_wave(failures)
	return failures

func _test_start_run_initializes_state_and_wave(failures: Array[String]) -> void:
	var manager = GameManagerScript.new(WAVE_DEFS_PATH)
	var wave: Dictionary = manager.start_run()
	_assert_eq(manager.get_state(), "combat", "start_run should enter combat state", failures)
	_assert_eq(int(wave.get("wave", -1)), 1, "start_run should initialize wave 1", failures)

func _test_handle_wave_clear_moves_to_reward(failures: Array[String]) -> void:
	var manager = GameManagerScript.new(WAVE_DEFS_PATH)
	manager.start_run()
	manager.handle_wave_clear()
	_assert_eq(manager.get_state(), "reward", "wave clear should enter reward state", failures)

func _test_claim_reward_advances_to_next_wave(failures: Array[String]) -> void:
	var manager = GameManagerScript.new(WAVE_DEFS_PATH)
	manager.start_run()
	manager.handle_wave_clear()
	var next_wave: Dictionary = manager.claim_reward_and_advance()
	_assert_eq(manager.get_state(), "combat", "claim_reward_and_advance should return to combat", failures)
	_assert_eq(int(next_wave.get("wave", -1)), 2, "claim_reward_and_advance should advance to wave 2", failures)

func _assert_eq(actual, expected, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s (expected=%s, actual=%s)" % [message, str(expected), str(actual)])
