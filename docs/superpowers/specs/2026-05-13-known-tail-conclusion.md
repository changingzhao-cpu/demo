# Known Tail Conclusion

## Final conclusion

当前 full runner 结束时的尾项：

| Item | Current state |
|---|---|
| DummyTexture | `1 DummyTexture` |
| resources still in use | `20 resources still in use` |

已经完成的定位表明，这不是 battle 逻辑错误，也不是 active runtime reference 没清掉。

## Evidence

| Check | Result | Conclusion |
|---|---|---|
| fresh full runner | `162/162 PASS` | 业务逻辑与 contract 通过 |
| EffectPool/ObjectPool active refs cleanup | tail 不变 | 不是活跃引用列表问题 |
| `test_runner.gd` 主动释放 suite 实例 | tail 不变 | 不是 runner 持有 suite 实例问题 |
| `unit_view.gd` 顶层贴图 preload → lazy load 实验 | tail 不变 | 不是单位贴图 preload 主因 |
| `reward_panel.tscn` load-only | 不足以复现同类 tail | UI scene 不是主因 |
| `battle_scene.tscn` instantiate/free 最小 case | `before_free` 快照里 `active_enemy=0`、`active_ally=0`、`active_visual=0`、`effect_layer_children=0`，但退出后仍保留 `object_pool.gd` / `effect_pool.gd` | 不是 battle scene 活对象引用链问题，而更像 GDScript/resource cache 生命周期 |

## Working interpretation

| Scope | Interpretation |
|---|---|
| project logic | 已清理到足以证明没有明显活跃对象残留 |
| remaining tail | 更像 Godot 对 `GDScript` / `PackedScene` / `CompressedTexture2D` 的进程级资源缓存/退出行为 |
| recommended status | 记录为已知运行时尾项，而不是继续作为项目功能缺陷追查 |

## Acceptance policy

后续此仓库的相关验收建议采用：

| Condition | Accept |
|---|---|
| fresh full runner `162/162 PASS` | 是 |
| 仍出现当前已知 `1 DummyTexture + 20 resources still in use` | 是，作为已知 Godot 运行时尾项接受 |
| 尾项数量或种类显著变化 | 否，应重新调查 |

## Cleanup guidance

| Action | Recommendation |
|---|---|
| 未提交的 teardown/debug 实验改动 | 回退，不保留进主线 |
| repro/debug 结论文档 | 保留 |
| 相关 worktrees | 在确认不再需要后删除 |
