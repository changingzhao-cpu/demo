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

## Phase boundary
- Phase A only observes.
- No battle decision, AI route, or effect policy is changed by V4 in this phase.

## Issue Interpretation Template

| Item | Fill-in |
|---|---|
| Business issue name | |
| Observable symptom | |
| Triggering scene/wave | |
| V4 signal(s) | |
| Why the signal explains the issue | |
| Follow-up action | |

## First Interpretation Case

| Item | Current status |
|---|---|
| Business issue name | 高密度接敌抖动/拥挤毛刺 |
| Observable symptom | 单位在高密度接敌阶段出现高频抖动，虽然未逃逸，但表现为接敌中带不稳定 |
| Triggering scene/wave | `battle_scene_runtime_tick` 真实业务路径；critical density 基线样本 |
| V4 signal(s) | `high_frequency_jitter_count=38`、`contention_index=0.25`、`claim_success_rate=0.25`、`attack_rebind_escape_count=0`、`late_commit_deviation=0.0` |
| Why the signal explains the issue | 问题不是迟滞提交或逃逸回绑，而是高密度接敌中的持续抖动；低 `claim_success_rate` 与稳定非零 `contention_index` 说明接敌资源竞争持续存在，而 `high_frequency_jitter_count` 直接给出可观测的抖动证据 |
| Follow-up action | 进入降级式 feedback 设计，优先考虑特效削减、AI 精度放宽、负载节流，而不是直接阻断战斗逻辑 |

## Case writing rule
- Describe the business symptom first.
- Then record the triggering scene or wave.
- Then list the exact V4 signal(s).
- Then explain why the signal is sufficient to explain the issue.
- Do not jump to feedback or takeover decisions in this section.

## First degradative feedback policy

| Signal | Feedback |
|---|---|
| `attack_midband_drift_count > 0` | reduce non-core battle effects |
| `attack_rebind_escape_count > 0` | relax AI precision before altering battle authority |

## Progression rule
- Silent baseline first
- Real issue interpretation second
- Degradative feedback third

## Before gate activation
- first prove that V4 can explain one real business issue
- then activate degradative feedback
- do not directly switch to authoritative takeover

## Degradative feedback evidence rule

| Evidence | Requirement |
|---|---|
| Before | 记录问题出现时的业务症状、wave/live_count/combat_event_count 与对应 V4 signal |
| During | 记录 `feedback_mode` / `feedback_active` 与 shadow recommendation 如何变化 |
| After | 记录业务表现是否收敛，并保留在 `business_probe_events` 或 `battle_report_timeline` 可复查 |

## Current evidence boundary
- 现阶段已具备 `business_probe_events`、`feedback_mode`、`takeover_shadow_*` 与 `battle_report_timeline` 出口。
- 下一步应补“反馈前/后”证据，而不是直接扩成第二个 authoritative decision point。
