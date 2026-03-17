---
name: idea-spec-execution
description: "[已停用自动触发] 轻量想法→规格→任务拆解工作流（已被 idea-flow 融合替代）。仅在用户显式说 /idea-spec-execution 时触发。原始 description 备份在 idea-flow/references/archived-descriptions.md。"
---

# 轻量想法落地

## Overview

把模糊 idea 收敛成可直接推进实现的轻量交付材料。默认只产出两份核心文档：`problem-frame.md` 与 `spec-and-tasks.md`；只有在任务较多、存在明显并行边界或需要 checkpoint 时，才补 `execution-plan.md`；只有在存在高代价、难以后改的决策时，才补 `critical-decisions.md`。

除非用户另行要求，不要引导回 Kiro 或其它重型 phase 流程；默认保持轻量闭环。

## 典型触发

- “把这个想法整理成需求、设计和实现计划。”
- “给我一版轻量 spec，不要走重型文档流程。”
- “先帮我把问题边界、规格和任务拆出来。”
- “把这个功能从想法推进到可执行任务。”
- “帮我把需求、设计、任务和执行编排一次收口。”
- “别写大而全 PRD，直接给我可落地版本。”

## 默认产物

### 核心文档（始终产出）

- `problem-frame.md`：问题定锚、约束/假设、V1 边界、成功标准。
- `spec-and-tasks.md`：一句话范围、用户流、关键组件/边界、选定方案、sprint、任务清单。

### 按需文档（满足条件才产出）

- `execution-plan.md`：任务 DAG、并行波次、checkpoint、快测方案、停止条件。
- `critical-decisions.md`：高代价决策的备选项、取舍与最终结论。

## 工作流

### 1. 问题定锚

- 先确认正在解决的是“问题”，不是先入为主的“方案”。
- 明确：谁在什么场景下遇到问题、当前如何凑合、为什么现在值得做。
- 分开写：`Constraints` 与 `Assumptions`，不要混写。
- 先识别难以后改的关键决策，再决定哪些必须现在拍板。
- 对非阻塞未知项做保守假设，不为小问题反复停下。

### 2. 规格收口

- 用一句话定义范围；若一句话都说不清，说明问题还没收口。
- 将方案压缩为 `<=9` 个主要部分；超出说明范围过大或拆分不当。
- 只对高影响分歧做 `2~3` 个方案对比；不要为所有细节做比稿。
- 明确主要用户流、关键边界、依赖与验证策略。
- 保持规格薄：能指导实现即可，不要膨胀成长篇背景说明。

### 3. 任务塑形

- 先按可演示（demoable）的 sprint 切片，而不是按技术层机械分组。
- 每个任务必须原子化、可独立提交、可独立 review。
- 每个任务必须写清 `Validation` 与 `Done Signal`。
- 任务描述用动词开头，尽量短，不要夹带无关工作。
- 默认把“顺手做一下”“后面再看”类内容放进 deferred，而不是混进当前任务。

### 4. 执行编排（按需）

仅在满足以下任一条件时补 `execution-plan.md`：

- 任务数 `> 5`
- 明显存在可并行任务
- 需要多 worktree / 多 agent / 多 checkpoint
- 需要显式依赖图，否则执行顺序容易混乱

生成执行编排时：

- 为每个任务声明 `depends_on`、`owner_scope`、`validation_command`、`done_signal`。
- 先排无依赖任务，再排集成与回归任务。
- 写清 checkpoint：已完成输出、验证结果、当前阻塞、下一步边界动作。
- 所有命令默认加 timeout；优先设计最短、最有证明力的快测。

## 默认规则

- 先问题，后方案。
- 少问，先做保守假设。
- 只对关键分歧做方案比选。
- 规格必须薄，任务必须实。
- 每个任务都要可验证、可完成、可交付。
- 不升级到重型阶段文档；保持轻量闭环即可。

## 何时读取附加资料

- 读取 `references/artifact-templates.md` 获取四份文档的标准模板与字段要求。
- 读取 `references/decision-rules.md` 获取问题定锚、关键决策、任务粒度和执行编排的判定规则。
- 读取 `references/example-topic.md` 获取一份完整中文示例，帮助快速理解输出长相与粒度。
- 需要快速起目录与模板文件时，运行 `scripts/init_light_spec.py`。

## 脚本

- 初始化 topic 目录：
  - `python3 scripts/init_light_spec.py --topic <slug>`
  - `python3 scripts/init_light_spec.py --topic <slug> --title "中文标题" --base-dir docs/light-specs`
- 若本轮已经明确需要可选文档：
  - `python3 scripts/init_light_spec.py --topic <slug> --include-optional`

## 参考资料

- `references/artifact-templates.md`
- `references/decision-rules.md`
- `references/example-topic.md`
