# CLI 笔记工具（Rust）

- 项目 UID：PRJ-20260316-001
- 当前状态：frame
- 负责人：-
- 仓库路径：/tmp/test-idea-ops-2
- 当前分支：-
- 当前 worktree：-
- 最后更新：2026-03-16

## 1. Idea

### 1.1 一句话想法

用 Rust 构建一个高性能 CLI 笔记工具，使用 SQLite 存储，支持全文搜索和标签系统。

### 1.2 背景

参考了 nb、joplin、obsidian 等现有笔记工具，希望做一个更轻量、命令行原生的方案。Rust 保证性能，SQLite 单文件部署简化使用。

### 1.3 成功信号

- 能通过命令行完成笔记的增删改查
- 全文搜索响应时间 <100ms（千条笔记规模）
- 标签系统支持多对多关联和筛选

## 2. 术语表

| ID | 术语 | 解释 | 备注 |
|---|---|---|---|
| TERM-001 | NoteStore | 笔记存储层 trait，定义 CRUD 与搜索接口 | 见 api-draft.rs |
| TERM-002 | FTS5 | SQLite 全文搜索扩展 | 用于实现搜索命令 |
| TERM-003 | front matter | Markdown 文件头部的元数据块（YAML 格式） | 需解析以提取标签等信息 |

## 3. 调研登记表

| ID | 主题 | 问题 | 结论 | 证据路径/来源 | 上次检查 | 重查条件 | 复用说明 |
|---|---|---|---|---|---|---|---|
| RES-001 | 嵌入式数据库选型 | SQLite vs LevelDB vs Sled 哪个适合单用户 CLI 笔记工具？ | 选 SQLite：成熟、FTS5 全文搜索、单文件部署；LevelDB 无 SQL 查询不灵活；Sled API 不稳定社区小 | archive/research-db.md | 2026-03-16 | Sled 发布 1.0 稳定版；或需要高写并发场景 | 存储层选型直接复用此结论 |

## 4. 目标与非目标

### 4.1 目标

| ID | 目标 | 衡量方式 | 优先级 |
|---|---|---|---|
| G-001 | CLI 笔记增删改查 | 能通过命令行完成 create/get/delete 操作 | p1 |
| G-002 | 全文搜索 | search 命令返回匹配结果，基于 SQLite FTS5 | p1 |
| G-003 | 标签系统 | 支持标签 CRUD，多对多关系表实现 | p1 |
| G-004 | Markdown front matter 解析 | 自动解析笔记头部元数据 | p2 |
| G-005 | 导入导出 | 支持批量导入导出笔记 | p2 |

### 4.2 非目标

| ID | 非目标 | 不做原因 |
|---|---|---|
| NG-001 | GUI 界面 | 定位为 CLI 工具，保持轻量 |
| NG-002 | 多用户/云同步 | 单用户场景，SQLite 写并发限制可接受 |
| NG-003 | 实时协作编辑 | 超出 CLI 笔记工具范围 |

## 5. 范围图

| ID | 类型 | 摘要 | 输入 | 输出 | 负责人 | 状态 | 依赖 |
|---|---|---|---|---|---|---|---|
| REQ-001 | feature | 笔记 CRUD 命令 | CLI 参数 | 操作结果 | - | todo | - |
| REQ-002 | feature | 全文搜索命令 | 搜索关键词 | 匹配笔记列表 | - | todo | REQ-001 |
| REQ-003 | feature | 标签 CRUD | CLI 参数 | 标签列表/操作结果 | - | todo | REQ-001 |
| REQ-004 | feature | Markdown front matter 解析 | .md 文件 | 结构化元数据 | - | todo | - |
| REQ-005 | feature | 导入导出 | 文件/目录路径 | 导出文件/导入结果 | - | todo | REQ-001 |

## 6. 架构与边界

### 6.1 模块

| ID | 模块 | 职责 | 边界 | 备注 |
|---|---|---|---|---|
| MOD-001 | cli | 命令行参数解析与路由 | 只负责解析输入、调用 store、格式化输出 | 可用 clap |
| MOD-002 | store | 数据存储层（NoteStore trait） | 只负责数据持久化和查询，不含业务逻辑 | 见 api-draft.rs |
| MOD-003 | search | 全文搜索 | 基于 SQLite FTS5，由 store 模块内部实现 | - |
| MOD-004 | parser | Markdown front matter 解析 | 只负责解析，不存储 | - |

### 6.2 接口

| ID | 方向 | 契约 | 异常规则 | 备注 |
|---|---|---|---|---|
| IF-001 | cli -> store | NoteStore trait（create/get/search/list_tags/delete） | 所有方法返回 Result 类型 | 见 src/api-draft.rs |

### 6.3 交互时序

1. 用户输入 CLI 命令 -> cli 模块解析参数
2. cli 调用 NoteStore trait 对应方法
3. store 模块操作 SQLite 数据库，返回 Result

### 6.4 关键限制

- 单用户场景，不考虑写并发
- SQLite 单文件，数据库路径可配置

## 7. 技术栈与方案概述

| 领域 | 选择 | 原因 | 备选 |
|---|---|---|---|
| 语言 | Rust | 性能好、安全 | - |
| 存储 | SQLite + FTS5 | 成熟、单文件、全文搜索 | LevelDB, Sled |
| CLI 框架 | clap（待定） | Rust 生态主流 CLI 框架 | structopt |
| SQLite 绑定 | rusqlite（待定） | Rust SQLite 绑定主流选择 | diesel |

## 8. 实施计划

### 8.1 里程碑

| ID | 里程碑 | 交付物 | 验证方式 | 状态 |
|---|---|---|---|---|
| M-001 | 存储层基础 | NoteStore trait + SQLite 实现 | 单元测试 CRUD | todo |
| M-002 | CLI 基础命令 | create/get/delete 命令可用 | 手动测试 CLI | todo |
| M-003 | 搜索与标签 | search 命令 + 标签 CRUD | 搜索准确性测试 | todo |
| M-004 | 解析与导入导出 | front matter 解析 + 导入导出 | 导入导出往返测试 | todo |

### 8.2 任务拆解

| ID | 里程碑 | 任务 | worktree | 负责人 | 验证点 | 状态 |
|---|---|---|---|---|---|---|
| TSK-001 | M-001 | 定义 NoteStore trait 和数据结构 | - | - | VAL-001 | todo |
| TSK-002 | M-001 | 实现 SQLite 后端 | - | - | VAL-002 | todo |
| TSK-003 | M-002 | 实现 CLI 命令路由 | - | - | VAL-003 | todo |
| TSK-004 | M-003 | 实现全文搜索 | - | - | VAL-004 | todo |
| TSK-005 | M-003 | 实现标签 CRUD | - | - | VAL-005 | todo |
| TSK-006 | M-004 | 实现 front matter 解析 | - | - | VAL-006 | todo |
| TSK-007 | M-004 | 实现导入导出 | - | - | VAL-007 | todo |

### 8.3 并行泳道

- lane a：存储层 + 搜索（TSK-001 -> TSK-002 -> TSK-004）
- lane b：CLI + 标签（TSK-003 -> TSK-005）

## 9. 风险与应对

| ID | 风险 | 触发条件 | 影响 | 应对 | 状态 |
|---|---|---|---|---|---|
| RSK-001 | FTS5 中文分词效果差 | 用中文内容测试搜索 | 搜索体验差 | 调研 jieba-rs 或 cang-jie 分词方案 | open |
| RSK-002 | rusqlite 编译复杂 | 交叉编译或 bundled 模式 | 构建困难 | 使用 bundled feature flag | open |

## 10. ADR-lite

| ID | 决策 | 原因 | 取舍 | 日期 |
|---|---|---|---|---|
| ADR-001 | 选择 SQLite 作为存储引擎 | 成熟、FTS5 全文搜索、单文件部署简单 | 放弃 Sled 原生 Rust 优势和 LevelDB 高写入性能 | 2026-03-05 |

## 11. 实施记录

| 时间 | 变更 | 提交 | 验证 | 备注 |
|---|---|---|---|---|
| 2026-03-01 | 项目启动，确定用 Rust 写 CLI 笔记工具 | - | - | 参考 nb/joplin/obsidian |
| 2026-03-05 | 数据库选型完成，选定 SQLite | - | - | 详见 RES-001 |
| 2026-03-16 | idea-ops-lite 接管，整理现有材料 | - | - | 材料分类归档 |

## 12. 验证表

| ID | 检查项 | 方法 | 结果 | 状态 |
|---|---|---|---|---|
| VAL-001 | NoteStore trait 定义完整 | 代码审查 | - | todo |
| VAL-002 | SQLite CRUD 正确 | 单元测试 | - | todo |
| VAL-003 | CLI 命令解析正确 | 手动测试 | - | todo |
| VAL-004 | 全文搜索返回正确结果 | 测试用例 | - | todo |
| VAL-005 | 标签多对多关系正确 | 单元测试 | - | todo |
| VAL-006 | front matter 解析正确 | 测试用例 | - | todo |
| VAL-007 | 导入导出往返一致 | 往返测试 | - | todo |

## 13. 当前状态报告

- 总体：yellow
- 已完成：idea 收集、数据库选型调研、API trait 草稿
- 进行中：材料整理与归档（idea-ops-lite 接管）
- 下一步：确认技术栈（clap/rusqlite），开始 TSK-001 实现 NoteStore trait
- 阻塞项：无
- 待决策：CLI 框架选择（clap vs structopt），SQLite 绑定选择（rusqlite vs diesel）

## 14. 材料登记表

| ID | 类型 | 路径 | 来源区块 | 保留规则 | 状态 | 删除条件 |
|---|---|---|---|---|---|---|
| ART-001 | scratch | scratch/notes.md | 1. Idea, 8. 实施计划 | 吸收后删 | absorbed | 已吸收到 WORK.md 各区块 |
| ART-002 | archive | archive/research-db.md | 3. 调研登记表 | 长期保留 | live | RES-001 结论被推翻或不再需要 |
| ART-003 | src | src/api-draft.rs | 6. 架构与边界 | 迭代演进 | live | 正式实现后替换 |

## 15. 归档与删除记录

| 日期 | 材料 | 动作 | 原因 |
|---|---|---|---|
| 2026-03-16 | notes.md | move -> scratch/ + absorb | 内容已吸收到 WORK.md 各区块，原文保留在 scratch/ 供参照 |
| 2026-03-16 | research-db.md | move -> archive/ | 有价值的选型调研，支撑 ADR-001 决策，未来可能复查 |
| 2026-03-16 | api-draft.rs | move -> src/ | API 设计草稿，后续迭代演进为正式实现 |
