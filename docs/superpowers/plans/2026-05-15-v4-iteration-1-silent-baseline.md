# V4 Iteration 1 Silent Baseline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在不修改真实业务战斗判定逻辑的前提下，把 V4 作为幽灵观察者静默挂载到真实业务 battle 路径，稳定产出第一份真实业务 unified snapshot、trace payload 与 bridge 事件证据。

**Architecture:** 保持 `emit_v4_probe_event(event: Dictionary)` 作为唯一桥接 API，不再改动 V4 内部主流转，只在真实 battle scene 路径补最小挂载点与最小 contract。先锁住“挂载存在且不破坏业务”，再记录第一轮真实业务基线与下一阶段闭环入口。

**Tech Stack:** Godot 4 GDScript、battle controller、battle scene runtime、unified snapshot contracts、project test runner、Markdown docs。

---

## File structure

| 路径 | 角色 | 本计划用途 |
|---|---|---|
| `scripts/battle/battle_controller.gd` | battle runtime controller | 承载业务桥接 API 与 `business_probe_events` 输出 |
| `scripts/battle/battle_scene_runtime.gd` | 真实 battle scene 运行态入口 | 静默挂载业务 battle tick 到 V4 |
| `tests/battle/test_battle_controller_integration.gd` | controller 集成合同 | 锁住 bridge API 存在且能更新 trace payload |
| `tests/battle/test_battle_runtime_probe_trace_contract.gd` | trace payload contract | 锁住业务挂载后 payload 仍稳定可消费 |
| `tests/battle/test_battle_scene_runtime_binding.gd` | scene binding contract | 锁住真实 scene 路径会暴露 `business_probe_events` |
| `tests/battle/test_probe_sampling_payload_contract.gd` | critical payload contract | 锁住静默挂载不改变 unified snapshot 消费面 |
| `docs/v4_delivery_archive.md` | 交付档案 | 追加 Silent Integration milestone |
| `docs/v4_backlog_tiers.md` | backlog 分级 | 把下一步改成 baseline establishment / gate activation |

## Task 1: 锁住 bridge API 与 payload 输出

**Files:**
- Modify: `tests/battle/test_battle_controller_integration.gd`
- Modify: `scripts/battle/battle_controller.gd`
- Test: `tests/battle/test_battle_controller_integration.gd`

- [ ] **Step 1: 在 integration contract 中先写失败断言，锁住 `emit_v4_probe_event` 与 `business_probe_events`**

```gdscript
func _test_v4_probe_bridge_exists_and_updates_trace_payload(failures: Array[String]) -> void:
	var controller = BattleControllerScript.new(WAVE_DEFS_PATH)
	controller.start_run()
	_assert_true(controller.has_method("emit_v4_probe_event"), "battle controller should expose emit_v4_probe_event bridge", failures)
	controller.emit_v4_probe_event({"event_type": "integration_test", "state": controller.get_state()})
	var payload: Dictionary = controller.debug_get_runtime_trace_payload()
	_assert_true(payload.has("business_probe_events"), "battle controller runtime trace payload should expose business_probe_events", failures)
	var events: Array = payload.get("business_probe_events", [])
	_assert_true(events.size() == 1, "battle controller probe bridge should append one event", failures)
```

- [ ] **Step 2: 跑 smoke，确认先红且失败集中在 bridge 缺失**

Run: `"/c/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "/c/Users/admin/Documents/demo" -s res://tests/test_runner.gd -- --smoke`
Expected: FAIL，失败集中在 `emit_v4_probe_event` / `business_probe_events` 缺失

- [ ] **Step 3: 在 `battle_controller.gd` 写最小 bridge 实现与事件缓冲上限**

```gdscript
var _v4_business_probe_events: Array[Dictionary] = []

func emit_v4_probe_event(event: Dictionary) -> void:
	_v4_business_probe_events.append(event.duplicate(true))
	while _v4_business_probe_events.size() > 32:
		_v4_business_probe_events.pop_front()
```

- [ ] **Step 4: 把 `business_probe_events` 接入 `debug_get_runtime_trace_payload()`**

```gdscript
func debug_get_runtime_trace_payload() -> Dictionary:
	var probe_payload := _build_runtime_trace_payload()
	var nested_probe: Dictionary = probe_payload.get("probe", {})
	var output := probe_payload.duplicate(true)
	output["probe"] = nested_probe.duplicate(true)
	output["business_probe_events"] = _v4_business_probe_events.duplicate(true)
	output["warning_unified_snapshot"] = _read_warning_unified_snapshot_for_debug()
	output["critical_unified_snapshot"] = _read_critical_unified_snapshot_for_debug()
	for key in nested_probe.keys():
		output[key] = nested_probe[key]
	return output
```

- [ ] **Step 5: 重跑 smoke，确认 bridge 合同转绿**

Run: `"/c/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "/c/Users/admin/Documents/demo" -s res://tests/test_runner.gd -- --smoke`
Expected: `All 6 test suite(s) passed.`

- [ ] **Step 6: Commit**

```bash
git add scripts/battle/battle_controller.gd tests/battle/test_battle_controller_integration.gd
git commit -m "feat: add v4 business bridge buffer"
```

## Task 2: 在真实 battle scene 路径静默挂载业务事件

**Files:**
- Modify: `scripts/battle/battle_scene_runtime.gd`
- Modify: `tests/battle/test_battle_runtime_probe_trace_contract.gd`
- Modify: `tests/battle/test_battle_scene_runtime_binding.gd`
- Test: `tests/battle/test_battle_runtime_probe_trace_contract.gd`
- Test: `tests/battle/test_battle_scene_runtime_binding.gd`

- [ ] **Step 1: 在 trace contract 中先写失败断言，锁住 payload 会暴露 `business_probe_events`**

```gdscript
var trace_payload := {
	"probe": {"backend": "v4", "history_limit": 32, "samples": [], "movement_anomalies": [], "probe": {}},
	"business_probe_events": [{"event_type": "battle_scene_runtime_tick", "state": "combat"}],
	"warning_unified_snapshot": {...},
	"critical_unified_snapshot": {...}
}
_assert_trace_true(trace_payload.has("business_probe_events"), "runtime trace payload should expose business probe events", failures)
```

- [ ] **Step 2: 在 scene binding contract 中先写失败断言，锁住真实 scene 路径会暴露 `business_probe_events`**

```gdscript
var payload: Dictionary = controller.call("debug_get_runtime_trace_payload")
_assert_true(payload.has("business_probe_events"), "battle scene controller runtime trace payload should expose business_probe_events", failures)
```

- [ ] **Step 3: 在 `battle_scene_runtime.gd` 里静默挂载 battle tick 事件，不改变原业务判定**

```gdscript
if _controller.has_method("tick_combat"):
	_controller.call("tick_combat", delta)
if _controller.has_method("emit_v4_probe_event"):
	_controller.call("emit_v4_probe_event", {
		"event_type": "battle_scene_runtime_tick",
		"state": _controller.call("get_state")
	})
var state := str(_controller.call("get_state"))
```

- [ ] **Step 4: 重跑 smoke，确认静默挂载不破坏 scene/runtime path**

Run: `"/c/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "/c/Users/admin/Documents/demo" -s res://tests/test_runner.gd -- --smoke`
Expected: `All 6 test suite(s) passed.`

- [ ] **Step 5: Commit**

```bash
git add scripts/battle/battle_scene_runtime.gd tests/battle/test_battle_runtime_probe_trace_contract.gd tests/battle/test_battle_scene_runtime_binding.gd
git commit -m "feat: mount silent v4 events in battle scene"
```

## Task 3: 锁住静默挂载不污染 unified snapshot 消费面

**Files:**
- Modify: `tests/battle/test_probe_sampling_payload_contract.gd`
- Modify: `docs/v4_delivery_archive.md`
- Test: `tests/battle/test_probe_sampling_payload_contract.gd`
- Test: `tests/test_runner.gd`

- [ ] **Step 1: 在 payload contract 中先写失败断言，锁住 business mounting 不改变 critical unified family 与 gate_results**

```gdscript
_assert_true(str(unified_snapshot.get("family", "")) == "critical", "business mounting should not change critical unified family", failures)
_assert_true(unified_snapshot.has("gate_results"), "business mounting should not remove unified gate_results", failures)
```

- [ ] **Step 2: 在 delivery archive 中追加 Silent Integration milestone**

```md
| Project V4 Integration / Silent Integration | done | business path can emit V4 probe events without changing battle logic |
```

- [ ] **Step 3: 跑全量 runner，确认静默挂载没有破坏现有 artifact 合同**

Run: `"/c/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "/c/Users/admin/Documents/demo" -s res://tests/test_runner.gd`
Expected: `All 163 test suite(s) passed.`

- [ ] **Step 4: Commit**

```bash
git add tests/battle/test_probe_sampling_payload_contract.gd docs/v4_delivery_archive.md
git commit -m "test: preserve unified contracts under silent mounting"
```

## Task 4: 固化下一阶段基线与闭环入口

**Files:**
- Modify: `docs/v4_backlog_tiers.md`
- Modify: `docs/v4_delivery_archive.md`
- Test: `tests/test_runner.gd`

- [ ] **Step 1: 把 backlog P1 改成真实 baseline establishment 与 gate activation**

```md
## P1

| Item | Why it stays out of current slice |
|---|---|
| 基于真实业务数据建立 threshold baseline | 静默挂载已完成，下一步应进入真实数据基线拟合 |
| 让 `takeover_ready` 或相关 gate 反馈业务层 | 属于下一阶段闭环激活，不在本轮静默挂载内 |
```

- [ ] **Step 2: 在 delivery archive 中补 Next Step 段落**

```md
## Next Step
- Baseline establishment on real business traces
- Gate activation back into business battle logic
```

- [ ] **Step 3: 运行 smoke 与 full runner，作为 Iteration 1 最终验收**

Run: `"/c/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "/c/Users/admin/Documents/demo" -s res://tests/test_runner.gd -- --smoke`
Expected: `All 6 test suite(s) passed.`

Run: `"/c/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "/c/Users/admin/Documents/demo" -s res://tests/test_runner.gd`
Expected: `All 163 test suite(s) passed.`

- [ ] **Step 4: Commit**

```bash
git add docs/v4_backlog_tiers.md docs/v4_delivery_archive.md
git commit -m "docs: mark silent baseline integration milestone"
```

## Self-review

| 检查项 | 结果 |
|---|---|
| Spec coverage | 已覆盖 bridge API、真实 scene 静默挂载、基线 contract、下一阶段入口 |
| Placeholder scan | 无 TBD/TODO/“类似上一步”占位 |
| Type consistency | 全程统一使用 `emit_v4_probe_event`、`business_probe_events`、`warning_unified_snapshot`、`critical_unified_snapshot` |
| Scope check | 明确不做大规模结构整顿，不拆大脚本，只做静默挂载与基线入口 |
