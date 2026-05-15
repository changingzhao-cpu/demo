# Critical Runtime Perturbation Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为 Critical runtime perturbation hardening 建立一条可验证、可交付的真实 runtime 证据链，把 backlog 中“显式延期”的物理扰动问题收束成稳定 contract 与最小实现。

**Architecture:** 继续沿用现有 probe-first 路线，不直接大改战斗主循环。先把 `test_battle_runtime_probe_contact_oscillation.gd` 中混杂的“采样、扫描、阈值、产物写出”责任拆成可组合 helper，再新增专门的 perturbation contract 锁住 attack/contact 漂移与 rebind 物理异常，最后把结论回灌到 unified snapshot/readiness map，形成一致消费面。

**Tech Stack:** Godot 4 GDScript、battle runtime probe、critical sampling artifact、JSON contracts、project test runner。

---

## File structure

| 路径 | 角色 | 本计划用途 |
|---|---|---|
| `tests/battle/test_battle_runtime_probe_contact_oscillation.gd` | Critical runtime 真实采样主脚本 | 拆分 perturbation 采样/扫描/产物构建逻辑，减少单文件耦合 |
| `tests/battle/test_runtime_probe_oscillation_fingerprint_contract.gd` | oscillation 指纹 contract | 补充 perturbation 指纹字段与基线顺序约束 |
| `tests/battle/test_probe_critical_payload_enrichment_contract.gd` | critical payload contract | 锁住 unified snapshot / artifact 对 perturbation 汇总字段的暴露 |
| `tests/battle/test_probe_takeover_gate_contract.gd` | takeover gate contract | 确保 perturbation hardening 不破坏 fast-track takeover 对齐 |
| `tests/battle/test_battle_runtime_probe_trace_contract.gd` | runtime trace consumer contract | 确保 trace payload 继续消费 unified snapshot，不被 perturbation 新字段打破 |
| `tests/battle/test_battle_scene_runtime_binding.gd` | battle scene runtime contract | 确保 scene 路径能继续消费 hardening 后的 runtime payload |
| `docs/v4_readiness_map.md` | 交付文档 | 把 Critical runtime perturbation hardening 从 backlog 更新为真实状态 |
| `tests/test_runner.gd` | 全量验证入口 | 最终 `162/162 PASS` 及新增 suite 验收 |

## Task 1: 先把 perturbation 目标收束成独立 contract

**Files:**
- Create: `tests/battle/test_probe_critical_runtime_perturbation_contract.gd`
- Modify: `tests/test_runner.gd`
- Test: `tests/battle/test_probe_critical_runtime_perturbation_contract.gd`

- [ ] **Step 1: 写失败 contract，锁住 oscillation 产物必须暴露 perturbation 汇总字段**

```gdscript
extends RefCounted

const ARTIFACT_PATH := "user://critical_sampling.json"

func run() -> Array[String]:
	var failures: Array[String] = []
	var text := FileAccess.get_file_as_string(ARTIFACT_PATH)
	_assert_true(text != "", "critical sampling artifact should exist before perturbation contract checks", failures)
	if text == "":
		return failures
	var json := JSON.new()
	var parse_result := json.parse(text)
	_assert_true(parse_result == OK, "critical sampling artifact should parse as json for perturbation contract checks", failures)
	if parse_result != OK:
		return failures
	var payload: Dictionary = json.data
	var unified_snapshot: Dictionary = payload.get("unified_snapshot", {})
	var gate_results: Dictionary = unified_snapshot.get("gate_results", {})
	_assert_true(payload.has("anomaly_scan"), "critical artifact should expose anomaly_scan for perturbation hardening", failures)
	_assert_true(gate_results.has("takeover_ready"), "critical gate results should still expose takeover_ready during perturbation hardening", failures)
	_assert_true(typeof(payload.get("anomaly_scan", null)) == TYPE_DICTIONARY, "critical anomaly_scan should remain a dictionary", failures)
	_assert_true(payload.get("anomaly_scan", {}).has("attack_rebind_escape_count"), "critical anomaly_scan should expose attack_rebind_escape_count", failures)
	_assert_true(payload.get("anomaly_scan", {}).has("attack_rebind_recontact_count"), "critical anomaly_scan should expose attack_rebind_recontact_count", failures)
	_assert_true(payload.get("anomaly_scan", {}).has("attack_midband_drift_count"), "critical anomaly_scan should expose attack_midband_drift_count", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
```

- [ ] **Step 2: 把新 contract 加入 runner，先制造红灯**

```gdscript
{"name": "battle/test_probe_critical_runtime_perturbation_contract", "path": "res://tests/battle/test_probe_critical_runtime_perturbation_contract.gd"},
```

- [ ] **Step 3: 运行单测确认它先红，而且只因为 artifact 尚未暴露 perturbation 汇总字段**

Run: `"/c/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "/c/Users/admin/Documents/demo" -s res://tests/test_runner.gd`
Expected: FAIL，且失败信息集中在 `anomaly_scan` / `attack_rebind_*` 新断言

- [ ] **Step 4: Commit**

```bash
git add tests/battle/test_probe_critical_runtime_perturbation_contract.gd tests/test_runner.gd
git commit -m "test: add critical runtime perturbation contract"
```

## Task 2: 先把 oscillation fixture 接入可执行链

**Files:**
- Modify: `tests/battle/test_probe_critical_runtime_perturbation_contract.gd`
- Modify: `tests/test_runner.gd`
- Test: `tests/battle/test_probe_critical_runtime_perturbation_contract.gd`

- [ ] **Step 1: 让 perturbation contract 在断言前主动执行 oscillation fixture，刷新 `user://critical_sampling.json`**

```gdscript
const OSCILLATION_SCRIPT := preload("res://tests/battle/test_battle_runtime_probe_contact_oscillation.gd")

func run() -> Array[String]:
	var fixture := OSCILLATION_SCRIPT.new()
	await fixture.run()
	var failures: Array[String] = []
	var text := FileAccess.get_file_as_string(ARTIFACT_PATH)
```

- [ ] **Step 2: 如果 fixture 返回 failures，先把 fixture failures 原样透传，再做 artifact 断言**

```gdscript
var fixture_failures: Array[String] = await fixture.run()
for failure in fixture_failures:
	failures.append("oscillation fixture: %s" % failure)
if not fixture_failures.is_empty():
	return failures
```

- [ ] **Step 3: 运行 full runner，确认红灯从“artifact 未刷新”前进到真实 perturbation 字段缺失**

Run: `"/c/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "/c/Users/admin/Documents/demo" -s res://tests/test_runner.gd`
Expected: FAIL，但 `critical_sampling.json` 已被 fixture 刷新，失败点聚焦在未落地的 perturbation 字段镜像

- [ ] **Step 4: Commit**

```bash
git add tests/battle/test_probe_critical_runtime_perturbation_contract.gd tests/test_runner.gd
git commit -m "test: execute oscillation fixture in perturbation contract"
```

## Task 3: 把 oscillation 主脚本拆成可验证的 perturbation 构建链

**Files:**
- Modify: `tests/battle/test_battle_runtime_probe_contact_oscillation.gd`
- Test: `tests/battle/test_probe_critical_runtime_perturbation_contract.gd`
- Test: `tests/battle/test_runtime_probe_oscillation_fingerprint_contract.gd`

- [ ] **Step 1: 先写最小 helper，把 anomaly scan 从 `run()` 中抽成独立 artifact builder 入口**

```gdscript
func _build_critical_perturbation_summary(trajectories: Dictionary, battle_report_timeline: Array) -> Dictionary:
	var anomaly_scan := _build_anomaly_scan(trajectories, battle_report_timeline)
	return {
		"attack_rebind_escape_count": int(anomaly_scan.get("attack_rebind_escape_count", 0)),
		"attack_rebind_recontact_count": int(anomaly_scan.get("attack_rebind_recontact_count", 0)),
		"attack_midband_drift_count": int(anomaly_scan.get("attack_midband_drift_count", 0)),
		"position_jump_count": int(anomaly_scan.get("position_jump_count", 0)),
		"spiral_drift_count": int(anomaly_scan.get("spiral_drift_count", 0)),
		"high_frequency_jitter_count": int(anomaly_scan.get("high_frequency_jitter_count", 0))
	}
```

- [ ] **Step 2: 让 critical artifact 根 payload 显式持有 `anomaly_scan` 与 `perturbation_summary`**

```gdscript
var anomaly_scan := _build_anomaly_scan(trajectories, battle_report_timeline)
var perturbation_summary := _build_critical_perturbation_summary(trajectories, battle_report_timeline)
var payload := {
	"sample_name": "oscillation",
	"samples": samples,
	"trajectories": trajectories,
	"battle_report_timeline": battle_report_timeline,
	"anomaly_scan": anomaly_scan,
	"perturbation_summary": perturbation_summary,
	"fitted_thresholds": fitted_thresholds,
	"probe_contract_snapshot": probe_contract_snapshot,
	"unified_snapshot": unified_snapshot
}
```

- [ ] **Step 3: 让 `unified_snapshot.gate_results` 镜像最小 perturbation 指标，但不改变现有 takeover 判定口径**

```gdscript
func _build_critical_perturbation_summary(trajectories: Dictionary, battle_report_timeline: Array) -> Dictionary:
	var anomaly_scan := _build_anomaly_scan(trajectories, battle_report_timeline)
	return {
		"attack_rebind_escape_count": int(anomaly_scan.get("attack_rebind_escape_count", 0)),
		"attack_rebind_recontact_count": int(anomaly_scan.get("attack_rebind_recontact_count", 0)),
		"attack_midband_drift_count": int(anomaly_scan.get("attack_midband_drift_count", 0)),
		"position_jump_count": int(anomaly_scan.get("position_jump_count", 0)),
		"spiral_drift_count": int(anomaly_scan.get("spiral_drift_count", 0)),
		"high_frequency_jitter_count": int(anomaly_scan.get("high_frequency_jitter_count", 0))
	}
```

- [ ] **Step 2: 让 critical artifact 根 payload 显式持有 `anomaly_scan` 与 `perturbation_summary`**

```gdscript
var anomaly_scan := _build_anomaly_scan(trajectories, battle_report_timeline)
var perturbation_summary := _build_critical_perturbation_summary(trajectories, battle_report_timeline)
var payload := {
	"sample_name": "oscillation",
	"samples": samples,
	"trajectories": trajectories,
	"battle_report_timeline": battle_report_timeline,
	"anomaly_scan": anomaly_scan,
	"perturbation_summary": perturbation_summary,
	"fitted_thresholds": fitted_thresholds,
	"probe_contract_snapshot": probe_contract_snapshot,
	"unified_snapshot": unified_snapshot
}
```

- [ ] **Step 3: 让 `unified_snapshot.gate_results` 镜像最小 perturbation 指标，但不改变现有 takeover 判定口径**

```gdscript
var gate_results := {
	"gate_a_critical_hit_rate": _compute_gate_a_critical_hit_rate(family_samples),
	"gate_b_fast_false_positive_rate": _compute_gate_b_fast_false_positive_rate(family_samples),
	"gate_c_no_false_positive_records": _compute_gate_c_no_false_positive_records(family_samples),
	"takeover_ready": _compute_gate_c_no_false_positive_records(family_samples),
	"sample_count": 20,
	"critical_hit_rate": _compute_gate_a_critical_hit_rate(family_samples),
	"fast_false_positive_rate": _compute_gate_b_fast_false_positive_rate(family_samples),
	"attack_rebind_escape_count": int(perturbation_summary.get("attack_rebind_escape_count", 0)),
	"attack_rebind_recontact_count": int(perturbation_summary.get("attack_rebind_recontact_count", 0)),
	"attack_midband_drift_count": int(perturbation_summary.get("attack_midband_drift_count", 0)),
	"takeover_blockers": [] if _compute_gate_c_no_false_positive_records(family_samples) else ["false_positive_records"]
}
```

- [ ] **Step 4: 运行全量测试，确认 perturbation contract 转绿且旧 fast-track 合同不回退**

Run: `"/c/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "/c/Users/admin/Documents/demo" -s res://tests/test_runner.gd`
Expected: PASS，`test_probe_critical_runtime_perturbation_contract` / `test_probe_takeover_gate_contract` / `test_probe_sampling_payload_contract` 全绿

- [ ] **Step 5: Commit**

```bash
git add tests/battle/test_battle_runtime_probe_contact_oscillation.gd
git commit -m "feat: expose critical runtime perturbation summary"
```

## Task 3: 锁住 perturbation fingerprint 与 unified payload 消费面

**Files:**
- Modify: `tests/battle/test_runtime_probe_oscillation_fingerprint_contract.gd`
- Modify: `tests/battle/test_probe_critical_payload_enrichment_contract.gd`
- Modify: `tests/battle/test_probe_takeover_gate_contract.gd`
- Test: `tests/battle/test_runtime_probe_oscillation_fingerprint_contract.gd`
- Test: `tests/battle/test_probe_critical_payload_enrichment_contract.gd`
- Test: `tests/battle/test_probe_takeover_gate_contract.gd`

- [ ] **Step 1: 在 fingerprint contract 中先写失败断言，锁住 oscillation 指纹包含 perturbation 汇总字段**

```gdscript
_assert_true(source.contains('"attack_rebind_escape_count"'), "oscillation fingerprint should expose attack_rebind_escape_count", failures)
_assert_true(source.contains('"attack_rebind_recontact_count"'), "oscillation fingerprint should expose attack_rebind_recontact_count", failures)
_assert_true(source.contains('"attack_midband_drift_count"'), "oscillation fingerprint should expose attack_midband_drift_count", failures)
```

- [ ] **Step 2: 在 critical payload enrichment contract 中锁住 payload 与 unified gate 的镜像关系**

```gdscript
var payload: Dictionary = json.data
var perturbation_summary: Dictionary = payload.get("perturbation_summary", {})
var unified_snapshot: Dictionary = payload.get("unified_snapshot", {})
var gate_results: Dictionary = unified_snapshot.get("gate_results", {})
_assert_true(int(perturbation_summary.get("attack_rebind_escape_count", -1)) == int(gate_results.get("attack_rebind_escape_count", -2)), "critical perturbation summary should mirror unified gate attack_rebind_escape_count", failures)
_assert_true(int(perturbation_summary.get("attack_rebind_recontact_count", -1)) == int(gate_results.get("attack_rebind_recontact_count", -2)), "critical perturbation summary should mirror unified gate attack_rebind_recontact_count", failures)
_assert_true(int(perturbation_summary.get("attack_midband_drift_count", -1)) == int(gate_results.get("attack_midband_drift_count", -2)), "critical perturbation summary should mirror unified gate attack_midband_drift_count", failures)
```

- [ ] **Step 3: 在 takeover gate contract 中锁住 perturbation 新字段不会破坏旧门禁语义**

```gdscript
_assert_true(gate_results.has("attack_rebind_escape_count"), "critical unified gate results should expose perturbation escape count", failures)
_assert_true(gate_results.has("attack_rebind_recontact_count"), "critical unified gate results should expose perturbation recontact count", failures)
_assert_true(gate_results.has("attack_midband_drift_count"), "critical unified gate results should expose perturbation midband drift count", failures)
_assert_true(bool(unified_snapshot.get("takeover_ready", false)) == bool(gate_results.get("takeover_ready", false)), "critical unified snapshot should still mirror takeover_ready after perturbation hardening", failures)
```

- [ ] **Step 4: 运行全量测试，确认 payload/fingerprint/takeover 三组 contract 一起转绿**

Run: `"/c/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "/c/Users/admin/Documents/demo" -s res://tests/test_runner.gd`
Expected: PASS，且新增 perturbation 字段不会打破旧 probe 合同

- [ ] **Step 5: Commit**

```bash
git add tests/battle/test_runtime_probe_oscillation_fingerprint_contract.gd tests/battle/test_probe_critical_payload_enrichment_contract.gd tests/battle/test_probe_takeover_gate_contract.gd
git commit -m "test: lock critical perturbation fingerprint and payload mirrors"
```

## Task 4: 更新运行时消费面与交付文档

**Files:**
- Modify: `tests/battle/test_battle_runtime_probe_trace_contract.gd`
- Modify: `tests/battle/test_battle_scene_runtime_binding.gd`
- Modify: `docs/v4_readiness_map.md`
- Test: `tests/battle/test_battle_runtime_probe_trace_contract.gd`
- Test: `tests/battle/test_battle_scene_runtime_binding.gd`
- Test: `tests/test_runner.gd`

- [ ] **Step 1: 在 runtime trace contract 中增加最小断言，锁住 unified snapshot 继续可消费 perturbation 指标**

```gdscript
var critical_unified_snapshot: Dictionary = trace_payload.get("critical_unified_snapshot", {})
var critical_gate_results: Dictionary = critical_unified_snapshot.get("gate_results", {})
_assert_trace_true(critical_gate_results.has("attack_rebind_escape_count"), "runtime trace payload should expose critical perturbation escape count through unified snapshot", failures)
_assert_trace_true(critical_gate_results.has("attack_rebind_recontact_count"), "runtime trace payload should expose critical perturbation recontact count through unified snapshot", failures)
_assert_trace_true(critical_gate_results.has("attack_midband_drift_count"), "runtime trace payload should expose critical perturbation midband drift count through unified snapshot", failures)
```

- [ ] **Step 2: 在 battle scene runtime contract 中增加控制器路径断言，锁住 scene 也能读到 perturbation 指标**

```gdscript
var payload: Dictionary = controller.call("debug_get_runtime_trace_payload")
var critical_unified_snapshot: Dictionary = payload.get("critical_unified_snapshot", {})
var critical_gate_results: Dictionary = critical_unified_snapshot.get("gate_results", {})
_assert_true(critical_gate_results.has("attack_rebind_escape_count"), "battle scene controller runtime trace payload should expose perturbation escape count", failures)
_assert_true(critical_gate_results.has("attack_rebind_recontact_count"), "battle scene controller runtime trace payload should expose perturbation recontact count", failures)
_assert_true(critical_gate_results.has("attack_midband_drift_count"), "battle scene controller runtime trace payload should expose perturbation midband drift count", failures)
```

- [ ] **Step 3: 更新 readiness map，把 backlog 状态改为已硬化并注明交付口径**

```md
# V4 Readiness Map

| Area | Status | Notes |
|---|---|---|
| Warning artifact | real-sampled | truth-hardening through Phase 3 |
| Critical artifact | real-sampled | fast-track hardened through Phase 2 |
| Runtime trace payload | unified | warning/critical unified snapshots exposed |
| Critical runtime perturbation hardening | real-sampled | oscillation anomaly_scan and perturbation_summary mirrored into critical unified gate results |
| Known tail | accepted | `1 DummyTexture + 20 resources still in use` treated as known runtime tail |
```

- [ ] **Step 4: 运行 fresh full runner，作为 perturbation hardening 最终交付证据**

Run: `"/c/Users/admin/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path "/c/Users/admin/Documents/demo" -s res://tests/test_runner.gd`
Expected: `All 162 test suite(s) passed.`（如果 suite 数新增，则以新增后全绿为准）

- [ ] **Step 5: Commit**

```bash
git add tests/battle/test_battle_runtime_probe_trace_contract.gd tests/battle/test_battle_scene_runtime_binding.gd docs/v4_readiness_map.md
git commit -m "docs: promote critical perturbation hardening readiness"
```

## Self-review

| 检查项 | 结果 |
|---|---|
| Spec coverage | 已覆盖 backlog 中唯一明确未完成项：Critical runtime perturbation hardening |
| Placeholder scan | 无 TBD/TODO/“类似上一步”占位 |
| Type consistency | 全程统一使用 `anomaly_scan`、`perturbation_summary`、`attack_rebind_escape_count`、`attack_rebind_recontact_count`、`attack_midband_drift_count` |
| Scope check | 未扩展到无关子系统；仅围绕 Critical runtime perturbation 证据链、contract、readiness map 收口 |
