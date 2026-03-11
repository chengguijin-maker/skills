# 保留完整历史的分支合并约定

## 1. 目标

当用户强调“分支历史要看得清”“后续要审计/回溯”“不要看起来像历史丢了”时，目标不是只保留代码结果，而是同时保留：

- 原主题分支提交链
- 集成分支收口点
- 目标分支接入点

## 2. 默认策略

- 集成阶段优先：`git merge --no-ff <source>`
- 目标分支接入优先：`git merge --no-ff <integ-branch>`
- 公共分支默认避免：`squash merge`、无必要的 `rebase`、`reset --hard`、`push --force`
- 若当前分支只是 `fast-forward` 了历史，但用户后续希望图更直观，可从旧头重建一条“visible/history”分支，再做一次显式 `--no-ff merge`。

## 3. 推荐流程

### 3.1 先做集成验证

```bash
timeout 30s git switch -c integ/<topic> <base>
timeout 30s git merge --no-ff <branch-a> -m "merge(integ/<topic>): integrate <branch-a>"
timeout 30s git merge --no-ff <branch-b> -m "merge(integ/<topic>): integrate <branch-b>"
```

### 3.2 验证通过后接入目标分支

```bash
timeout 30s git switch <target-branch>
timeout 30s git merge --no-ff integ/<topic> -m "merge(<target-branch>): integrate validated <topic> history"
```

### 3.3 关键点打标签

```bash
timeout 30s git tag -a checkpoint/<topic>-before-merge <old-head> -m "before merge"
timeout 30s git tag -a merge/<topic> HEAD -m "integrated <topic> history"
```

## 4. 补救模板

如果已经 `fast-forward`，但用户想“只保留更清楚的那条线”，可用：

```bash
timeout 30s git switch -c <target>-visible <old-head>
timeout 30s git merge --no-ff <current-merged-branch> -m "merge(<target>): integrate validated history"
```

然后比较树对象是否一致：

```bash
timeout 30s git rev-parse <target>-visible^{tree}
timeout 30s git rev-parse <current-target>^{tree}
```

若树对象一致，则说明只是把历史表达方式变清楚，没有改变代码内容。

## 5. 审计命令

```bash
timeout 30s git log --graph --oneline --decorate --all --date-order
timeout 30s git log --first-parent --oneline --decorate <branch>
timeout 30s git show --no-patch --pretty=raw <merge-commit>
timeout 30s git branch --contains <commit>
timeout 30s git reflog <branch>
```

## 6. 明确禁止

- 不要在公共分支上默认使用 `squash merge`
- 不要在未说明影响时改写共享分支历史
- 不要在 worktree 不干净时直接重排关键分支
- 不要只凭 GUI 单视图判断“历史丢了”，先用 DAG 命令核对
