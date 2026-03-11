# 项目启动检查表

## 1. 仓库盘点

- 检查是否已是 git 仓库：`git rev-parse --is-inside-work-tree`
- 检查当前分支与 worktree：`git branch --show-current`、`git worktree list`
- 确认用户是否指定了 `worktree` 根目录；若无额外说明，默认使用 `~/.psm/worktrees`
- 若 `~/.psm/worktrees` 不存在，先执行 `mkdir -p ~/.psm/worktrees`
- 扫描约束与设计资料：`AGENTS.md`、`.kiro/`、`docs/`、`README*`
- 扫描项目类型：`pyproject.toml`、`package.json`、`go.mod`、`Cargo.toml`
- 扫描测试入口：`tests/`、`scripts/run_tests.*`、`docs/TESTING.*`

## 2. git 基线

### 若尚未初始化 git

1. 建 `main`
2. 补最小 `.gitignore`
3. 提交基线快照

### 若已经有 git

1. 不要先动历史
2. 先看 `git status --short`
3. 先看 `git log --oneline --decorate -n 20`
4. 再决定是否拆分主题分支

## 3. 分支治理

- 默认：`main` + `feat/*` + `worktree`
- 默认：新的 `worktree` 落在指定根目录；若未指定，则固定使用 `~/.psm/worktrees`
- 重构单开 `refactor/*`
- 性能单开 `perf/*`
- 文档单开 `docs/*`
- 探索性验证单开 `spike/*`

## 4. 快测策略

- 所有命令默认加 `timeout`
- 先最小单测，再局部集成，再小范围回归
- 只测本轮变更真正触达的路径
- 长测、全量测放到最后

## 5. 建议输出结构

| 编号 | 事项 | 结果 |
|---|---|---|
| 1 | 当前仓库状态 | 已/未纳入 git，主分支情况 |
| 2 | 关键约束 | AGENTS、设计文档、环境约束 |
| 3 | 代码与文档差距 | 已实现 / 未实现 |
| 4 | 分支策略 | 建议的分支与 worktree 分布 |
| 5 | 测试策略 | 本轮先跑哪些快测 |
| 6 | 下一步 | 下一笔原子改动 |
