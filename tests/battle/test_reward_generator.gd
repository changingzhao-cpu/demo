extends RefCounted

const RewardGeneratorScript = preload("res://scripts/battle/reward_generator.gd")
const RELIC_DEFS_PATH := "res://data/relic_defs.json"

func run() -> Array[String]:
	var failures: Array[String] = []
	_test_generate_choices_returns_three_unique_rewards(failures)
	_test_matching_tags_raise_reward_score(failures)
	_test_generate_choices_mixes_growth_categories(failures)
	return failures

func _test_generate_choices_returns_three_unique_rewards(failures: Array[String]) -> void:
	var generator = RewardGeneratorScript.new(RELIC_DEFS_PATH)
	var rewards: Array = generator.generate_choices(["melee"], 3)
	_assert_eq(rewards.size(), 3, "reward generator should return exactly three choices", failures)
	var ids := {}
	for reward in rewards:
		if not _assert_true(reward is Dictionary, "reward choice should be a Dictionary", failures):
			continue
		var reward_id := str(reward.get("id", ""))
		_assert_true(reward_id != "", "reward choice should include an id", failures)
		_assert_false(ids.has(reward_id), "reward choices should be unique", failures)
		ids[reward_id] = true

func _test_matching_tags_raise_reward_score(failures: Array[String]) -> void:
	var generator = RewardGeneratorScript.new(RELIC_DEFS_PATH)
	var scored: Array = generator.score_rewards(["caster"])
	var manual_score := _score_for_id(scored, "meteor_manual")
	var oath_score := _score_for_id(scored, "blood_oath")
	_assert_true(manual_score > oath_score, "matching team tags should give higher reward scores", failures)

func _test_generate_choices_mixes_growth_categories(failures: Array[String]) -> void:
	var generator = RewardGeneratorScript.new(RELIC_DEFS_PATH)
	var rewards: Array = generator.generate_choices(["melee", "caster", "support"], 3)
	var categories := {}
	for reward in rewards:
		if reward is Dictionary:
			categories[str(reward.get("category", ""))] = true
	_assert_true(categories.size() >= 2, "reward choices should mix at least two growth categories when possible", failures)

func _score_for_id(scored: Array, reward_id: String) -> float:
	for entry in scored:
		if entry is Dictionary and str(entry.get("id", "")) == reward_id:
			return float(entry.get("score", 0.0))
	return 0.0

func _assert_true(value: bool, message: String, failures: Array[String]) -> bool:
	if not value:
		failures.append(message)
	return value

func _assert_false(value: bool, message: String, failures: Array[String]) -> void:
	if value:
		failures.append(message)

func _assert_eq(actual, expected, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s (expected=%s, actual=%s)" % [message, str(expected), str(actual)])
