# V4 Senior Review Consultation Text Design

**Goal:** 输出一份适合咨询资深工程师的正式文本，清晰说明 demo 项目当前开发进度、已交付边界、结构状态、后续开发候选路线，以及需要对方拍板的问题。

**Why now:** 当前 V4 已完成一轮可交付收口，但下一阶段到底应先接真实业务、还是先做结构整顿，已经进入“高判断密度、低实现密度”的阶段。这个阶段最需要的不是继续写代码，而是一份高质量上下文材料，用来换取高价值外部判断。

---

## 1. Scope

本轮目标不是继续设计实现细节，而是把“给资深工程师看的咨询材料”设计成一份可直接复制发送的文本。

### In scope

| 项目 | 说明 |
|---|---|
| 当前开发进度整理 | 汇总 Warning / Critical / Runtime trace / perturbation hardening 的完成状态 |
| 已交付边界说明 | 讲清楚当前哪些结果已经成立、哪些问题已接受、不再继续追 |
| 后续开发路线候选 | 给出 2-4 条下一阶段路线，并明确主次建议 |
| 咨询问题设计 | 把真正想让大牛回答的问题压缩成少量高价值问题 |
| 正式咨询文本 | 形成一份可直接发送的中文文本 |

### Out of scope

| 项目 | 处理 |
|---|---|
| 新功能实现 | 不做 |
| 新 implementation plan | 不做 |
| 继续扩写技术细节文档 | 不做，除非直接服务于咨询文本 |
| 继续重构 runner / fixture / contract | 不做 |

---

## 2. Recommended approach

| 方案 | 内容 | 优点 | 风险 | 结论 |
|---|---|---|---|---|
| A. 纯进度汇报 | 只讲当前完成了什么 | 简短 | 对方很难给出路线建议 | 不推荐 |
| B. 技术问题列表 | 直接丢问题，不讲背景 | 高密度 | 对方可能看不懂上下文 | 不推荐 |
| C. 综合体检文本 | 先给现状、边界、候选路线，再给拍板问题 | 最容易换来高质量反馈 | 文本稍长 | **推荐** |

本设计采用 **方案 C**。

---

## 3. Consultation text structure

### 3.1 Text purpose

这份文本要达到两个目的：

| 目的 | 说明 |
|---|---|
| 让对方在 2-3 分钟内理解当前状态 | 不需要翻代码也知道项目走到哪一步 |
| 让对方把反馈聚焦在“下一步怎么走” | 避免变成泛泛的技术点评 |

### 3.2 Recommended sections

| 段落 | 目标 | 内容重点 |
|---|---|---|
| 当前进度 | 快速建立上下文 | 已完成 Warning、Critical、Runtime trace、perturbation hardening |
| 当前交付边界 | 界定“已完成”与“已接受” | 163/163 tests、accepted tail、closeout infrastructure |
| 当前结构状态 | 让对方判断架构健康度 | smoke suite、runner conventions、artifact/unified snapshot 消费面 |
| 后续候选路线 | 让对方比较路线优先级 | 真实业务接入、结构整顿、精度优化、遗留债处理 |
| 请求拍板问题 | 逼出明确判断 | 哪条路线应先做、哪些债该延后 |

### 3.3 Tone and writing constraints

| 规则 | 说明 |
|---|---|
| 先给事实再给判断 | 避免显得像先入为主 |
| 只写跟下一阶段判断有关的信息 | 不铺陈无关历史 |
| 问题必须具体 | 不问“你怎么看”，要问“先接业务还是先整结构” |
| 明确表达当前倾向 | 给出你的建议，方便对方校正 |

---

## 4. Current state to include

咨询文本中建议固定包含以下现状：

| 领域 | 当前状态 | 应如何表述 |
|---|---|---|
| Warning artifact | 已完成 | warning unified snapshot 已稳定可消费 |
| Critical artifact | 已完成 | critical payload / thresholds / mirrors 已稳定 |
| Runtime trace payload | 已完成 | warning/critical unified snapshots 已接到 trace payload |
| Critical perturbation hardening | 已完成 | anomaly_scan / perturbation_summary / gate mirrors 已落地 |
| Runner closeout infrastructure | 已完成 | smoke suite、runner 入口规范、delivery archive、backlog tiers 已建立 |
| Full verification | 已通过 | `All 163 test suite(s) passed.` |
| Known tail | 已接受 | `DummyTexture/ObjectDB/resources still in use` 不作为当前交付阻断项 |

---

## 5. Future routes to present

咨询文本里建议直接给出候选路线，不让对方从零替你定义问题。

| 路线 | 内容 | 推荐度 | 理由 |
|---|---|---|---|
| 路线 A | 先接入真实业务战斗逻辑 | **高** | 当前最接近真实价值，且已通过 closeout infrastructure 降低改动风险 |
| 路线 B | 先做更深的结构整顿 | 中 | 长期收益高，但可能再次打断业务推进 |
| 路线 C | 继续做 Critical 精度优化 | 低 | 当前 contract 已可交付，边际收益下降 |
| 路线 D | 继续追资源尾项 | 低 | 已 accepted，不值得抢主线 |

建议在文本里明确写出：**我的默认倾向是先接业务，再按真实接入痛点回收结构债。**

---

## 6. Questions to ask senior engineer

建议问题不要超过 4 个。

| 问题 | 目的 |
|---|---|
| 你是否认同当前阶段已经达到“可交付收口”，下一阶段主线应转向真实业务接入？ | 确认阶段判断 |
| 你会建议在业务接入前，先额外做一轮结构整顿吗？如果要做，范围应控制在哪？ | 确认是否要先修结构 |
| 现在这些技术债里，哪些应该继续冻结在 P2，哪些必须上提到 P1？ | 确认优先级 |
| 如果以“最快验证 V4 真价值”为目标，你会怎么排未来 2-3 个迭代？ | 获取可执行路线 |

---

## 7. Recommended output artifact

产物应是一份可以直接复制给资深工程师的中文文本，而不是面向仓库内部的实施文档。

建议文件：

| 路径 | 作用 |
|---|---|
| `docs/v4_senior_review_consultation_text.md` | 最终可发送咨询文本 |

---

## 8. Success criteria

| 项目 | 验收标准 |
|---|---|
| 可读性 | 对方不需要读代码也能理解当前阶段状态 |
| 聚焦度 | 文本中心是“下一步路线判断”，而不是流水账 |
| 可回答性 | 问题足够具体，能换来明确反馈 |
| 可复用性 | 文本可直接复制到 IM / 邮件 / 文档中发送 |

---

## 9. Recommendation from senior-engineering perspective

这份咨询文本不应只是“请帮我看看项目怎么样”，而应是“这是我们已经完成的边界，这是我看到的 3-4 条下一步路线，这是我当前倾向，请你帮我拍板优先级”。高质量外部反馈来自高质量问题，不来自更长的背景介绍。
