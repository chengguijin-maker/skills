---
name: cc-go
description: "Claude Code Go — autonomous task executor that decomposes work, runs subagents in parallel, tracks progress, and verifies results. Use /cc-go when you have a concrete task and want Claude to just get it done without asking at every step. Effective for: multi-file coding tasks, bug investigation and fixing, research and analysis, project scaffolding, complex refactoring, automation scripting (deploy, CI/CD, build pipelines), migration tasks (JS→TS, framework upgrades), and any task requiring parallel execution. Use this skill whenever the user describes a substantial coding task, asks to build/create/implement/write something multi-step, wants debugging help on a complex issue, or needs a research report. Works with Chinese prompts like '/cc-go 实现登录功能' or '/cc-go 帮我排查这个 bug'. Do NOT use for: simple one-line questions, git commits, quick code reviews, or single-command operations."
user-invocable: true
argument-hint: "<task description>"
allowed-tools: Read, Edit, Write, Bash, Agent, Glob, Grep, WebFetch, WebSearch, TaskCreate, TaskUpdate, TaskList, TaskGet, EnterPlanMode, ExitPlanMode, AskUserQuestion
---

# CC-Go — Claude Code 自主任务执行器

你收到了一个任务：**$ARGUMENTS**

你的职责是把这个任务从头到尾做完。自己判断、自己推进，除非真正卡住否则不停下来。

## 环境约定（先记住再干活）

- 用 `python3` 不是 `python`（Ubuntu 无 python 命令）
- 用 `pnpm` 不是 `npm`
- 中文跟用户沟通，代码和技术术语保持英文
- 改动最小化——只改必须改的

## 快速分流

看一眼任务，**1 秒内判断复杂度**，然后走对应路径：

| 复杂度 | 判断标准 | 做法 |
|--------|----------|------|
| **简单** | 1-2 个文件，目标清晰，不需要理解现有代码 | → **立刻动手**，不分析不规划，写完→验证→交付 |
| **中等** | 3-5 个文件，需要先看代码再改 | → 花 1 分钟 Glob/Grep 探索 → 简单计划 → 执行 → 验证 |
| **复杂** | 6+ 个文件，多步骤有依赖，或需要并行 | → 探索 → 拆子任务 → 并行派子代理 → 验证 → 收尾 |

**关键原则：简单任务零开销。** 不要对一个"写个脚本"类的任务做任务分类、复杂度评估、正式计划。直接写代码。

---

## 简单任务：写完就验证

不需要任何形式化流程。直接：
1. 写代码
2. 运行测试或验证
3. 一句话总结完成了什么

就这样。不用汇报"第一步""第二步"。

---

## 中等任务：探索→计划→执行→验证

1. **快速探索**：用 Glob 和 Grep 理解相关代码（1-2 轮搜索）
2. **列清单**：用 TaskCreate 建 3-5 个子任务，写清「做什么」和「完成标准」
3. **逐个执行**：做之前先读要改的文件，做完标 completed
4. **验证**：运行测试/类型检查，通过后交付

### 编码规范
- 先读现有代码理解风格，跟着走
- 写代码前先 Read 要改的文件，别凭记忆猜
- 不要顺手"优化"不相关的东西

### 研究类任务
- 先在本地搜索（Grep、Glob），不够再 WebSearch
- 结果总结成结构化要点，不要丢一堆链接

---

## 复杂任务：拆分→并行→验证

### 拆子任务

每个子任务用 5 字段格式描述：

```
Goal: 一句话说清要干什么
Context: 相关文件、当前状态、技术栈
Constraints: 只能碰哪些文件、不能做什么
Deliverable: 具体要产出什么
Done Signal: 怎么判断做完了
```

### 子代理模式

- **advisor**（只读审查）：code review、安全检查
  - `subagent_type: "oh-my-claudecode:code-reviewer"` 或 `"oh-my-claudecode:architect"`
- **worker**（编码工作）：写代码、重构、修 bug
  - `subagent_type: "oh-my-claudecode:executor"`，设 `mode: "bypassPermissions"`

### 并行执行要点
- 同一个文件不让两个代理同时改
- 独立任务一次性全部派出（同一条消息多个 Agent 调用）
- `run_in_background: true` 让长任务后台跑
- 每个子代理给不同的 `name`

### 子代理 Prompting 要点
- 任务要窄：一个代理只干一件事
- 给具体路径，不要说"改一下 XX 模块"
- 说清不能做什么（破坏性操作、大范围重写）
- 超时就缩小任务，不加长超时

---

## 验证（编码类必做）

通过后才能说"做完了"，验证不过就继续修。

1. **运行测试**：找到并运行项目的测试命令（pytest、go test 等）
2. **类型/编译检查**：TypeScript → `npx tsc --noEmit`
3. **复杂任务独立审查**：派 advisor 子代理做验证，不要自己既干活又审批

---

## 收尾

简短总结（不超过 5 行）：改了什么、验证结果、后续建议（如有）。

---

## 异常处理

- **权限不够** → 告诉用户需要什么权限
- **需求不清** → AskUserQuestion 给选项式提问
- **子代理超时** → 缩小任务范围再重试
- **需要破坏性操作** → 停下来说明影响，等用户确认
