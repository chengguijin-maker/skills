# Stacked Branches 与 Worktree 约定

## 1. 适用场景

当你已经有一串按主题递进的提交，且希望：

- 一功能一分支
- 一分支一 worktree
- 后续按顺序评审或合并

就把提交链整理成 stacked branches。

## 2. 推荐命名

- `feat/output-top-bottom`
- `feat/output-depth-map-video`
- `feat/output-audio-copy`
- `feat/output-manifest`
- `refactor/pipeline-layout-export`
- `feat/apple-spatial-bridge`

## 3. worktree 根目录与命名

- 先确认用户是否指定了 `worktree` 根目录；如果没有额外说明，默认统一使用 `~/.psm/worktrees`。
- 如果用户指定了其它目录，所有新 `worktree` 都必须落在该绝对路径下。
- 不要把 `worktree` 建在仓库内部的嵌套目录、随机家目录、`/tmp` 或其它临时位置，除非用户明确要求。

- `~/.psm/worktrees/repo-wt-output-top-bottom`
- `~/.psm/worktrees/repo-wt-output-depth-map-video`
- `~/.psm/worktrees/repo-wt-output-audio-copy`
- `~/.psm/worktrees/repo-wt-output-manifest`
- `~/.psm/worktrees/edit-mind-fix`

保持“一个分支对应一个 worktree”的单射关系。

## 4. 重排步骤

1. 先确认提交链顺序：`git log --oneline --decorate`
2. 把最顶层泛化分支重命名成最后一个主题分支
3. 以各主题提交点创建分支指针
4. 为每个分支创建独立 worktree
   - 若目录不存在，先执行：`mkdir -p ~/.psm/worktrees`
   - 示例：`git worktree add ~/.psm/worktrees/edit-mind-fix fix/audit-p0`
5. 验证拓扑：`git log --graph --oneline --decorate --all --simplify-by-decoration`
6. 验证所有 worktree 干净：`git status --short`

## 5. 合并顺序

- 最底层功能先合并
- 上层分支再依次 rebase 或更新基底
- 永远不要跨层把上层能力直接压回 `main`

## 6. 不要这样做

- 不要把功能、重构、性能混到一个分支
- 不要让一个 worktree 频繁切不同分支
- 不要在工作树不干净时大规模重排分支
