# V4 Closeout Infrastructure Design

**Goal:** 在不继续扩展 V4 功能逻辑的前提下，为当前阶段建立可交付的收口基础设施：最小 smoke 回归、test runner 入口规范、交付归档、backlog 分级。

**Why now:** V4 当前已经具备可交付状态，但后续继续开发仍有三个高摩擦点：核心回归集过大、不知道改动后该先跑什么、以及指标/阶段结论只存在于近期记忆里。先收口基础设施，可以降低明天继续开发的风险和心智负担。

---

## 1. Scope

本轮只做收口基础设施，不做新的 Feature 逻辑，不做大脚本内部重构，不继续追 `DummyTexture/ObjectDB/resources still in use` 这一已接受尾项。

### In scope

| 项目 | 说明 |
|---|---|
| Smoke baseline | 从 163 项测试中抽出 P0 级最小回归集合，形成 5 秒级别的核心保险栓 |
| Runner entry normalization | 统一 test runner 对核心 suite/fixture 的入口约定，降低调用成本 |
| Delivery archive | 沉淀当前阶段交付结果，重点记录关键指标的物理内涵与验收口径 |
| Backlog triage | 把后续事项明确划分为 P1/P2，停止继续混入当前收口周期 |

### Out of scope

| 项目 | 处理 |
|---|---|
| 新业务 Feature | 本轮不做 |
| 真实业务战斗接入实现 | 只列为后续 P1，不在本轮落地 |
| 几千行 fixture 内部重构 | 本轮不做 |
| 20 resources / DummyTexture 尾项继续排查 | 维持 accepted |
| Critical 精度进一步优化 | 作为 P2 |

---

## 2. Recommended approach

| 方案 | 内容 | 优点 | 风险 | 结论 |
|---|---|---|---|---|
| A. 文档优先 | 先写归档和 backlog，再补基线 | 很快有文档 | 回归保险栓建立太晚 | 不推荐 |
| B. 基线优先 | 先做 smoke suite 和 runner 入口规范，再补文档 | 最快降低后续开发风险 | 文档稍后补 | **推荐** |
| C. 全面整顿 | 四个包并行推进 | 一次性最完整 | 容易重新发散成大重构 | 不推荐 |

本设计采用 **方案 B**。

---

## 3. Design

### 3.1 Smoke baseline

目标是让后续每次提交前，都能先用一个最小入口确认 V4 没崩，而不是每次直接跑全量 163 项。

#### Smoke suite selection rule

Smoke suite 只保留“交付是否仍成立”的核心 contract，不追求覆盖所有 probe 细节。

| 类别 | 选择标准 | 代表 suite |
|---|---|---|
| Warning artifact | warning unified snapshot 仍可消费 | warning snapshot / artifact content contract |
| Critical artifact | critical unified snapshot、perturbation mirrors、takeover gate 仍成立 | perturbation contract / takeover gate contract / sampling payload contract |
| Runtime trace | trace payload 仍能暴露 warning/critical unified snapshots | runtime probe trace contract |
| Battle scene binding | scene 路径仍能消费统一 payload | battle scene runtime binding |
| Runner integrity | smoke 入口自身仍能被 runner 调起 | runner banner / suite membership 最小必要项 |

产物形态建议：

| 文件 | 作用 |
|---|---|
| `tests/battle/smoke_suite.json` | 声明 P0 smoke suites 列表 |
| `tests/test_runner.gd` | 增加读取 smoke 配置或按参数只执行 smoke |

#### Command contract

| 命令 | 用途 |
|---|---|
| `Godot --headless --path ... -s res://tests/test_runner.gd -- --smoke` | 日常 5 秒级保险栓 |
| `Godot --headless --path ... -s res://tests/test_runner.gd` | 交付前全量验证 |

### 3.2 Runner entry normalization

现在最痛的问题不是测试不够，而是“哪些东西该进 runner、哪些是独立 fixture、如何调用”不够清楚。

本轮只修入口约定，不重构 fixture 内部。

#### Entry taxonomy

| 类型 | 约定 | 示例 |
|---|---|---|
| Runner suite | 必须是 `extends RefCounted` + `run() -> Array[String]`，由 `test_runner.gd` 调度 | contract / schema / binding suites |
| Direct fixture | 允许 `extends SceneTree`，可直接 `-s` 执行，用于刷新 artifact 或生成观测数据 | `test_battle_runtime_probe_contact_oscillation.gd` |
| Source contract | 不执行 fixture，只检查源码/静态契约 | fingerprint / ordering / membership 类测试 |

#### Rule

| 规则 | 含义 |
|---|---|
| RefCounted suite 不等待 SceneTree fixture | 避免把独立运行脚本混入 runner 生命周期，造成卡死 |
| Fixture 刷新与 contract 校验分离 | 先明确“谁负责生成 artifact”，再由 contract 只读验证 |
| Runner 只调 suite，不直接承载复杂 fixture orchestration | 保持入口稳定 |

建议增加一份简短入口文档：

| 文件 | 作用 |
|---|---|
| `docs/test_entry_conventions.md` | 说明 suite / fixture / source contract 三种入口约定 |

### 3.3 Delivery archive

Archive 的核心不是记“改过什么代码”，而是记“为什么这些指标能代表真实运行时物理现象”。

#### Archive sections

| 章节 | 内容 |
|---|---|
| Milestone timeline | Warning、Critical、Runtime trace、Perturbation hardening 的阶段完成线 |
| Artifact contract map | 当前 warning/critical/runtime payload 的消费面 |
| Metric physics | 每个关键指标的物理内涵与可解释性 |
| Acceptance boundary | 什么算通过，什么已明确不追 |
| Known tail | accepted tail 的统一口径 |

#### Metric physics examples that must be documented

| 指标 | 物理内涵 |
|---|---|
| `contention_index` | 接敌/分配阶段单位间拥挤与冲突压力的强弱近似量，不是纯视觉指标 |
| `claim_success_rate` | 单位是否能稳定占据预期接敌/分配结果的成功率，反映执行稳定性 |
| `late_commit_deviation` | 后提交/迟滞提交导致的状态偏差，用来发现“结果晚到”型不稳定 |
| `old_escape_hit` | 历史 escape 异常是否重现，用于连接旧问题与新采样 |
| `attack_rebind_escape_count` | 攻击态下目标重绑后又逃出稳定接敌窗口的次数 |
| `attack_rebind_recontact_count` | 逃出后又重新回到稳定接敌窗口的次数 |
| `attack_midband_drift_count` | 未完全逃逸但在攻击中带发生不合理中带漂移的次数 |

建议产物：

| 文件 | 作用 |
|---|---|
| `docs/v4_delivery_archive.md` | 本轮阶段性交付总档案 |

### 3.4 Backlog triage

Backlog 的目标不是“列 TODO”，而是防止所有未完成事项继续污染当前收口阶段。

#### Tiering

| 优先级 | 内容 | 说明 |
|---|---|---|
| P1 | V4 接入真实业务战斗逻辑 | 下一阶段主线，但不在本轮实现 |
| P2 | 大脚本拆分、runner 内部进一步重构、Critical 精度继续提升、资源尾项继续排查 | 统一降级为后续优化 |

建议单独写成文档，避免和 readiness map 混在一起：

| 文件 | 作用 |
|---|---|
| `docs/v4_backlog_tiers.md` | 对未完成事项分级并冻结口径 |

---

## 4. Execution order

| 顺序 | 包 | 原因 |
|---|---|---|
| 1 | Smoke baseline | 先建立最小保险栓 |
| 2 | Runner entry normalization | 立刻降低调用摩擦 |
| 3 | Delivery archive | 用稳定口径沉淀知识 |
| 4 | Backlog triage | 最后正式封口未完成项 |

---

## 5. Success criteria

| 项目 | 验收标准 |
|---|---|
| Smoke baseline | 能通过单一入口快速执行一组 P0 suites |
| Runner normalization | suite / fixture / source contract 的入口边界清晰，避免再次卡在错误执行方式 |
| Delivery archive | 能回答“某指标为什么存在、反映什么物理现象、怎么解读” |
| Backlog triage | 所有非本轮交付项都被明确打入 P1/P2 |
| Full verification | 全量 runner 继续保持绿 |

---

## 6. Recommendation from senior-engineering perspective

当前最值钱的不是继续加功能，而是把“已经做出来的正确东西”变成低摩擦、可记忆、可回归、可交付的基础设施。最重要的动作不是大重构，而是建立一条以后每天都能重复执行的稳定路径：先跑 smoke，再决定是否跑全量；先看 archive，再调指标；先看 backlog tier，再决定是否开新坑。

这轮结束后，项目应该从“靠近期记忆维持正确”进入“靠明确 contract 和入口约定维持正确”。
