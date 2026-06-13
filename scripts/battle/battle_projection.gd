extends RefCounted
class_name BattleProjection

func build_authoritative_contract(entities: Array) -> Dictionary:
	return {"ticksource": "battle_simulation_v3", "entities": entities}

func build_runtime_projection(entities: Array) -> Dictionary:
	return {"source": "authoritative_battle_contract", "entities": entities}

func build_probe_snapshot(entities: Array) -> Dictionary:
	return {"source": "battle_runtime_probe", "entities": entities}
