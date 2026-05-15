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

## Rule

- Closeout phase must not accept new feature logic.
- Any new work must be classified into P1 or P2 before implementation begins.
