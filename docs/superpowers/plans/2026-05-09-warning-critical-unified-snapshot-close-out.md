# Warning Critical Unified Snapshot Close-Out Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 建立 Warning / Critical 统一 snapshot 消费面，让 Warning `readiness_snapshot` 与 Critical `probe_contract_snapshot` 共享同一组核心字段语义，并用产物级 contract 锁住。

**Architecture:** 先保留两族现有采样与阈值拟合逻辑，只在各自产物层补一个最小公共 snapshot schema。然后把 contract 从“源码里出现了 key”迁移到“JSON/运行产物字段与语义一致”，最后让下游测试消费统一 snapshot，而不是继续耦合历史命名。

**Tech Stack:** Godot 4 GDScript、battle runtime probe fixtures、JSON artifact contracts、project test runner.

---

## Context
当前 Warning 侧已经在 [test_battle_runtime_probe_medium_density_filled_slots.gd](../../tests/battle/test_battle_runtime_probe_medium_density_filled_slots.gd) 中稳定产出 `readiness_snapshot`、`fitted_thresholds`、`gate_results` 与 `scenario_summaries`，并由 [test_warning_readiness_snapshot_contract.gd](../../tests/battle/test_warning_readiness_snapshot_contract.gd) 和 [test_warning_sampling_artifact_content_contract.gd](../../tests/battle/test_warning_sampling_artifact_content_contract.gd) 做内容级验证。

Critical 侧在 [test_battle_runtime_probe_contact_oscillation.gd](../../tests/battle/test_battle_runtime_probe_contact_oscillation.gd#L588-L608) 产出 `probe_contract_snapshot`，字段包含 `warning_threshold_value`、`error_threshold_value`、`old_escape_true_count` 与嵌套 `gate_results`，但现有 contract 主要仍是源码字符串锚定，例如 [test_probe_fitted_threshold_contract.gd](../../tests/battle/test_probe_fitted_threshold_contract.gd)、[test_probe_takeover_gate_contract.gd](../../tests/battle/test_probe_takeover_gate_contract.gd)、[test_probe_sampling_payload_contract.gd](../../tests/battle/test_probe_sampling_payload_contract.gd)。

下一步不该再扩单族字段，而是把两族都收敛到一个统一 snapshot 消费面。这样下游只需先读统一 snapshot，就能拿到 family、thresholds、gate 结论、sample 规模、关键计数与 blockers；只有在需要深挖时才再读族特有 payload。

## File structure

| 路径 | 角色 | 计划用途 |
|---|---|---|
| `tests/battle/test_battle_runtime_probe_medium_density_filled_slots.gd` | Warning 真采样产物源 | 补 unified snapshot，复用现有 `readiness_snapshot` / `fitted_thresholds` / `gate_results` |
| `tests/battle/test_battle_runtime_probe_contact_oscillation.gd` | Critical 真采样产物源 | 补 unified snapshot，基于现有 `probe_contract_snapshot` 对齐公共字段 |
| `tests/battle/test_warning_readiness_snapshot_contract.gd` | Warning snapshot contract | 迁移为验证 Warning unified snapshot 与现有 fitted/gate/sampling 镜像 |
| `tests/battle/test_warning_sampling_artifact_content_contract.gd` | Warning 内容级 contract | 保留现有数值关系，并补 unified snapshot 存在性与语义镜像 |
| `tests/battle/test_probe_sampling_payload_contract.gd` | family payload presence contract | 从源码 key 锚定升级为 unified snapshot presence/schema contract |
| `tests/battle/test_probe_fitted_threshold_contract.gd` | Critical fitted threshold contract | 改为验证 Critical unified snapshot 与 `fitted_thresholds` 镜像一致 |
| `tests/battle/test_probe_takeover_gate_contract.gd` | Critical gate contract | 改为验证 Critical unified snapshot 中 `takeover_ready` / blockers / gate_results 一致 |
| `tests/battle/test_runner.gd` | suite 注册入口 | 若新增 unified snapshot contract 文件，需要接入 runner |

## Unified snapshot schema
统一 snapshot 只包含最小公共消费面，避免复制全量 payload：

| 字段 | Warning 来源 | Critical 来源 | 说明 |
|---|---|---|---|
| `family` | `readiness_snapshot.family` | 新增到 unified snapshot | 固定族标识 |
| `takeover_ready` | `gate_results.takeover_ready` | `probe_contract_snapshot.gate_results.takeover_ready` | 最终接管结论 |
| `sample_count` | `sampling_results.sample_count_completed` | `fitted_from_sample_count` / gate sample count | 统一样本规模 |
| `gate_results` | 顶层 `gate_results` | `probe_contract_snapshot.gate_results` | 保留门级细节 |
| `blockers` | Warning 先给空数组 | `takeover_blockers` | 统一阻断入口 |
| `thresholds` 或等价扁平阈值字段 | `warning_upper/center/lower_threshold_value` | `warning_threshold_value` / `error_threshold_value` | 与本族 fitted thresholds 镜像一致 |
| `support_counts` | `nonzero_scenario_count` | `old_escape_true_count` | 保留族特有支撑明细 |
| `confidence_score` | 由 `nonzero_scenario_count / 3.0` 归一化 | 由 `old_escape_true_count / fitted_from_sample_count` 归一化 | 下游统一可信度入口，范围固定 `0.0-1.0` |

推荐实现方式：继续保留 Warning `readiness_snapshot` 与 Critical `probe_contract_snapshot` 历史结构，再新增一层 `unified_snapshot`。同时把 Critical 真采样结果也落到 `user://critical_sampling.json`，让后续 contract 基于两个 JSON 产物做纯产物对比，而不是继续读取 `res://` 源码字符串。

## Task 1: 定义 unified snapshot schema 并先锁 Warning 侧

**Files:**
- Modify: `tests/battle/test_warning_readiness_snapshot_contract.gd`
- Modify: `tests/battle/test_warning_sampling_artifact_content_contract.gd`
- Test: `tests/battle/test_warning_readiness_snapshot_contract.gd`

- [ ] **Step 1: 写 Warning unified snapshot 的失败测试**

```gdscript
var unified_snapshot: Dictionary = payload.get("unified_snapshot", {})
_assert_true(str(unified_snapshot.get("family", "")) == "warning", "unified snapshot should identify warning family", failures)
_assert_true(bool(unified_snapshot.get("takeover_ready", false)) == bool(gate_results.get("takeover_ready", false)), "unified snapshot should mirror warning takeover readiness", failures)
_assert_true(int(unified_snapshot.get("sample_count", -1)) == int(sampling_results.get("sample_count_completed", -2)), "unified snapshot should mirror warning sample count", failures)
_assert_true(int(unified_snapshot.get("support_counts", {}).get("nonzero_scenario_count", -1)) == int(sampling_results.get("nonzero_scenario_count", -2)), "unified snapshot should mirror warning nonzero scenario count", failures)
_assert_true(float(unified_snapshot.get("confidence_score", -1.0)) == 1.0, "warning unified snapshot should persist normalized confidence score", failures)
_assert_true(float(unified_snapshot.get("thresholds", {}).get("warning_upper_threshold_value", 0.0)) == float(fitted_thresholds.get("warning_upper_threshold_value", 0.0)), "unified snapshot should mirror warning upper threshold", failures)
```

- [ ] **Step 2: 运行 Warning snapshot contract，确认先红**

Run: `godot --headless --path C:/Users/admin/Documents/demo res://tests/test_runner.gd --test battle/test_warning_readiness_snapshot_contract`
Expected: FAIL，因为 `payload` 中还没有 `unified_snapshot`

- [ ] **Step 3: 在内容级 contract 中补 unified snapshot 断言**

```gdscript
var unified_snapshot: Dictionary = payload.get("unified_snapshot", {})
var unified_thresholds: Dictionary = unified_snapshot.get("thresholds", {})
_assert_true(str(unified_snapshot.get("family", "")) == "warning", "warning artifact should persist unified snapshot family", failures)
_assert_true(float(unified_thresholds.get("warning_threshold_value", 0.0)) == float(fitted_thresholds.get("warning_threshold_value", 0.0)), "warning unified snapshot should mirror fitted center threshold", failures)
_assert_true(bool(unified_snapshot.get("takeover_ready", false)) == bool(gate_results.get("takeover_ready", false)), "warning unified snapshot should mirror gate takeover readiness", failures)
```

- [ ] **Step 4: 重新运行两个 Warning contract，仍保持红但失败原因只剩 unified snapshot 缺失**

Run: `godot --headless --path C:/Users/admin/Documents/demo res://tests/test_runner.gd --test battle/test_warning_readiness_snapshot_contract --test battle/test_warning_sampling_artifact_content_contract`
Expected: FAIL，错误集中在 `unified_snapshot` 缺失或为空

- [ ] **Step 5: Commit**

```bash
git add tests/battle/test_warning_readiness_snapshot_contract.gd tests/battle/test_warning_sampling_artifact_content_contract.gd
git commit -m "test: add warning unified snapshot contracts"
```

## Task 2: 在 Warning artifact 中产出 unified snapshot

**Files:**
- Modify: `tests/battle/test_battle_runtime_probe_medium_density_filled_slots.gd`
- Test: `tests/battle/test_warning_readiness_snapshot_contract.gd`
- Test: `tests/battle/test_warning_sampling_artifact_content_contract.gd`

- [ ] **Step 1: 在 Warning payload 构造前写最小 unified snapshot 实现**

```gdscript
var confidence_score := clampf(float(nonzero_scenario_count) / 3.0, 0.0, 1.0)
var unified_snapshot := {
	"family": "warning",
	"takeover_ready": bool(gate_results.get("takeover_ready", false)),
	"sample_count": samples.size(),
	"gate_results": gate_results,
	"blockers": [],
	"support_counts": {
		"nonzero_scenario_count": nonzero_scenario_count
	},
	"confidence_score": confidence_score,
	"thresholds": {
		"warning_upper_threshold_value": float(fitted_thresholds.get("warning_upper_threshold_value", 0.0)),
		"warning_threshold_value": float(fitted_thresholds.get("warning_threshold_value", 0.0)),
		"warning_lower_threshold_value": float(fitted_thresholds.get("warning_lower_threshold_value", 0.0))
	}
}
```

- [ ] **Step 2: 把 unified snapshot 写入 payload**

```gdscript
var payload := {
	"sampling_plan": sampling_plan,
	"fingerprint_zone_summary": fingerprint_zone_summary,
	"threshold_candidate": threshold_candidate,
	"threshold_formula": threshold_formula,
	"fitted_thresholds": fitted_thresholds,
	"gate_results": gate_results,
	"readiness_snapshot": readiness_snapshot,
	"unified_snapshot": unified_snapshot,
	"scenario_param": scenario_param,
	"warning_summary": warning_summary,
	"scenario_summaries": scenario_summaries,
	"outliers": outliers,
	"scatter_plot": scatter_plot,
	"sampling_results": sampling_results,
	"known_tail_items": known_tail_items,
	"samples": samples
}
```

- [ ] **Step 3: 运行 Warning contract，确认转绿**

Run: `godot --headless --path C:/Users/admin/Documents/demo res://tests/test_runner.gd --test battle/test_warning_readiness_snapshot_contract --test battle/test_warning_sampling_artifact_content_contract`
Expected: PASS

- [ ] **Step 4: 运行 Warning fixture，确认 artifact 实际落出 unified snapshot**

Run: `godot --headless --path C:/Users/admin/Documents/demo res://tests/battle/test_battle_runtime_probe_medium_density_filled_slots.gd`
Expected: PASS，并更新 `user://warning_sampling.json`

- [ ] **Step 5: Commit**

```bash
git add tests/battle/test_battle_runtime_probe_medium_density_filled_slots.gd
git commit -m "feat: add warning unified snapshot payload"
```

## Task 3: 先把 Critical contract 改成 user artifact 红测

**Files:**
- Modify: `tests/battle/test_probe_sampling_payload_contract.gd`
- Modify: `tests/battle/test_probe_fitted_threshold_contract.gd`
- Modify: `tests/battle/test_probe_takeover_gate_contract.gd`
- Test: `tests/battle/test_probe_sampling_payload_contract.gd`

- [ ] **Step 1: 让 Critical payload presence contract 读取 `user://critical_sampling.json`**

```gdscript
const ARTIFACT_PATH := "user://critical_sampling.json"

var text := FileAccess.get_file_as_string(ARTIFACT_PATH)
_assert_true(text != "", "critical sampling artifact should exist before payload checks", failures)
if text == "":
	return failures
var json := JSON.new()
var parse_result := json.parse(text)
_assert_true(parse_result == OK, "critical sampling artifact should parse as json", failures)
if parse_result != OK:
	return failures
var payload: Dictionary = json.data
var unified_snapshot: Dictionary = payload.get("unified_snapshot", {})
_assert_true(str(unified_snapshot.get("family", "")) == "critical", "critical unified snapshot should identify critical family", failures)
```

- [ ] **Step 2: 让 fitted threshold contract 读取 artifact 中的 unified snapshot**

```gdscript
var payload: Dictionary = json.data
var unified_snapshot: Dictionary = payload.get("unified_snapshot", {})
var thresholds: Dictionary = unified_snapshot.get("thresholds", {})
_assert_true(float(thresholds.get("warning_threshold_value", 0.0)) == float(payload.get("fitted_thresholds", {}).get("warning_threshold_value", 0.0)), "critical unified snapshot should mirror warning threshold value", failures)
_assert_true(float(thresholds.get("error_threshold_value", 0.0)) == float(payload.get("fitted_thresholds", {}).get("error_threshold_value", 0.0)), "critical unified snapshot should mirror error threshold value", failures)
```

- [ ] **Step 3: 让 gate contract 读取 artifact 中的 unified snapshot**

```gdscript
var payload: Dictionary = json.data
var unified_snapshot: Dictionary = payload.get("unified_snapshot", {})
var gate_results: Dictionary = unified_snapshot.get("gate_results", {})
_assert_true(bool(unified_snapshot.get("takeover_ready", false)) == bool(gate_results.get("takeover_ready", false)), "critical unified snapshot should mirror takeover readiness", failures)
_assert_true(unified_snapshot.has("blockers"), "critical unified snapshot should persist blocker list", failures)
```

- [ ] **Step 4: 运行 3 个 Critical contract，确认先红**

Run: `godot --headless --path C:/Users/admin/Documents/demo res://tests/test_runner.gd --test battle/test_probe_sampling_payload_contract --test battle/test_probe_fitted_threshold_contract --test battle/test_probe_takeover_gate_contract`
Expected: FAIL，因为 `user://critical_sampling.json` 还未落盘或没有 `unified_snapshot`

- [ ] **Step 5: Commit**

```bash
git add tests/battle/test_probe_sampling_payload_contract.gd tests/battle/test_probe_fitted_threshold_contract.gd tests/battle/test_probe_takeover_gate_contract.gd
git commit -m "test: move critical snapshot contracts to artifact checks"
```

## Task 4: 在 Critical artifact 中产出 unified snapshot 并落盘 JSON

**Files:**
- Modify: `tests/battle/test_battle_runtime_probe_contact_oscillation.gd:588-625`
- Test: `tests/battle/test_probe_sampling_payload_contract.gd`
- Test: `tests/battle/test_probe_fitted_threshold_contract.gd`
- Test: `tests/battle/test_probe_takeover_gate_contract.gd`

- [ ] **Step 1: 在 `probe_contract_snapshot` 之后定义 unified snapshot，并加入统一可信度字段**

```gdscript
var confidence_score := clampf(float(old_escape_true_values.size()) / maxf(1.0, float(fitted_thresholds.get("fitted_from_sample_count", 0))), 0.0, 1.0)
var unified_snapshot := {
	"family": "critical",
	"takeover_ready": bool(gate_results.get("takeover_ready", false)),
	"sample_count": int(probe_contract_snapshot.get("fitted_from_sample_count", 0)),
	"gate_results": gate_results,
	"blockers": gate_results.get("takeover_blockers", []),
	"support_counts": {
		"old_escape_true_count": int(probe_contract_snapshot.get("old_escape_true_count", 0))
	},
	"confidence_score": confidence_score,
	"thresholds": {
		"warning_threshold_value": float(probe_contract_snapshot.get("warning_threshold_value", 0.0)),
		"error_threshold_value": float(probe_contract_snapshot.get("error_threshold_value", 0.0))
	}
}
```

- [ ] **Step 2: 把 unified snapshot 写入最终 payload，并补 `user://critical_sampling.json` 落盘**

```gdscript
var payload := {
	"sampling_plan": critical_sampling_plan,
	"fingerprint_zone_summary": fingerprint_zone_summary,
	"threshold_formula": threshold_formula,
	"fitted_thresholds": fitted_thresholds,
	"probe_contract_snapshot": probe_contract_snapshot,
	"unified_snapshot": unified_snapshot,
	"long_running_stability": long_running_stability,
	"scatter_plot": scatter_plot,
	"critical_sampling_result_contract": critical_sampling_result_contract,
	"outliers": outliers,
	"samples": family_samples
}
var json_file := FileAccess.open("user://critical_sampling.json", FileAccess.WRITE)
if json_file != null:
	json_file.store_string(JSON.stringify(payload, "\t"))
	json_file.close()
```

- [ ] **Step 3: 运行 3 个 Critical contract，确认转绿**

Run: `godot --headless --path C:/Users/admin/Documents/demo res://tests/test_runner.gd --test battle/test_probe_sampling_payload_contract --test battle/test_probe_fitted_threshold_contract --test battle/test_probe_takeover_gate_contract`
Expected: PASS

- [ ] **Step 4: 运行 Critical fixture，确认 `user://critical_sampling.json` 实际落盘**

Run: `godot --headless --path C:/Users/admin/Documents/demo res://tests/battle/test_battle_runtime_probe_contact_oscillation.gd`
Expected: PASS，并更新 `user://critical_sampling.json`

- [ ] **Step 5: Commit**

```bash
git add tests/battle/test_battle_runtime_probe_contact_oscillation.gd
git commit -m "feat: add critical unified snapshot artifact"
```

## Task 5: 新增跨族 unified snapshot schema contract（双 JSON 产物对比）

**Files:**
- Create: `tests/battle/test_unified_snapshot_schema_contract.gd`
- Modify: `tests/test_runner.gd`
- Test: `tests/battle/test_unified_snapshot_schema_contract.gd`

- [ ] **Step 1: 写新的跨族 contract 文件**

```gdscript
extends RefCounted

const WARNING_ARTIFACT_PATH := "user://warning_sampling.json"
const CRITICAL_ARTIFACT_PATH := "user://critical_sampling.json"

func _read_json(path: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(path)
	if text == "":
		return {}
	var json := JSON.new()
	if json.parse(text) != OK:
		return {}
	return json.data

func run() -> Array[String]:
	var failures: Array[String] = []
	var warning_payload := _read_json(WARNING_ARTIFACT_PATH)
	var critical_payload := _read_json(CRITICAL_ARTIFACT_PATH)
	_assert_true(not warning_payload.is_empty(), "warning artifact should exist before unified snapshot checks", failures)
	_assert_true(not critical_payload.is_empty(), "critical artifact should exist before unified snapshot checks", failures)
	if warning_payload.is_empty() or critical_payload.is_empty():
		return failures
	var warning_unified: Dictionary = warning_payload.get("unified_snapshot", {})
	var critical_unified: Dictionary = critical_payload.get("unified_snapshot", {})
	_assert_true(str(warning_unified.get("family", "")) == "warning", "warning unified snapshot should identify warning family", failures)
	_assert_true(str(critical_unified.get("family", "")) == "critical", "critical unified snapshot should identify critical family", failures)
	_assert_true(warning_unified.has("thresholds") and critical_unified.has("thresholds"), "both unified snapshots should persist thresholds block", failures)
	_assert_true(warning_unified.has("gate_results") and critical_unified.has("gate_results"), "both unified snapshots should persist gate results", failures)
	_assert_true(warning_unified.has("support_counts") and critical_unified.has("support_counts"), "both unified snapshots should persist support counts", failures)
	_assert_true(typeof(warning_unified.get("confidence_score", null)) == TYPE_FLOAT or typeof(warning_unified.get("confidence_score", null)) == TYPE_INT, "warning unified snapshot should persist confidence score", failures)
	_assert_true(typeof(critical_unified.get("confidence_score", null)) == TYPE_FLOAT or typeof(critical_unified.get("confidence_score", null)) == TYPE_INT, "critical unified snapshot should persist confidence score", failures)
	return failures

func _assert_true(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append(message)
```

- [ ] **Step 2: 在 runner 注册 suite**

```gdscript
{"name": "battle/test_unified_snapshot_schema_contract", "path": "res://tests/battle/test_unified_snapshot_schema_contract.gd"},
```

- [ ] **Step 3: 运行新 contract，确认通过**

Run: `godot --headless --path C:/Users/admin/Documents/demo res://tests/test_runner.gd --test battle/test_unified_snapshot_schema_contract`
Expected: PASS

- [ ] **Step 4: 运行所有 snapshot 相关 contract，确认没有回归**

Run: `godot --headless --path C:/Users/admin/Documents/demo res://tests/test_runner.gd --test battle/test_warning_readiness_snapshot_contract --test battle/test_warning_sampling_artifact_content_contract --test battle/test_probe_sampling_payload_contract --test battle/test_probe_fitted_threshold_contract --test battle/test_probe_takeover_gate_contract --test battle/test_unified_snapshot_schema_contract`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add tests/battle/test_unified_snapshot_schema_contract.gd tests/test_runner.gd
git commit -m "test: add cross-family unified snapshot artifact contract"
```
## Task 6: 切下游消费面到 unified snapshot 并做全量验证

**Files:**
- Modify: `tests/battle/test_warning_readiness_snapshot_contract.gd`
- Modify: `tests/battle/test_probe_fitted_threshold_contract.gd`
- Modify: `tests/battle/test_probe_takeover_gate_contract.gd`
- Test: `tests/test_runner.gd`

- [ ] **Step 1: 在 Warning contract 中把读取主入口切到 `unified_snapshot`**

```gdscript
var unified_snapshot: Dictionary = payload.get("unified_snapshot", {})
var unified_thresholds: Dictionary = unified_snapshot.get("thresholds", {})
var unified_counts: Dictionary = unified_snapshot.get("support_counts", {})
_assert_true(float(unified_thresholds.get("warning_threshold_value", 0.0)) == float(fitted_thresholds.get("warning_threshold_value", 0.0)), "warning unified snapshot should mirror fitted center threshold", failures)
_assert_true(int(unified_counts.get("nonzero_scenario_count", -1)) == int(sampling_results.get("nonzero_scenario_count", -2)), "warning unified snapshot should mirror nonzero scenario count", failures)
_assert_true(float(unified_snapshot.get("confidence_score", -1.0)) == 1.0, "warning unified snapshot should mirror normalized confidence score", failures)
```

- [ ] **Step 2: 在 Critical contract 中把读取主入口切到 `unified_snapshot`**

```gdscript
var unified_snapshot: Dictionary = payload.get("unified_snapshot", {})
var support_counts: Dictionary = unified_snapshot.get("support_counts", {})
_assert_true(int(support_counts.get("old_escape_true_count", -1)) == int(payload.get("fitted_thresholds", {}).get("old_escape_true_count", -2)), "critical unified snapshot should mirror old escape true count", failures)
_assert_true(unified_snapshot.has("blockers"), "critical unified snapshot should persist blockers array", failures)
_assert_true(float(unified_snapshot.get("confidence_score", -1.0)) >= 0.0 and float(unified_snapshot.get("confidence_score", -1.0)) <= 1.0, "critical unified snapshot should keep confidence score normalized", failures)
```

- [ ] **Step 3: 运行 snapshot 相关 contract，全绿后再跑全量 runner**

Run: `godot --headless --path C:/Users/admin/Documents/demo res://tests/test_runner.gd --test battle/test_warning_readiness_snapshot_contract --test battle/test_warning_sampling_artifact_content_contract --test battle/test_probe_sampling_payload_contract --test battle/test_probe_fitted_threshold_contract --test battle/test_probe_takeover_gate_contract --test battle/test_unified_snapshot_schema_contract`
Expected: PASS

- [ ] **Step 4: fresh 跑完整 runner**

Run: `godot --headless --path C:/Users/admin/Documents/demo res://tests/test_runner.gd`
Expected: PASS with 0 failures

- [ ] **Step 5: Commit**

```bash
git add tests/battle/test_warning_readiness_snapshot_contract.gd tests/battle/test_probe_fitted_threshold_contract.gd tests/battle/test_probe_takeover_gate_contract.gd
git commit -m "refactor: switch snapshot consumers to unified snapshot"
```

## Verification

| 层级 | 命令 | 期望 |
|---|---|---|
| Warning snapshot contract | `godot --headless --path C:/Users/admin/Documents/demo res://tests/test_runner.gd --test battle/test_warning_readiness_snapshot_contract --test battle/test_warning_sampling_artifact_content_contract` | PASS |
| Critical snapshot contract | `godot --headless --path C:/Users/admin/Documents/demo res://tests/test_runner.gd --test battle/test_probe_sampling_payload_contract --test battle/test_probe_fitted_threshold_contract --test battle/test_probe_takeover_gate_contract` | PASS |
| Cross-family unified contract | `godot --headless --path C:/Users/admin/Documents/demo res://tests/test_runner.gd --test battle/test_unified_snapshot_schema_contract` | PASS |
| Dual-artifact sanity | 检查 `user://warning_sampling.json` 与 `user://critical_sampling.json` 都存在 `unified_snapshot`、`confidence_score`、`thresholds`、`gate_results` | PASS |
| Full regression | `godot --headless --path C:/Users/admin/Documents/demo res://tests/test_runner.gd` | PASS, 0 failures |
``` }]}
## Self-review
- Spec coverage: 已覆盖 unified snapshot schema、Warning/Critical 对齐、产物级 contract、下游消费迁移、runner 回归。
- Placeholder scan: 无 `TODO/TBD/implement later` 占位词；每个任务都含具体代码与命令。
- Type consistency: 统一使用 `unified_snapshot`、`thresholds`、`support_counts`、`blockers`、`sample_count` 命名。
