# AGENTS

## 项目信息

- 项目：DevNotes - 本地优先个人知识库
- UID：PRJ-20260316-001
- 主控文件：WORK.md
- 语言：Rust
- 构建：cargo build / cargo test

## 工作规则

- 单文件优先
- 主控文件是WORK.md
- 先写非目标
- 先查旧调研
- 结论回填主文件
- 临时材料进scratch
- 有价值再归archive
- 吸收后删除草稿
- 一任务一worktree
- 小步频繁提交
- 验证点必须落表
- 风险必须显式写
- 决策写入ADR-lite
- 状态持续更新

## 技术约束

- Rust edition 2021，MSRV 1.75
- 使用 clap derive 模式定义 CLI
- 笔记文件必须是合法 Markdown，frontmatter 用 YAML
- 搜索索引存储在 .devnotes/ 目录下
- TUI 用 feature flag 控制，默认不编译
- 所有 pub 函数写文档注释
- 错误处理用 thiserror 定义领域错误，对外用 anyhow

## 代码风格

- `cargo fmt` 强制格式化
- `cargo clippy` 零警告
- 模块按 cli / core / storage / index / search / tui / config 划分
- 测试与源码同目录（mod tests），集成测试放 tests/

## 去重规则

- 同题先查RES表
- 同题优先更新原行
- 同源优先复用摘要
- 冲突结论必须标记
- 低价值材料不留

## 拆分规则

- 非必要不拆文件
- 拆分后主文件保索引
- 子文件顶部写回链
- 子文件继承项目UID
- 必须说明拆分原因

## worktree 规则

- 禁止直改主分支
- 分支只做一个目标
- 验证后尽快合并
- 合并后删除worktree

## 归档规则

- 可复查才归档
- 高成本材料可归档
- 决策证据可归档
- 已吸收材料不归档
- 过期草稿直接删除
