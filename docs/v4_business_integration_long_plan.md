# V4 Business Integration Long Plan

## 主线结论

后续开发主线已经确定：**坚定走真实业务接入主线**。

这意味着：

| 项目 | 决策 |
|---|---|
| 主目标 | 用真实业务战斗路径验证 V4 价值 |
| 当前禁止事项 | 无业务压力下的大规模结构整顿 |
| 当前允许事项 | 业务接入、基线拟合、毛刺解释、降级式反馈 |
| 冻结项 | 大脚本拆分、runner 深度重构、Critical 精度继续优化、Godot 资源尾项排查 |

## 长线开发阶段

| 阶段 | 目标 | 成功标准 |
|---|---|---|
| Phase A | Silent Integration | 真实业务路径稳定暴露 `business_probe_events` 与 unified snapshots |
| Phase B | Baseline Establishment | 建立第一版真实业务 threshold baseline |
| Phase C | Real-Issue Interpretation | 至少解释 1 个真实业务毛刺或拥挤点 |
| Phase D | Degradative Feedback | Warning/Critical 开始以降级方式影响业务逻辑 |
| Phase E | Authoritative Takeover | `takeover_ready` 或相关 gate 进入业务闭环接管 |

## Phase B：Baseline Establishment

| 项目 | 内容 |
|---|---|
| 目标 | 建立第一版真实业务 baseline |
| 输入 | `business_probe_events`、`warning_unified_snapshot`、`critical_unified_snapshot` |
| 关键字段 | `wave`、`live_count`、`combat_event_count`、`contention_index`、`claim_success_rate` |
| 成功标准 | 能稳定产出一组可解释的真实业务基线数据 |

## Phase C：Real-Issue Interpretation

| 项目 | 内容 |
|---|---|
| 目标 | 用 V4 数据解释至少 1 个真实业务已知毛刺 |
| 关键工作 | 将业务卡点与 `attack_rebind_escape_count` / `contention_index` / `late_commit_deviation` 对齐 |
| 成功标准 | 团队能接受“V4 确实解释了真实问题” |

## Phase D：Degradative Feedback

| 项目 | 内容 |
|---|---|
| 目标 | 在不粗暴阻断业务逻辑的前提下，让 V4 开始反馈业务层 |
| 反馈方式 | 特效削减、AI 精度放宽、负载节流 |
| 禁止事项 | 直接阻断 battle 流程或硬切接管 |
| 成功标准 | 能在不破坏战斗体验的前提下缓解问题场景 |

## Phase E：Authoritative Takeover

| 项目 | 内容 |
|---|---|
| 目标 | 在证据充分后，让 V4 gate 成为业务闭环一部分 |
| 前提 | Baseline 成立、毛刺解释成功、降级式反馈稳定 |
| 成功标准 | `takeover_ready` 或同级 gate 能安全影响业务决策 |

## 开发原则

| 原则 | 含义 |
|---|---|
| Business-first | 业务接入优先，结构优化服从真实痛点 |
| Evidence-first | 先采数据，再调参、再接管 |
| Freeze refactor | 不做无压力结构整顿 |
| Guardrails stay green | smoke 与 full runner 必须持续绿 |

## 最近 3 个迭代建议

| 迭代 | 工作重点 | 交付物 |
|---|---|---|
| Iteration 1 | 持续沉淀真实业务 baseline | baseline 文档、基线字段、稳定采样 |
| Iteration 2 | 抓到第一个真实业务毛刺解释案例 | 毛刺解释记录、指标映射证据 |
| Iteration 3 | 启动降级式 gate feedback | 最小反馈策略、回归验证 |
