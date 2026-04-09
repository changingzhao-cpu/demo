extends RefCounted
class_name RewardGenerator

var _relic_defs_path: String
var _reward_defs: Array = []

func _init(relic_defs_path: String) -> void:
	_relic_defs_path = relic_defs_path
	_reward_defs = _load_reward_defs()

func generate_choices(team_tags: Array, choice_count: int = 3) -> Array:
	var scored: Array = score_rewards(team_tags)
	var remaining: Array = scored.duplicate(true)
	var categories_seen := {}
	var selections: Array = []
	var desired_count: int = min(choice_count, remaining.size())

	while selections.size() < desired_count and not remaining.is_empty():
		var next_index := _find_next_index(remaining, categories_seen, desired_count - selections.size())
		var reward: Dictionary = remaining[next_index]
		selections.append(reward)
		categories_seen[reward.get("category", "")] = true
		remaining.remove_at(next_index)

	return selections

func score_rewards(team_tags: Array) -> Array:
	var tag_lookup := {}
	for tag in team_tags:
		tag_lookup[str(tag)] = true

	var scored: Array = []
	for reward in _reward_defs:
		if not reward is Dictionary:
			continue
		var reward_copy: Dictionary = reward.duplicate(true)
		reward_copy["score"] = _score_reward(reward_copy, tag_lookup)
		scored.append(reward_copy)

	scored.sort_custom(_sort_rewards_desc)
	return scored

func _score_reward(reward: Dictionary, tag_lookup: Dictionary) -> float:
	var score: float = float(reward.get("weight", 0.0))
	var reward_tags: Array = reward.get("tags", [])
	for tag in reward_tags:
		if tag_lookup.has(str(tag)):
			score += 1.0
	return score

func _find_next_index(remaining: Array, categories_seen: Dictionary, slots_left: int) -> int:
	for index in range(remaining.size()):
		var category := str(remaining[index].get("category", ""))
		if not categories_seen.has(category):
			return index
	if slots_left <= 0:
		return 0
	return 0

func _load_reward_defs() -> Array:
	if not FileAccess.file_exists(_relic_defs_path):
		return []
	var file := FileAccess.open(_relic_defs_path, FileAccess.READ)
	if file == null:
		return []
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Array:
		return parsed
	return []

static func _sort_rewards_desc(left: Dictionary, right: Dictionary) -> bool:
	var left_score: float = float(left.get("score", 0.0))
	var right_score: float = float(right.get("score", 0.0))
	if left_score == right_score:
		return str(left.get("id", "")) < str(right.get("id", ""))
	return left_score > right_score
