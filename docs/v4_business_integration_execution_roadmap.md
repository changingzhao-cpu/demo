# V4 Business Integration Execution Roadmap

## 主线结论

| 项目 | 决策 |
|---|---|
| 主线 | 坚定走真实业务接入 |
| 当前禁止事项 | 无业务压力下的大规模结构整顿 |
| 当前允许事项 | 基线拟合、毛刺解释、降级式反馈、闭环接管 |
| 护栏 | smoke `All 6 test suite(s) passed.` + full runner `All 163 test suite(s) passed.` |

## 执行阶段

| 阶段 | 目标 | 成功标准 | 不做什么 |
|---|---|---|---|
| Phase A | Silent Integration | 真实 battle 路径稳定暴露 `business_probe_events` 与 unified snapshots | 不改业务判定 |
| Phase B | Baseline Establishment | 产出第一版真实业务 threshold baseline | 不做接管 |
| Phase C | Real-Issue Interpretation | 至少解释 1 个真实业务毛刺/拥挤点 | 不做结构大修 |
| Phase D | Degradative Feedback | Warning/Critical 开始以降级方式影响业务层 | 不做粗暴阻断 |
| Phase E | Authoritative Takeover | `takeover_ready` 或同级 gate 进入业务闭环 | 不提前切主逻辑 |

## 当前所处位置

| 项目 | 状态 |
|---|---|
| Silent Integration | 已完成 |
| Baseline event fields | 已完成 |
| Real business baseline docs | 已完成第一版 |
| Next active target | Phase C / Real-Issue Interpretation |

## 未来 3 个迭代

| 迭代 | 目标 | 交付物 |
|---|---|---|
| Iteration 1 | 继续沉淀真实业务 baseline | baseline 文档、稳定采样、事件字段口径 |
| Iteration 2 | 拿到第一个真实业务毛刺解释案例 | 指标映射证据、毛刺解释记录 |
| Iteration 3 | 启动降级式 gate feedback | 最小反馈策略、回归验证 |

## 执行原则

| 原则 | 含义 |
|---|---|
| Business-first | 业务接入优先，结构优化服从真实痛点 |
| Evidence-first | 先采集真实数据，再调参、再反馈 |
| Freeze refactor | 不做无压力结构整顿 |
| Guardrails stay green | smoke / full runner 必须持续绿 |
