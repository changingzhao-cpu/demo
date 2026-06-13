# V4 Iteration 1 Silent Baseline Design

**Goal:** 在不修改真实业务战斗判定逻辑的前提下，把 V4 作为“幽灵观察者”静默挂载到真实业务战斗路径，稳定产出第一份真实业务 unified snapshot 与 trace payload。

**Why now:** 当前 V4 已完成可交付收口，下一阶段的核心不是继续整结构，而是尽快接受真实业务压力验证。Iteration 1 的成功标准不是“让 V4 接管业务”，而是“让 V4 在真实战斗里看得见、记得住、且不打断业务本身”。

---

## 1. Scope

### In scope

| 项目 | 说明 |
|---|---|
| 真实业务静默挂载 | 在真实 battle 路径里调用 V4 bridge，但不改变业务判定 |
| 基线采样产物 | 产出真实业务 unified snapshot / trace payload / business probe events |
| 性能观测钩子 | 建立最小观测，确认 V4 不明显拖垮业务帧率 |
| 最小 contract | 验证“挂载存在 + 产物存在 + 不改变业务逻辑” |

### Out of scope

| 项目 | 处理 |
|---|---|
| 大规模结构整顿 | 禁止 |
| 大脚本拆分 | 禁止 |
| V4 takeover 直接接管业务逻辑 | 不在本轮 |
| Critical 精度继续调参 | 不在本轮 |
| Godot 资源尾项排查 | 继续冻结 |

---

## 2. Architecture stance

本轮唯一架构原则：**V4 必须先做“幽灵观察者”，再做“智能节流阀”。**

| 原则 | 含义 |
|---|---|
| Silent mount | V4 只采集，不影响业务判定 |
| Business-first | 业务战斗逻辑优先，V4 不得破坏战斗路径 |
| Evidence-first | 先拿到真实业务 unified snapshot，再谈后续调参或接管 |
| Freeze refactor | 除接入所需适配代码外，不改 V4 内部流转逻辑 |

---

## 3. Design

### 3.1 Silent integration target

真实业务战斗入口只做一件事：把 battle runtime 状态通过统一桥接 API 送入 V4。

推荐接口保持不变：

| API | 作用 |
|---|---|
| `emit_v4_probe_event(event: Dictionary)` | 业务代码唯一桥接点 |

推荐事件形态：

| 字段 | 说明 |
|---|---|
| `event_type` | 事件类型，如 `business_battle_tick` |
| `state` | 当前 battle state |
| `wave` | 波次或业务阶段 |
| `live_count` | 当前单位数量 |
| `combat_event_count` | 当前战斗事件计数 |

### 3.2 Baseline output

Iteration 1 必须产出三类证据：

| 证据 | 用途 |
|---|---|
| `business_probe_events` | 证明真实业务路径已成功静默挂载 |
| `warning_unified_snapshot` / `critical_unified_snapshot` | 证明真实业务路径下仍有统一消费面 |
| 业务基线采样工件 | 为 Iteration 2 的毛刺解释准备真实输入 |

### 3.3 Performance guardrail

本轮必须对一个风险保持警惕：V4 自己成为业务性能噪音。

最小要求：

| 项目 | 验收 |
|---|---|
| 挂载后 battle scene 仍可正常推进 | 必须满足 |
| 现有 smoke / full runner 不回退 | 必须满足 |
| V4 事件缓冲受限 | 必须有上限，避免无限增长 |

### 3.4 Exit criteria

Iteration 1 完成不以“业务接管”判断，而以以下三点判断：

| 条件 | 说明 |
|---|---|
| 静默挂载存在 | 真实业务路径能稳定发出 business probe events |
| 统一消费面仍成立 | trace payload / unified snapshot 继续可消费 |
| 业务不被打断 | 挂载不破坏 battle scene 正常运行与既有 contracts |

---

## 4. Questions resolved by the senior review

| 问题 | 结论 |
|---|---|
| 现在是否该继续整结构？ | 不该，立即停止 |
| 是否先进入真实业务接入？ | 是，刻不容缓 |
| 技术债如何处理？ | 除业务接入必需项外，全部冻结在 P2 |
| V4 当前护栏是否足够？ | 足够支撑业务接入 |

---

## 5. Success criteria

| 项目 | 验收标准 |
|---|---|
| 静默挂载 | 真实业务 battle scene 能稳定暴露 `business_probe_events` |
| 统一快照 | `warning_unified_snapshot` / `critical_unified_snapshot` 继续存在 |
| 回归护栏 | smoke `All 6 test suite(s) passed.` |
| 全量验证 | full runner `All 163 test suite(s) passed.` |
| 后续准备 | 具备进入 Iteration 2（解释真实毛刺）的真实业务输入 |
