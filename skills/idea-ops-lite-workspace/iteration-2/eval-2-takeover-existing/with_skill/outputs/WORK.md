# CLI 知识库工具

- 项目 UID：PRJ-20260316-001
- 当前状态：frame
- 负责人：-
- 仓库路径：/tmp/test-idea-ops-2
- 当前分支：-
- 当前 worktree：-
- 最后更新：2026-03-16

## 1. Idea

### 1.1 一句话想法

做一个 Rust CLI 知识库工具，面向开发者，用终端管理 markdown 笔记，支持全文搜索和标签。

### 1.2 背景

- 现有工具（如 Obsidian）功能强大但过重，开发者更习惯终端工作流
- 需要本地优先、零配置、单文件存储的轻量方案
- 开发者日常知识管理缺少一个够用的 CLI 工具

### 1.3 成功信号

- 能通过 CLI 创建、编辑、搜索 markdown 笔记
- 全文搜索响应 < 100ms（万级笔记）
- 标签过滤和管理可用
- 单二进制分发，零外部依赖

## 2. 术语表

| ID | 术语 | 解释 | 备注 |
|---|---|---|---|
| TERM-001 | NoteStore | 笔记存储核心 trait，定义 CRUD + 搜索 + 标签接口 | 见 src/api-draft.rs |
| TERM-002 | FTS5 | SQLite 全文搜索扩展 | 用于实现全文搜索 |
| TERM-003 | tantivy | Rust 全文搜索引擎库 | 备选方案，notes.md 提及 |

## 3. 调研登记表

| ID | 主题 | 问题 | 结论 | 证据路径/来源 | 上次检查 | 重查条件 | 复用说明 |
|---|---|---|---|---|---|---|---|
| RES-001 | 数据库选型 | SQLite vs PostgreSQL 哪个适合本地知识库 | 选 SQLite：本地优先、单文件、FTS5 全文搜索、嵌入式零配置 | archive/research-db.md | 2026-03-10 | 需求变为多用户/服务端时重查 | 直接复用，结论稳定 |
| RES-002 | 全文搜索方案 | tantivy vs SQLite FTS5 | 待调研 | - | 2026-03-16 | 性能测试后 | 与 RES-001 相关但层次不同：RES-001 是存储选型，RES-002 是搜索引擎选型 |

## 4. 目标与非目标

### 4.1 目标

| ID | 目标 | 衡量方式 | 优先级 |
|---|---|---|---|
| G-001 | Markdown 笔记 CRUD | CLI 命令可创建/读取/更新/删除笔记 | p1 |
| G-002 | 全文搜索 | 万级笔记搜索 < 100ms | p1 |
| G-003 | 标签管理 | 支持标签增删、按标签过滤 | p1 |
| G-004 | 本地存储优先 | 单文件 SQLite，零外部依赖 | p1 |

### 4.2 非目标

| ID | 非目标 | 不做原因 |
|---|---|---|
| NG-001 | GUI 界面 | 面向终端用户，GUI 增加复杂度 |
| NG-002 | 云同步 | 本地优先原则，同步可后期插件化 |
| NG-003 | LSP 支持 | notes.md 提及但优先级低，属后续增强 |
| NG-004 | 多用户并发 | 个人工具，不需要服务端架构 |

## 5. 范围图

| ID | 类型 | 摘要 | 输入 | 输出 | 负责人 | 状态 | 依赖 |
|---|---|---|---|---|---|---|---|
| REQ-001 | feature | 笔记 CRUD 操作 | CLI 命令 + 参数 | 笔记数据 | - | todo | - |
| REQ-002 | feature | 全文搜索 | 搜索关键词 | 匹配笔记列表 | - | todo | REQ-001 |
| REQ-003 | feature | 标签管理 | 标签名 | 标签列表 / 过滤结果 | - | todo | REQ-001 |
| REQ-004 | infra | SQLite 存储层 | Note 结构体 | 持久化数据 | - | todo | - |
| REQ-005 | feature | Markdown 编辑集成 | 笔记 ID | 打开 $EDITOR | - | todo | REQ-001 |

## 6. 架构与边界

### 6.1 模块

| ID | 模块 | 职责 | 边界 | 备注 |
|---|---|---|---|---|
| MOD-001 | cli | 解析命令行参数，路由到对应操作 | 只做参数解析和输出格式化 | clap |
| MOD-002 | core | 业务逻辑：NoteStore trait 及实现 | 不直接操作 DB | 见 api-draft.rs |
| MOD-003 | storage | SQLite 存储实现 | 只暴露 NoteStore trait | rusqlite |
| MOD-004 | search | 全文搜索引擎 | 可切换 FTS5/tantivy | 待 RES-002 |

### 6.2 接口

| ID | 方向 | 契约 | 异常规则 | 备注 |
|---|---|---|---|---|
| IF-001 | cli → core | NoteStore trait（CRUD + search + tags） | 返回 Result 类型 | 见 src/api-draft.rs |
| IF-002 | core → storage | NoteStore trait 实现 | DB 错误统一包装 | - |

### 6.3 交互时序

1. 用户输入 CLI 命令
2. cli 模块解析参数，调用 core 对应方法
3. core 通过 NoteStore trait 操作 storage
4. storage 执行 SQLite 操作，返回结果
5. cli 格式化输出到终端

### 6.4 关键限制

- 单进程单用户，不考虑并发锁
- SQLite 单文件，路径可配置（默认 ~/.knowledgebase/notes.db）

## 7. 技术栈与方案概述

| 领域 | 选择 | 原因 | 备选 |
|---|---|---|---|
| 语言 | Rust | 高性能、单二进制分发 | - |
| 存储 | SQLite (rusqlite) | 本地优先、FTS5、零配置 | sled |
| 全文搜索 | SQLite FTS5 / tantivy | 待 RES-002 调研确定 | - |
| CLI 框架 | clap | Rust 生态标准 | - |
| 序列化 | serde | Rust 生态标准 | - |

## 8. 实施计划

### 8.1 里程碑

| ID | 里程碑 | 交付物 | 验证方式 | 状态 |
|---|---|---|---|---|
| M-001 | 存储层 + CRUD | SQLite 存储 + NoteStore 实现 | 单元测试 | todo |
| M-002 | CLI 框架 | 命令行接口可用 | 集成测试 | todo |
| M-003 | 全文搜索 | 搜索功能可用 | 性能测试 < 100ms | todo |
| M-004 | 标签管理 | 标签 CRUD + 过滤 | 功能测试 | todo |

### 8.2 任务拆解

| ID | 里程碑 | 任务 | worktree | 负责人 | 验证点 | 状态 |
|---|---|---|---|---|---|---|
| TSK-001 | M-001 | 定义 Note 结构体和 NoteStore trait | - | - | VAL-001 | todo |
| TSK-002 | M-001 | 实现 SQLite 存储层 | - | - | VAL-002 | todo |
| TSK-003 | M-002 | 搭建 clap CLI 框架 | - | - | VAL-003 | todo |
| TSK-004 | M-003 | 集成全文搜索 | - | - | VAL-004 | todo |
| TSK-005 | M-004 | 实现标签管理 | - | - | VAL-005 | todo |

### 8.3 并行泳道

- lane a：存储层（TSK-001 → TSK-002）
- lane b：CLI 框架（TSK-003，与 lane a 可并行）

## 9. 风险与应对

| ID | 风险 | 触发条件 | 影响 | 应对 | 状态 |
|---|---|---|---|---|---|
| RSK-001 | FTS5 中文分词效果差 | 中文笔记搜索不准 | 搜索体验差 | 考虑 jieba-rs 分词 + tantivy 替代 | open |
| RSK-002 | SQLite 大量笔记性能下降 | 笔记数超 10 万 | CRUD 变慢 | 加索引、分页查询、惰性加载 | open |

## 10. ADR-lite

| ID | 决策 | 原因 | 取舍 | 日期 |
|---|---|---|---|---|
| ADR-001 | 存储选 SQLite 而非 PostgreSQL | 本地优先、零配置、单文件便携、FTS5 内置 | 牺牲多用户并发能力（非目标 NG-004） | 2026-03-10 |
| ADR-002 | 接管现有项目，不重建仓库 | 已有 API 草稿和调研材料可复用 | 需额外整理分类工作 | 2026-03-16 |

## 11. 实施记录

| 时间 | 变更 | 提交 | 验证 | 备注 |
|---|---|---|---|---|
| 2026-03-16 | idea-ops-lite 接管项目 | - | - | 从散乱文件收敛到 WORK.md |
| 2026-03-16 | 吸收 notes.md 到 Idea/目标/范围 | - | - | notes.md 内容已全部吸收，原文件移至 scratch/ 待删 |
| 2026-03-16 | 吸收 research-db.md 到调研表/ADR | - | - | 调研结论已入 RES-001 + ADR-001，原文件归档 archive/ |
| 2026-03-16 | 登记 api-draft.rs 到材料表 | - | - | 接口设计有独立价值，移至 src/ |
| 2026-03-16 | RES-002 与 RES-001 去重判定 | - | - | 问题层次不同：RES-001 是存储选型，RES-002 是搜索引擎选型，保留为独立条目 |

## 12. 验证表

| ID | 检查项 | 方法 | 结果 | 状态 |
|---|---|---|---|---|
| VAL-001 | Note 结构体和 NoteStore trait 编译通过 | cargo check | - | todo |
| VAL-002 | SQLite CRUD 单元测试通过 | cargo test | - | todo |
| VAL-003 | CLI 命令解析正确 | 集成测试 | - | todo |
| VAL-004 | 全文搜索性能 < 100ms | 基准测试 | - | todo |
| VAL-005 | 标签过滤功能正确 | 功能测试 | - | todo |

## 13. 当前状态报告

- 总体：yellow
- 已完成：材料收敛、调研吸收、项目骨架建立
- 进行中：-
- 下一步：完成 RES-002 全文搜索方案调研，然后启动 M-001 存储层开发
- 阻塞项：无
- 待决策：全文搜索方案（FTS5 vs tantivy）

## 14. 材料登记表

| ID | 类型 | 路径 | 来源区块 | 保留规则 | 状态 | 删除条件 |
|---|---|---|---|---|---|---|
| ART-001 | scratch | scratch/notes.md | 1. Idea / 4. 目标 / 5. 范围 | 吸收后删 | absorbed | 已全部吸收到 WORK.md |
| ART-002 | archive | archive/research-db.md | 3. 调研登记表 RES-001 | 支撑 ADR-001，保留 | live | ADR-001 被推翻时 |
| ART-003 | src | src/api-draft.rs | 6. 架构 IF-001 | 有独立设计价值 | live | 被正式实现替代时 |

## 15. 归档与删除记录

| 日期 | 材料 | 动作 | 原因 |
|---|---|---|---|
| 2026-03-16 | notes.md → scratch/notes.md | move | 内容已吸收到 WORK.md，暂存 scratch 待确认删除 |
| 2026-03-16 | research-db.md → archive/research-db.md | archive | 支撑 ADR-001 决策，有复查价值 |
| 2026-03-16 | api-draft.rs → src/api-draft.rs | move | 接口设计有独立价值，归入 src |
