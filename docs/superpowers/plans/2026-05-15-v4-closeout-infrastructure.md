# V4 Closeout Infrastructure Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为 V4 当前阶段建立可交付的收口基础设施，包括最小 smoke 回归、runner 入口规范、交付归档、backlog 分级。

**Architecture:** 先在 `test_runner.gd` 之上加一层最小 smoke 入口，不碰已有 suite 内部大逻辑；再补一份入口约定文档，明确 `RefCounted suite` / `SceneTree fixture` / `source contract` 的边界；最后把阶段知识和后续优先级沉淀成两份文档，形成可持续维护的交付闭环。

**Tech Stack:** Godot 4 GDScript、JSON suite config、project test runner、Markdown docs。

---

## File structure

| 路径 | 角色 | 本计划用途 |
|---|---|---|
| `tests/test_runner.gd` | 全量测试入口 | 增加 smoke 模式入口与最小配置读取逻辑 |
| `tests/battle/smoke_suite.json` | 新建 smoke 配置 | 声明 P0 级 smoke suites 列表 |
| `tests/battle/test_probe_critical_runtime_perturbation_contract.gd` | Critical P0 contract | 继续作为 smoke 关键件之一 |
| `tests/battle/test_probe_takeover_gate_contract.gd` | takeover contract | 继续作为 smoke 关键件之一 |
| `tests/battle/test_probe_sampling_payload_contract.gd` | payload contract | 继续作为 smoke 关键件之一 |
| `tests/battle/test_battle_runtime_probe_trace_contract.gd` | runtime trace contract | 继续作为 smoke 关键件之一 |
| `tests/battle/test_battle_scene_runtime_binding.gd` | scene binding contract | 继续作为 smoke 关键件之一 |
| `docs/test_entry_conventions.md` | 新建入口规范文档 | 记录 suite / fixture / source contract 约定 |
| `docs/v4_delivery_archive.md` | 新建交付归档文档 | 记录阶段成果、指标物理内涵、验收边界 |
| `docs/v4_backlog_tiers.md` | 新建 backlog 分级文档 | 明确 P1/P2 后续事项 |
| `docs/v4_readiness_map.md` | 已有 readiness 图 | 必要时补链接或引用收口文档 |

## Task 1: 建立 smoke baseline 入口

**Files:**
- Create: `tests/battle/smoke_suite.json`
- Modify: `tests/test_runner.gd`
- Test: `tests/test_runner.gd`

- [ ] **Step 1: 新建 failing smoke 配置文件，明确 P0 suite 列表**

```json
[
  "battle/test_warning_readiness_snapshot_contract",
  "battle/test_probe_sampling_payload_contract",
  "battle/test_probe_takeover_gate_contract",
  "battle/test_probe_critical_runtime_perturbation_contract",
  "battle/test_battle_runtime_probe_trace_contract",
  "battle/test_battle_scene_runtime_binding"
]
```

- [ ] **Step 2: 在 `test_runner.gd` 中先写失败读取逻辑，支持 `--smoke` 参数切换**

```gdscript
const SMOKE_SUITE_CONFIG_PATH := "res://tests/battle/smoke_suite.json"

func _should_run_smoke_only() -> bool:
	for arg in OS.get_cmdline_user_args():
		if arg == "--smoke":
			return true
	return false

func _load_smoke_suite_names() -> Dictionary:
	var text := FileAccess.get_file_as_string(SMOKE_SUITE_CONFIG_PATH)
	if text == "":
		return {}
	var parsed: Variant = JSON.parse_string(text)
	if not parsed is Array:
		return {}
	var names := {}
	for item in parsed:
		names[str(item)] = true
	return names
```

- [ ] **Step 3: 在 suite 构建链中只保留 smoke 名单，先让 `--smoke` 路径红灯**

```gdscript
func _filtered_suites() -> Array:
	var suites := TEST_SUITES
	if not _should_run_smoke_only():
		return suites
	var allowed := _load_smoke_suite_names()
	var filtered: Array = []
	for suite in suites:
		if allowed.has(str(suite.get("name", ""))):
			filtered.append(suite)
	return filtered
```

```gdscript
for suite in _filtered_suites():
	_run_suite(suite)
```

- [ ] **Step 4: 运行 smoke 模式，确认它先失败在 smoke 配置/过滤链，而不是全量逻辑**

Run: `"/c/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "/c/Users/admin/Documents/demo" -s res://tests/test_runner.gd -- --smoke`
Expected: FAIL，失败集中在 smoke 配置或 smoke 过滤实现未完成

- [ ] **Step 5: 写最小实现并重跑 smoke**

```gdscript
func _filtered_suites() -> Array:
	if not _should_run_smoke_only():
		return TEST_SUITES
	var allowed := _load_smoke_suite_names()
	if allowed.is_empty():
		return []
	var filtered: Array = []
	for suite in TEST_SUITES:
		if allowed.has(str(suite.get("name", ""))):
			filtered.append(suite)
	return filtered
```

Run: `"/c/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "/c/Users/admin/Documents/demo" -s res://tests/test_runner.gd -- --smoke`
Expected: PASS，且只执行 smoke suites

- [ ] **Step 6: 跑全量 runner，确认 smoke 入口没有破坏全量路径**

Run: `"/c/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "/c/Users/admin/Documents/demo" -s res://tests/test_runner.gd`
Expected: `All 163 test suite(s) passed.`

- [ ] **Step 7: Commit**

```bash
git add tests/battle/smoke_suite.json tests/test_runner.gd
git commit -m "feat: add v4 smoke suite entrypoint"
```

## Task 2: 固化 runner 入口规范

**Files:**
- Create: `docs/test_entry_conventions.md`
- Test: `tests/test_runner.gd`

- [ ] **Step 1: 写入口规范文档，明确三类入口边界**

```md
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
```

- [ ] **Step 2: 在文档中补一个本项目真实案例表**

```md
| 类型 | 文件 | 用途 |
|---|---|---|
| Runner suite | `tests/battle/test_probe_takeover_gate_contract.gd` | 校验 critical takeover gate |
| Direct fixture | `tests/battle/test_battle_runtime_probe_contact_oscillation.gd` | 刷新 critical runtime artifact |
| Source contract | `tests/battle/test_runtime_probe_oscillation_fingerprint_contract.gd` | 校验 oscillation 源码/指纹合同 |
```

- [ ] **Step 3: 跑 smoke，确认新增文档没有引入 runner 误改**

Run: `"/c/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "/c/Users/admin/Documents/demo" -s res://tests/test_runner.gd -- --smoke`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add docs/test_entry_conventions.md
git commit -m "docs: define test entry conventions"
```

## Task 3: 沉淀交付归档

**Files:**
- Create: `docs/v4_delivery_archive.md`
- Modify: `docs/v4_readiness_map.md`
- Test: `tests/test_runner.gd`

- [ ] **Step 1: 写归档文档头部，固定阶段时间线与阶段成果**

```md
# V4 Delivery Archive

## Milestone Timeline

| Phase | Status | Notes |
|---|---|---|
| Warning truth-hardening Phase 1-3 | done | warning unified snapshot stabilized |
| Critical truth-hardening Phase 1 | done | fitted thresholds / payload mirrors stabilized |
| Fast-track exit | done | runtime trace unified snapshots exposed |
| Critical runtime perturbation hardening | done | anomaly_scan and perturbation_summary mirrored into critical gate results |
```

- [ ] **Step 2: 写 artifact contract map，固定 warning/critical/runtime 三条消费面**

```md
## Artifact Contract Map

| Surface | Required fields |
|---|---|
| Warning unified snapshot | `family`, `confidence_score`, `thresholds`, `support_counts`, `blockers`, `gate_results` |
| Critical unified snapshot | `family`, `confidence_score`, `thresholds`, `support_counts`, `blockers`, `gate_results`, `attack_rebind_escape_count` mirrors |
| Runtime trace payload | `probe`, `warning_unified_snapshot`, `critical_unified_snapshot` |
```

- [ ] **Step 3: 写指标物理内涵章节，至少覆盖 7 个核心指标**

```md
## Metric Physics

| Metric | Physical meaning |
|---|---|
| `contention_index` | 接敌/分配阶段的拥挤与冲突压力近似量 |
| `claim_success_rate` | 单位稳定占据预期接敌/分配结果的成功率 |
| `late_commit_deviation` | 后提交造成的状态偏差，用于识别“结果晚到”不稳定 |
| `old_escape_hit` | 历史 escape 异常是否在新采样中重现 |
| `attack_rebind_escape_count` | 攻击态重绑后再次逃出稳定接敌窗口的次数 |
| `attack_rebind_recontact_count` | 逃出后重新回到稳定接敌窗口的次数 |
| `attack_midband_drift_count` | 攻击中带内的不合理漂移次数 |
```

- [ ] **Step 4: 在 readiness map 中补充对 archive/backlog 文档的引用**

```md
# V4 Readiness Map

See also:
- `docs/v4_delivery_archive.md`
- `docs/v4_backlog_tiers.md`
```

- [ ] **Step 5: 跑全量 runner，确认文档补充没有影响代码路径**

Run: `"/c/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "/c/Users/admin/Documents/demo" -s res://tests/test_runner.gd`
Expected: `All 163 test suite(s) passed.`

- [ ] **Step 6: Commit**

```bash
git add docs/v4_delivery_archive.md docs/v4_readiness_map.md
git commit -m "docs: archive v4 delivery semantics"
```

## Task 4: 完成 backlog 分级并做最终收口验证

**Files:**
- Create: `docs/v4_backlog_tiers.md`
- Test: `tests/test_runner.gd`

- [ ] **Step 1: 写 backlog 分级文档，冻结 P1/P2 边界**

```md
# V4 Backlog Tiers

## P1

| Item | Why it stays out of closeout |
|---|---|
| V4 接入真实业务战斗逻辑 | 下一阶段主线，但不属于本轮收口基础设施 |

## P2

| Item | Why deferred |
|---|---|
| 大脚本拆分 | 当前收益低于交付收口收益 |
| runner 内部进一步重构 | 当前只修入口，不动内部 |
| Critical 精度继续提升 | 当前 contract 已可交付 |
| 20 resources / DummyTexture 尾项继续排查 | 已 accepted，不阻断交付 |
```

- [ ] **Step 2: 在文档尾部补一条执行纪律**

```md
## Rule

- Closeout phase must not accept new feature logic.
- Any new work must be classified into P1 or P2 before implementation begins.
```

- [ ] **Step 3: 运行 smoke，确认日常保险栓可用**

Run: `"/c/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "/c/Users/admin/Documents/demo" -s res://tests/test_runner.gd -- --smoke`
Expected: PASS

- [ ] **Step 4: 运行 fresh full runner，作为本轮 closeout infrastructure 最终验收**

Run: `"/c/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "/c/Users/admin/Documents/demo" -s res://tests/test_runner.gd`
Expected: `All 163 test suite(s) passed.`

- [ ] **Step 5: Commit**

```bash
git add docs/v4_backlog_tiers.md
git commit -m "docs: tier v4 closeout backlog"
```

## Self-review

| 检查项 | 结果 |
|---|---|
| Spec coverage | 已覆盖 smoke baseline、runner entry normalization、delivery archive、backlog triage 四个包 |
| Placeholder scan | 无 TBD/TODO/“类似上一步”占位 |
| Type consistency | 全程统一使用 `--smoke`、`smoke_suite.json`、`test entry conventions`、`delivery archive`、`backlog tiers` |
| Scope check | 没有扩展到新业务 feature、真实业务接入实现或大脚本内部重构 |
