# Stage 2 Real-Issue Interpretation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 拿到第一个“V4 能解释真实业务毛刺/拥挤点”的成功案例，把真实业务问题与 V4 指标建立可复用映射。

**Architecture:** 继续以真实业务接入主线推进，不做结构整顿。先锁住“解释毛刺所需证据字段必须持续存在”，再在基线文档中固定一份“业务问题 → 指标映射”的记录模板，最后把首个解释案例沉淀进 delivery archive 与 backlog 口径。

**Tech Stack:** Godot 4 GDScript、battle scene runtime、unified snapshots、project test runner、Markdown docs。

---

## File structure

| 路径 | 角色 | 本计划用途 |
|---|---|---|
| `tests/battle/test_probe_sampling_payload_contract.gd` | critical payload contract | 锁住解释毛刺必需的 unified gate 字段继续存在 |
| `tests/battle/test_probe_critical_runtime_perturbation_contract.gd` | perturbation contract | 锁住 `perturbation_summary` 与解释依赖字段继续存在 |
| `tests/battle/test_battle_runtime_probe_trace_contract.gd` | trace contract | 锁住业务事件字段仍能支撑问题解释 |
| `tests/battle/test_battle_scene_runtime_binding.gd` | scene binding contract | 锁住真实业务路径仍暴露 baseline 解释字段 |
| `docs/v4_real_business_baseline.md` | 基线文档 | 增加“问题映射模板”与首个解释案例位置 |
| `docs/v4_delivery_archive.md` | 交付档案 | 追加 Stage 2 解释里程碑 |
| `docs/v4_backlog_tiers.md` | backlog 分级 | 把“首个解释案例”列为当前 P1 主目标 |

## Task 1: 锁住解释毛刺所需证据字段

**Files:**
- Modify: `tests/battle/test_probe_sampling_payload_contract.gd`
- Modify: `tests/battle/test_probe_critical_runtime_perturbation_contract.gd`
- Test: `tests/battle/test_probe_sampling_payload_contract.gd`
- Test: `tests/battle/test_probe_critical_runtime_perturbation_contract.gd`

- [ ] **Step 1: 在 payload contract 中先写失败断言，锁住解释毛刺必需字段继续存在**

```gdscript
_assert_true(unified_gate_results.has("attack_rebind_escape_count"), "real issue interpretation should preserve attack_rebind_escape_count", failures)
_assert_true(unified_gate_results.has("attack_rebind_recontact_count"), "real issue interpretation should preserve attack_rebind_recontact_count", failures)
_assert_true(unified_gate_results.has("attack_midband_drift_count"), "real issue interpretation should preserve attack_midband_drift_count", failures)
_assert_true(unified_gate_results.has("critical_hit_rate"), "real issue interpretation should preserve critical_hit_rate", failures)
_assert_true(unified_gate_results.has("fast_false_positive_rate"), "real issue interpretation should preserve fast_false_positive_rate", failures)
```

- [ ] **Step 2: 在 perturbation contract 中先写失败断言，锁住 `perturbation_summary` 持续可读**

```gdscript
_assert_true(payload.has("perturbation_summary"), "real issue interpretation should still preserve perturbation_summary", failures)
_assert_true(payload.get("perturbation_summary", {}).has("attack_rebind_escape_count"), "real issue interpretation should preserve perturbation escape count in perturbation_summary", failures)
```

- [ ] **Step 3: 运行 full runner，确认先红时失败集中在解释字段断言**

Run: `"/c/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "/c/Users/admin/Documents/demo" -s res://tests/test_runner.gd`
Expected: FAIL，且失败集中在新增解释字段断言

- [ ] **Step 4: 写最小实现或调整断言到当前真实字段口径，然后重跑 full runner**

Run: `"/c/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "/c/Users/admin/Documents/demo" -s res://tests/test_runner.gd`
Expected: `All 163 test suite(s) passed.`

- [ ] **Step 5: Commit**

```bash
git add tests/battle/test_probe_sampling_payload_contract.gd tests/battle/test_probe_critical_runtime_perturbation_contract.gd
git commit -m "test: preserve evidence fields for real issue interpretation"
```

## Task 2: 固定“业务问题 -> 指标映射”模板

**Files:**
- Modify: `docs/v4_real_business_baseline.md`
- Test: `tests/test_runner.gd`

- [ ] **Step 1: 在 baseline 文档中增加问题映射模板**

```md
## Issue Interpretation Template

| Item | Fill-in |
|---|---|
| Business issue name | |
| Observable symptom | |
| Triggering scene/wave | |
| V4 signal(s) | |
| Why the signal explains the issue | |
| Follow-up action | |
```

- [ ] **Step 2: 增加首个案例占位结构，但不伪造结论**

```md
## First Interpretation Case

| Item | Current status |
|---|---|
| Business issue name | pending real case |
| Observable symptom | pending real case |
| Triggering scene/wave | pending real case |
| V4 signal(s) | pending real case |
| Why the signal explains the issue | pending real case |
| Follow-up action | pending real case |
```

- [ ] **Step 3: 跑 smoke，确认文档更新不影响护栏**

Run: `"/c/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "/c/Users/admin/Documents/demo" -s res://tests/test_runner.gd -- --smoke`
Expected: `All 6 test suite(s) passed.`

- [ ] **Step 4: Commit**

```bash
git add docs/v4_real_business_baseline.md
git commit -m "docs: add real issue interpretation template"
```

## Task 3: 把 Stage 2 目标写进交付与优先级文档

**Files:**
- Modify: `docs/v4_delivery_archive.md`
- Modify: `docs/v4_backlog_tiers.md`
- Test: `tests/test_runner.gd`

- [ ] **Step 1: 在 delivery archive 中增加 Stage 2 里程碑段**

```md
## Phase C / Real-Issue Interpretation
- Goal: explain at least one known business stall, clumping point, or arbitration hotspot with V4 signals.
- Current requirement: keep all interpretation evidence fields stable under smoke and full runner.
```

- [ ] **Step 2: 在 backlog tiers 中把“首个解释案例”明确列成当前 P1 主目标**

```md
## Active next phase
- Phase C / Real-Issue Interpretation
- Goal: land the first business issue explanation case with V4 signals
```

- [ ] **Step 3: 运行 smoke 与 full runner，确认文档口径更新不影响现有回归**

Run: `"/c/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "/c/Users/admin/Documents/demo" -s res://tests/test_runner.gd -- --smoke`
Expected: `All 6 test suite(s) passed.`

Run: `"/c/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "/c/Users/admin/Documents/demo" -s res://tests/test_runner.gd`
Expected: `All 163 test suite(s) passed.`

- [ ] **Step 4: Commit**

```bash
git add docs/v4_delivery_archive.md docs/v4_backlog_tiers.md
git commit -m "docs: promote real issue interpretation as next milestone"
```

## Task 4: 为 Stage 3 / Degradative Feedback 做边界准备

**Files:**
- Modify: `docs/v4_backlog_tiers.md`
- Modify: `docs/v4_delivery_archive.md`
- Modify: `docs/v4_real_business_baseline.md`
- Test: `tests/test_runner.gd`

- [ ] **Step 1: 在 backlog tiers 中补一条“解释成功后才允许降级式反馈”**

```md
## Rule
- Degradative feedback may begin only after at least one real business issue has been explained by V4 signals.
```

- [ ] **Step 2: 在 delivery archive 中补一条反馈前提**

```md
## Feedback Entry Condition
- first prove one real issue explanation case
- then activate degradative feedback
- do not jump directly to authoritative takeover
```

- [ ] **Step 3: 在 baseline 文档中补“解释成功 -> 才进入 feedback”的顺序说明**

```md
## Progression rule
- Silent baseline first
- Real issue interpretation second
- Degradative feedback third
```

- [ ] **Step 4: 运行 smoke 与 full runner，作为 Stage 2 计划最终验收**

Run: `"/c/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "/c/Users/admin/Documents/demo" -s res://tests/test_runner.gd -- --smoke`
Expected: `All 6 test suite(s) passed.`

Run: `"/c/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "/c/Users/admin/Documents/demo" -s res://tests/test_runner.gd`
Expected: `All 163 test suite(s) passed.`

- [ ] **Step 5: Commit**

```bash
git add docs/v4_backlog_tiers.md docs/v4_delivery_archive.md docs/v4_real_business_baseline.md
git commit -m "docs: define transition from interpretation to feedback"
```

## Self-review

| 检查项 | 结果 |
|---|---|
| Spec coverage | 已覆盖解释字段护栏、问题映射模板、Stage 2 里程碑、向 Stage 3 的过渡边界 |
| Placeholder scan | 无 TBD/TODO/“类似上一步”占位；首个案例位置用 `pending real case` 明示真实数据待填 |
| Type consistency | 全程统一使用 `attack_rebind_escape_count`、`attack_rebind_recontact_count`、`attack_midband_drift_count`、`critical_hit_rate`、`fast_false_positive_rate` |
| Scope check | 聚焦真实业务毛刺解释，不回头做无压力结构整顿 |
