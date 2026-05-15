# Test Entry Conventions

## Runner suite
- Base: `extends RefCounted`
- Required API: `func run() -> Array[String]`
- Called by: `res://tests/test_runner.gd`
- Rule: must not await long-lived `SceneTree` fixture lifecycle

## Direct fixture
- Base: `extends SceneTree`
- Called by: direct `Godot --headless --path ... -s res://...`
- Rule: may refresh artifacts or emit probe files, but is not registered as a runner suite

## Source contract
- Base: `extends RefCounted`
- Rule: validates source/schema/static contract only, without orchestrating runtime fixture execution

## Project examples

| 类型 | 文件 | 用途 |
|---|---|---|
| Runner suite | `tests/battle/test_probe_takeover_gate_contract.gd` | 校验 critical takeover gate |
| Direct fixture | `tests/battle/test_battle_runtime_probe_contact_oscillation.gd` | 刷新 critical runtime artifact |
| Source contract | `tests/battle/test_runtime_probe_oscillation_fingerprint_contract.gd` | 校验 oscillation 源码/指纹合同 |
