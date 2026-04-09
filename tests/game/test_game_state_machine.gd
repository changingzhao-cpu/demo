extends RefCounted

const GameStateMachineScript = preload("res://scripts/game/game_state_machine.gd")

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_initial_state_is_init(failures)
	_test_start_run_transitions_to_combat(failures)
	_test_wave_victory_transitions_to_reward_and_back(failures)
	_test_defeat_transitions_to_settle(failures)
	return failures

func _test_initial_state_is_init(failures: Array[String]) -> void:
	var machine = GameStateMachineScript.new()
	_assert_eq(machine.get_state(), machine.STATE_INIT, "initial state should be init", failures)

func _test_start_run_transitions_to_combat(failures: Array[String]) -> void:
	var machine = GameStateMachineScript.new()
	machine.start_run()
	_assert_eq(machine.get_state(), machine.STATE_COMBAT, "start_run should transition to combat", failures)

func _test_wave_victory_transitions_to_reward_and_back(failures: Array[String]) -> void:
	var machine = GameStateMachineScript.new()
	machine.start_run()
	machine.on_wave_cleared()
	_assert_eq(machine.get_state(), machine.STATE_REWARD, "wave clear should transition to reward", failures)
	machine.finish_reward()
	_assert_eq(machine.get_state(), machine.STATE_COMBAT, "finish_reward should return to combat", failures)

func _test_defeat_transitions_to_settle(failures: Array[String]) -> void:
	var machine = GameStateMachineScript.new()
	machine.start_run()
	machine.on_run_failed()
	_assert_eq(machine.get_state(), machine.STATE_SETTLE, "run failure should transition to settle", failures)

func _assert_eq(actual, expected, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s (expected=%s, actual=%s)" % [message, str(expected), str(actual)])
