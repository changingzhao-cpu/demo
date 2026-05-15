# V4 Backlog Tiers

## P1

| Item | Why it stays out of current slice |
|---|---|
| 基于真实业务数据建立 threshold baseline | 静默挂载已完成，下一步应进入真实数据基线拟合 |
| 让 `takeover_ready` 或相关 gate 反馈业务层 | 属于下一阶段闭环激活，不在本轮静默挂载内 |

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
