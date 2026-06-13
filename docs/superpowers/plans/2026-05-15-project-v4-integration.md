# Project V4 Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在不先做大规模结构整顿的前提下，把 V4 探针与 unified snapshot 体系静默挂载到真实业务战斗逻辑，建立第一轮真实业务基线。

**Architecture:** 先做一层极薄的业务接入适配层，让业务代码只通过单一桥接 API 把运行时事件送入 V4；再让 battle runtime 在真实业务路径下产出 warning/critical unified snapshots 与 trace payload；最后补一组最小业务接入 contract，验证“挂载存在但不改变原业务逻辑”。本轮不拆大脚本，不重构 fixture 内部，只修接入边界。

**Tech Stack:** Godot 4 GDScript、battle runtime controller、V4 probe payload、unified snapshot contracts、JSON artifacts、project test runner。

---

## File structure

| 路径 | 角色 | 本计划用途 |
|---|---|---|
| `scripts/battle/battle_controller.gd` | authoritative battle runtime | 增加业务侧可调用的 V4 probe 接入桥接点 |
| `scripts/battle/` 下真实业务战斗入口脚本 | 真实业务驱动层 | 通过最小桥接 API 静默挂载 V4 事件 |
| `tests/battle/test_battle_controller_integration.gd` | battle controller 集成 contract | 锁住桥接 API 不改变现有 battle controller 主行为 |
| `tests/battle/test_battle_scene_runtime_binding.gd` | scene runtime contract | 验证真实 battle scene 路径能消费挂载后的统一 payload |
| `tests/battle/test_battle_runtime_probe_trace_contract.gd` | trace payload contract | 验证真实业务挂载后 trace payload 仍稳定 |
| `tests/battle/test_probe_critical_runtime_perturbation_contract.gd` | critical artifact contract | 验证真实业务路径不破坏已建立的 perturbation mirrors |
| `tests/battle/smoke_suite.json` | P0 smoke suites | 把业务接入后的核心回归护栏保持在最小可跑集合 |
| `docs/v4_delivery_archive.md` | 交付归档 | 追加真实业务接入里程碑与基线说明 |
| `docs/v4_backlog_tiers.md` | backlog 分级 | 追加“已完成静默挂载，下一步为基线建立/闭环反馈” |

## Task 1: 建立业务接入适配层的最小 API

**Files:**
- Modify: `scripts/battle/battle_controller.gd`
- Modify: `tests/battle/test_battle_controller_integration.gd`
- Test: `tests/battle/test_battle_controller_integration.gd`

- [ ] **Step 1: 在 integration test 中先写失败断言，锁住 battle controller 必须暴露单一桥接入口**

```gdscript
var controller = BattleController.new()
_assert_true(controller.has_method("emit_v4_probe_event"), "battle controller should expose emit_v4_probe_event bridge", failures)
```

- [ ] **Step 2: 运行相关测试，确认先红且失败集中在桥接方法不存在**

Run: `"/c/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "/c/Users/admin/Documents/demo" -s res://tests/test_runner.gd -- --smoke`
Expected: FAIL，失败点集中在 `emit_v4_probe_event` 缺失

- [ ] **Step 3: 在 `battle_controller.gd` 写最小桥接方法，只接受 Dictionary 并缓存到 debug payload**

```gdscript
var _v4_business_probe_events: Array[Dictionary] = []

func emit_v4_probe_event(event: Dictionary) -> void:
	_v4_business_probe_events.append(event.duplicate(true))
	while _v4_business_probe_events.size() > 32:
		_v4_business_probe_events.pop_front()
```

- [ ] **Step 4: 把桥接事件接入 `debug_get_runtime_trace_payload()` 的 `probe` 或并列 debug 字段**

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

- [ ] **Step 5: 运行 integration test 与 smoke，确认桥接 API 存在且不破坏现有 smoke**

Run: `"/c/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "/c/Users/admin/Documents/demo" -s res://tests/test_runner.gd -- --smoke`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add scripts/battle/battle_controller.gd tests/battle/test_battle_controller_integration.gd
git commit -m "feat: add v4 business probe bridge"
```

## Task 2: 在真实 battle scene 路径做静默挂载

**Files:**
- Modify: 真实业务战斗入口脚本（当前 battle scene 使用的 battle 驱动脚本）
- Modify: `tests/battle/test_battle_scene_runtime_binding.gd`
- Modify: `tests/battle/test_battle_runtime_probe_trace_contract.gd`
- Test: `tests/battle/test_battle_scene_runtime_binding.gd`
- Test: `tests/battle/test_battle_runtime_probe_trace_contract.gd`

- [ ] **Step 1: 在 scene runtime contract 中先写失败断言，锁住真实 scene 路径下 payload 会暴露 `business_probe_events`**

```gdscript
var payload: Dictionary = controller.call("debug_get_runtime_trace_payload")
_assert_true(payload.has("business_probe_events"), "battle scene controller runtime trace payload should expose business_probe_events", failures)
```

- [ ] **Step 2: 在真实业务战斗入口脚本里只做静默挂载，不改原有判定逻辑**

```gdscript
if battle_controller != null and battle_controller.has_method("emit_v4_probe_event"):
	battle_controller.call("emit_v4_probe_event", {
		"event_type": "battle_scene_runtime_tick",
		"state": battle_controller.call("get_state")
	})
```

- [ ] **Step 3: 在 trace contract 中补断言，锁住 trace payload 在挂载后仍保留 unified snapshots 与新增业务事件字段**

```gdscript
_assert_trace_true(trace_payload.has("business_probe_events"), "runtime trace payload should expose business probe events", failures)
_assert_trace_true(trace_payload.has("warning_unified_snapshot"), "runtime trace payload should still expose warning unified snapshot", failures)
_assert_trace_true(trace_payload.has("critical_unified_snapshot"), "runtime trace payload should still expose critical unified snapshot", failures)
```

- [ ] **Step 4: 运行相关测试，确认静默挂载不会破坏 scene/runtime path**

Run: `"/c/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "/c/Users/admin/Documents/demo" -s res://tests/test_runner.gd -- --smoke`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add <真实业务战斗入口脚本> tests/battle/test_battle_scene_runtime_binding.gd tests/battle/test_battle_runtime_probe_trace_contract.gd
git commit -m "feat: silently mount v4 probe in battle scene"
```

## Task 3: 建立真实业务基线的第一版 contract

**Files:**
- Modify: `tests/battle/test_probe_critical_runtime_perturbation_contract.gd`
- Modify: `tests/battle/test_probe_sampling_payload_contract.gd`
- Modify: `docs/v4_delivery_archive.md`
- Test: `tests/battle/test_probe_critical_runtime_perturbation_contract.gd`
- Test: `tests/battle/test_probe_sampling_payload_contract.gd`

- [ ] **Step 1: 在 perturbation contract 中新增失败断言，锁住真实业务挂载后 artifact 仍然保留现有 perturbation mirrors**

```gdscript
_assert_true(payload.has("perturbation_summary"), "critical artifact should still expose perturbation_summary after business mounting", failures)
_assert_true(gate_results.has("attack_rebind_escape_count"), "critical gate results should still expose attack_rebind_escape_count after business mounting", failures)
```

- [ ] **Step 2: 在 sampling payload contract 中补一条“业务事件挂载不污染统一消费面”的断言**

```gdscript
_assert_true(str(unified_snapshot.get("family", "")) == "critical", "business mounting should not change critical unified family", failures)
_assert_true(unified_snapshot.has("gate_results"), "business mounting should not remove unified gate_results", failures)
```

- [ ] **Step 3: 在 delivery archive 中追加真实业务静默挂载里程碑**

```md
| Project V4 Integration / Silent Integration | done | business path can emit V4 probe events without changing battle logic |
```

- [ ] **Step 4: 运行全量 runner，确认业务静默挂载没有破坏现有 artifact 合同**

Run: `"/c/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "/c/Users/admin/Documents/demo" -s res://tests/test_runner.gd`
Expected: `All 163 test suite(s) passed.` 或新增 suite 后全绿

- [ ] **Step 5: Commit**

```bash
git add tests/battle/test_probe_critical_runtime_perturbation_contract.gd tests/battle/test_probe_sampling_payload_contract.gd docs/v4_delivery_archive.md
git commit -m "test: preserve v4 contracts under business mounting"
```

## Task 4: 固化下一阶段基线与后续闭环入口

**Files:**
- Modify: `docs/v4_backlog_tiers.md`
- Modify: `docs/v4_delivery_archive.md`
- Test: `tests/test_runner.gd`

- [ ] **Step 1: 在 backlog tiers 中把“静默挂载完成”移出 backlog，并把下一步改成基线建立/闭环反馈**

```md
## P1

| Item | Why it stays out of current slice |
|---|---|
| 基于真实业务数据建立 threshold baseline | 静默挂载已完成，下一步应进入真实数据基线拟合 |
| 让 `takeover_ready` 或相关 gate 反馈业务层 | 属于下一阶段闭环激活，不在本轮静默挂载内 |
```

- [ ] **Step 2: 在 delivery archive 中增加下一阶段说明**

```md
## Next Step
- Baseline establishment on real business traces
- Gate activation back into business battle logic
```

- [ ] **Step 3: 运行 smoke 与 full runner，作为 Project-V4-Integration 第一阶段最终验收**

Run: `"/c/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "/c/Users/admin/Documents/demo" -s res://tests/test_runner.gd -- --smoke`
Expected: PASS

Run: `"/c/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "/c/Users/admin/Documents/demo" -s res://tests/test_runner.gd`
Expected: `All 163 test suite(s) passed.` 或新增 suite 后全绿

- [ ] **Step 4: Commit**

```bash
git add docs/v4_backlog_tiers.md docs/v4_delivery_archive.md
git commit -m "docs: mark silent v4 business integration milestone"
```

## Self-review

| 检查项 | 结果 |
|---|---|
| Spec coverage | 已覆盖业务接入适配层、真实 scene 静默挂载、真实业务基线第一版 contract、后续闭环入口 |
| Placeholder scan | 仅保留一个待实现的真实业务入口脚本占位，需要在执行前先定位当前 battle scene 实际驱动脚本 |
| Type consistency | 全程统一使用 `emit_v4_probe_event`、`business_probe_events`、`warning_unified_snapshot`、`critical_unified_snapshot` |
| Scope check | 明确不做大规模结构整顿，不做大脚本内部重构，只做真实业务接入边界 |
