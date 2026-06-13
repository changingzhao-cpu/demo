# V4 Business Integration Follow-up Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在停止继续整结构的前提下，直接推进 V4 真实业务接入，先完成真实业务 baseline 建立，再进入闭环反馈准备。

**Architecture:** 继续沿用已建立的 `emit_v4_probe_event` / `business_probe_events` 桥接层，不再扩散到大规模结构整顿。先让真实业务路径稳定产出可解释的 unified snapshot 基线，再把一组真实业务毛刺映射到 V4 指标，最后只做“降级式反馈”的最小闭环入口，不直接篡改核心业务逻辑。

**Tech Stack:** Godot 4 GDScript、battle controller、battle scene runtime、unified snapshots、project test runner、Markdown docs。

---

## File structure

| 路径 | 角色 | 本计划用途 |
|---|---|---|
| `scripts/battle/battle_scene_runtime.gd` | 真实 battle scene runtime | 扩充静默挂载字段，产出更有解释力的真实业务事件 |
| `scripts/battle/battle_controller.gd` | battle runtime controller | 维持 bridge API，补最小基线缓存/读取接口 |
| `tests/battle/test_battle_scene_runtime_binding.gd` | scene binding contract | 锁住真实业务路径事件字段与统一消费面 |
| `tests/battle/test_battle_runtime_probe_trace_contract.gd` | trace payload contract | 锁住真实业务基线事件结构 |
| `tests/battle/test_probe_sampling_payload_contract.gd` | critical payload contract | 锁住真实业务接入不污染 unified snapshot |
| `tests/battle/test_probe_critical_runtime_perturbation_contract.gd` | perturbation contract | 锁住 perturbation mirrors 继续成立 |
| `docs/v4_delivery_archive.md` | 交付档案 | 记录真实业务 baseline 与解释案例 |
| `docs/v4_backlog_tiers.md` | backlog 分级 | 更新下一阶段从 baseline 进入 gate feedback 的优先级 |
| `docs/v4_real_business_baseline.md` | 新建业务基线文档 | 记录第一版真实业务 unified snapshot 观测结论 |

## Task 1: 扩充真实业务 baseline 事件字段

**Files:**
- Modify: `scripts/battle/battle_scene_runtime.gd`
- Modify: `tests/battle/test_battle_scene_runtime_binding.gd`
- Modify: `tests/battle/test_battle_runtime_probe_trace_contract.gd`
- Test: `tests/battle/test_battle_scene_runtime_binding.gd`
- Test: `tests/battle/test_battle_runtime_probe_trace_contract.gd`

- [ ] **Step 1: 在 trace contract 中先写失败断言，锁住业务事件至少带 `event_type/state/wave/live_count/combat_event_count`**

```gdscript
var business_probe_events: Array = trace_payload.get("business_probe_events", [])
_assert_trace_true(business_probe_events.size() > 0, "runtime trace payload should expose at least one business probe event", failures)
var first_event: Dictionary = business_probe_events[0]
_assert_trace_true(first_event.has("event_type"), "business probe event should expose event_type", failures)
_assert_trace_true(first_event.has("state"), "business probe event should expose state", failures)
_assert_trace_true(first_event.has("wave"), "business probe event should expose wave", failures)
_assert_trace_true(first_event.has("live_count"), "business probe event should expose live_count", failures)
_assert_trace_true(first_event.has("combat_event_count"), "business probe event should expose combat_event_count", failures)
```

- [ ] **Step 2: 运行 smoke，确认先红且失败集中在业务事件字段不足**

Run: `"/c/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "/c/Users/admin/Documents/demo" -s res://tests/test_runner.gd -- --smoke`
Expected: FAIL，失败点集中在 `business_probe_events` 缺字段

- [ ] **Step 3: 在 `battle_scene_runtime.gd` 的静默挂载里补齐业务字段，但不改 battle 判定**

```gdscript
if _controller.has_method("emit_v4_probe_event"):
	var report: Dictionary = _controller.call("get_last_tick_report") if _controller.has_method("get_last_tick_report") else {}
	var current_wave: Dictionary = _controller.call("get_current_wave") if _controller.has_method("get_current_wave") else {}
	_controller.call("emit_v4_probe_event", {
		"event_type": "battle_scene_runtime_tick",
		"state": _controller.call("get_state"),
		"wave": int(current_wave.get("wave", -1)),
		"live_count": int(report.get("live_count", 0)),
		"combat_event_count": int(report.get("combat_event_count", 0))
	})
```

- [ ] **Step 4: 在 scene binding contract 中补最小断言，锁住真实 scene 路径也能读到这些字段**

```gdscript
var events: Array = payload.get("business_probe_events", [])
_assert_true(events.size() > 0, "battle scene controller runtime trace payload should expose business probe events", failures)
var first_event: Dictionary = events[0]
_assert_true(first_event.has("wave"), "battle scene controller runtime trace payload should expose wave in business probe event", failures)
_assert_true(first_event.has("live_count"), "battle scene controller runtime trace payload should expose live_count in business probe event", failures)
_assert_true(first_event.has("combat_event_count"), "battle scene controller runtime trace payload should expose combat_event_count in business probe event", failures)
```

- [ ] **Step 5: 重跑 smoke，确认真实业务 baseline 事件结构转绿**

Run: `"/c/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "/c/Users/admin/Documents/demo" -s res://tests/test_runner.gd -- --smoke`
Expected: `All 6 test suite(s) passed.`

- [ ] **Step 6: Commit**

```bash
git add scripts/battle/battle_scene_runtime.gd tests/battle/test_battle_scene_runtime_binding.gd tests/battle/test_battle_runtime_probe_trace_contract.gd
git commit -m "feat: enrich silent business baseline events"
```

## Task 2: 固化第一版真实业务 baseline 文档

**Files:**
- Create: `docs/v4_real_business_baseline.md`
- Modify: `docs/v4_delivery_archive.md`
- Test: `tests/test_runner.gd`

- [ ] **Step 1: 写 baseline 文档，记录第一版真实业务观测口径**

```md
# V4 Real Business Baseline

## Event shape

| Field | Meaning |
|---|---|
| `event_type` | 业务 battle tick 事件类型 |
| `state` | 当前 battle state |
| `wave` | 当前波次 |
| `live_count` | 当前单位数量 |
| `combat_event_count` | 当前战斗事件总数 |

## Baseline intent
- 先建立“业务在什么状态下，V4 看到了什么”
- 不在本轮直接做 gate 接管
```

- [ ] **Step 2: 在 delivery archive 中增加真实业务 baseline 里程碑引用**

```md
## Real Business Baseline
- See `docs/v4_real_business_baseline.md`
- Silent business events now expose wave/live_count/combat_event_count for baseline establishment
```

- [ ] **Step 3: 跑全量 runner，确认文档补充不影响代码路径**

Run: `"/c/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "/c/Users/admin/Documents/demo" -s res://tests/test_runner.gd`
Expected: `All 163 test suite(s) passed.`

- [ ] **Step 4: Commit**

```bash
git add docs/v4_real_business_baseline.md docs/v4_delivery_archive.md
git commit -m "docs: record first real business baseline"
```

## Task 3: 建立“解释真实毛刺”的入口 contract

**Files:**
- Modify: `tests/battle/test_probe_sampling_payload_contract.gd`
- Modify: `tests/battle/test_probe_critical_runtime_perturbation_contract.gd`
- Modify: `docs/v4_backlog_tiers.md`
- Test: `tests/battle/test_probe_sampling_payload_contract.gd`
- Test: `tests/battle/test_probe_critical_runtime_perturbation_contract.gd`

- [ ] **Step 1: 在 payload contract 中先写失败断言，锁住静默基线阶段仍保留足够解释毛刺的字段**

```gdscript
_assert_true(unified_gate_results.has("attack_rebind_escape_count"), "silent baseline should still preserve attack_rebind_escape_count for future business interpretation", failures)
_assert_true(unified_gate_results.has("attack_rebind_recontact_count"), "silent baseline should still preserve attack_rebind_recontact_count for future business interpretation", failures)
_assert_true(unified_gate_results.has("attack_midband_drift_count"), "silent baseline should still preserve attack_midband_drift_count for future business interpretation", failures)
```

- [ ] **Step 2: 在 perturbation contract 中补一条“下一阶段解释依赖字段仍存在”的断言**

```gdscript
_assert_true(payload.has("perturbation_summary"), "real business baseline should still preserve perturbation_summary for later interpretation", failures)
```

- [ ] **Step 3: 在 backlog tiers 中把下一步明确写成“解释真实毛刺”而不是泛化优化**

```md
## P1

| Item | Why it stays out of current slice |
|---|---|
| 用 V4 数据解释真实业务中的已知毛刺/拥挤点 | Baseline 已建立，下一步应进入真实问题解释 |
| 让 `takeover_ready` 或相关 gate 反馈业务层 | 解释阶段完成后进入闭环激活 |
```

- [ ] **Step 4: 运行 full runner，确认解释入口 contract 全绿**

Run: `"/c/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "/c/Users/admin/Documents/demo" -s res://tests/test_runner.gd`
Expected: `All 163 test suite(s) passed.`

- [ ] **Step 5: Commit**

```bash
git add tests/battle/test_probe_sampling_payload_contract.gd tests/battle/test_probe_critical_runtime_perturbation_contract.gd docs/v4_backlog_tiers.md
git commit -m "test: preserve interpretation hooks for business baseline"
```

## Task 4: 为闭环反馈准备最小设计边界

**Files:**
- Modify: `docs/v4_backlog_tiers.md`
- Modify: `docs/v4_delivery_archive.md`
- Test: `tests/test_runner.gd`

- [ ] **Step 1: 在 backlog tiers 中把闭环反馈明确为“降级式接管”而非“毁灭式阻断”**

```md
## P1

| Item | Why it stays out of current slice |
|---|---|
| 降级式 gate feedback | 当 V4 报 Warning/Critical 时，优先做特效削减、AI 精度放宽、负载节流，而不是粗暴阻断战斗逻辑 |
```

- [ ] **Step 2: 在 delivery archive 中记录后续反馈原则**

```md
## Gate Feedback Principle
- V4 should first behave as a silent observer.
- Feedback must be degradative before it becomes authoritative.
```

- [ ] **Step 3: 运行 smoke 与 full runner，作为本轮 follow-up 最终验收**

Run: `"/c/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "/c/Users/admin/Documents/demo" -s res://tests/test_runner.gd -- --smoke`
Expected: `All 6 test suite(s) passed.`

Run: `"/c/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "/c/Users/admin/Documents/demo" -s res://tests/test_runner.gd`
Expected: `All 163 test suite(s) passed.`

- [ ] **Step 4: Commit**

```bash
git add docs/v4_backlog_tiers.md docs/v4_delivery_archive.md
git commit -m "docs: define degradative gate feedback direction"
```

## Self-review

| 检查项 | 结果 |
|---|---|
| Spec coverage | 已覆盖 baseline 事件扩充、真实业务 baseline 文档、毛刺解释入口、闭环反馈边界 |
| Placeholder scan | 无 TBD/TODO/“类似上一步”占位 |
| Type consistency | 统一使用 `business_probe_events`、`wave`、`live_count`、`combat_event_count`、`takeover_ready` |
| Scope check | 明确不继续整结构，直接服务于真实业务接入主线 |
