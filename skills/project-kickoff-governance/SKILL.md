---
name: project-kickoff-governance
description: 在接手新仓库、陌生项目或准备开始大改动前，执行标准化项目启动治理：盘点 AGENTS、设计文档、测试约束与真实实现，初始化或修复 git 基线，建立 main 加短命主题分支或 stacked branches 与 worktree 结构，规划带 timeout 的快测策略，并输出结构化汇总与下一步计划。用于“先分析项目”“先把 git 和 worktree 建好”“按优秀实践拆原子提交”“整理分支策略”“为后续改动建立快测与提交规范”等请求。
---

# Project Kickoff Governance

## Overview

在真正写业务代码前，先把仓库、分支、测试、文档和改动边界治理好。默认目标是：主干干净、分支短命、提交原子、测试快速、结论结构化。

## 典型触发

- “重新分析这个项目，先把 git 和 worktree 建好。”
- “接手一个新仓库，先按优秀实践整理分支和测试策略。”
- “继续做功能前，先把提交拆原子、分支拆干净。”
- “这个项目一开始都要做哪些标准化处理？”

## 工作流

### 1. 盘点仓库与约束

- 检查 `git` 状态、当前分支、已有 `worktree`、未提交改动。
- 先确认是否存在用户或环境约定的 `worktree` 根目录；若无额外说明，默认根目录为 `~/.psm/worktrees`。
- 盘点 `AGENTS.md`、`.kiro/`、`docs/`、`README*`、构建清单和测试入口。
- 对照文档承诺与当前实现，先找“真实能力”和“口径偏差”。
- 若项目范围过大，先收敛 MVP 边界，再讨论后续能力。

### 2. 稳定 git 基线

- 若仓库还未纳入 git：初始化 `main`、补最小 `.gitignore`、提交基线快照。
- 若仓库已有 git：先保留现状，不重写历史；只在边界清晰时整理分支。
- 任何批量操作前先确认工作树干净，或明确哪些文件是本轮改动。

### 3. 选择分支策略

- 默认使用 `Trunk-Based + 短命主题分支 + worktree`。
- 若用户已规定 `worktree` 存放根目录，严格沿用该根目录；否则默认使用 `~/.psm/worktrees`。
- 不要把新的 `worktree` 随意放到仓库内、`/tmp`、当前项目旁边的临时目录或其它未约定位置。
- 若 `~/.psm/worktrees` 不存在，先创建它，再在其下为具体分支创建独立目录。
- 一功能一分支：`feat/*`、`fix/*`、`refactor/*`、`perf/*`、`docs/*`、`spike/*`。
- 若已经形成按提交串起来的能力链，把它整理成 stacked branches。
- 不把功能、重构、性能、文档混在同一分支里。
- 若用户明确要求“完整历史可见”或后续需要审计/回溯，默认在集成分支和目标分支上都使用 `merge --no-ff`，不要只做 `fast-forward`。
- 公共分支默认避免 `squash merge`、避免随意 `rebase`；若必须重写历史，先说明影响并保留可回退锚点。
- 对关键集成点，优先保留 `integ/*` 分支、或额外打 `tag`/检查点，避免分支标签移动后“看起来像历史丢了”。
- 合并完成后，至少核对一次 `git show --no-patch --pretty=raw <merge-commit>` 与 `git log --graph --oneline --decorate --all`，确认双亲和拓扑都还在。
- 需要分支命名、worktree 命名、历史保留合并模板和验证命令时，读取 `references/stacked-branches.md` 与 `references/merge-history-preservation.md`。

### 4. 设计快测策略

- 只选最短、最能证明正确性的测试。
- 所有命令都加 timeout，避免卡死和无意义等待。
- 先跑 unit 或 smoke，再跑针对性 integration，最后才扩大回归范围。
- 不通过降低门槛、篡改用例来换“假通过”。
- 需要启动检查表与测试策略时，读取 `references/startup-checklist.md`。

### 5. 结构化输出与落地

- 先给汇总表，再给详细说明。
- 明确列出：现状、风险、建议路线、改动边界、测试范围、下一步。
- 每完成一个独立主题就立即提交，保持历史原子化。
- 若流程可复用，把结果沉淀为文档、脚本或 skill。

## 默认原则

- `main` 只保留可运行、可回归、可继续开发的基线。
- 一个活跃主题对应一个分支和一个 worktree。
- `worktree` 默认服从指定根目录约束；若无额外说明，固定使用 `~/.psm/worktrees`。
- 若需要 PR，合并顺序按 stacked chain 从底到顶。
- 项目起步优先治理结构，再进入具体功能实现。

## 参考资料

- 读取 `references/startup-checklist.md` 获取项目启动检查表、命令模板和快测节奏。
- 读取 `references/stacked-branches.md` 获取 stacked branches 与 worktree 的命名、拆分和验证方法。
- 读取 `references/merge-history-preservation.md` 获取保留完整历史的 merge 策略、命令模板和审计命令。
