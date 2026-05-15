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
