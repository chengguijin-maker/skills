# DevNotes - 本地优先个人知识库

- 项目 UID：PRJ-20260316-001
- 当前状态：scope
- 负责人：developer
- 仓库路径：/tmp/test-idea-ops-1
- 当前分支：main
- 当前 worktree：/tmp/test-idea-ops-1
- 最后更新：2026-03-16

## 1. Idea

### 1.1 一句话想法

一个本地优先、终端原生的个人知识库工具，支持 Markdown 编辑、全文搜索和标签管理，专为开发者设计。

### 1.2 背景

开发者日常需要记录大量技术笔记：代码片段、调试记录、学习笔记、方案对比等。现有工具存在以下痛点：

- **云端依赖**：Notion、语雀等需要网络，数据不在本地，迁移困难
- **离开终端**：大多数笔记工具需要切换到浏览器或 GUI，打断开发流程
- **格式锁定**：部分工具使用私有格式，不兼容 Markdown 生态
- **搜索不够快**：文件系统级的 grep 缺乏结构化搜索（按标签、按时间、按关联）
- **组织困难**：纯文件夹管理缺乏标签、反向链接等知识组织能力

DevNotes 的定位是做一个「开发者的第二大脑」，数据全部是本地 Markdown 文件，操作全部在终端完成，搜索快如 ripgrep，组织靠标签而非文件夹。

### 1.3 成功信号

- 开发者可以在 3 秒内从终端创建一条新笔记
- 全文搜索 10000 条笔记在 200ms 内返回结果
- 标签筛选和组合查询流畅可用
- 笔记文件是标准 Markdown，可被任何编辑器打开
- 无需网络即可完整使用

## 2. 术语表

| ID | 术语 | 解释 | 备注 |
|---|---|---|---|
| TERM-001 | Note | 一条知识记录，对应磁盘上一个 .md 文件 | 最小管理单元 |
| TERM-002 | Vault | 笔记库根目录，包含所有 Note 和索引数据 | 类似 Obsidian vault |
| TERM-003 | Tag | 标签，以 `#tag` 格式内嵌在 Note 的 frontmatter 或正文中 | 支持层级如 `#lang/rust` |
| TERM-004 | Frontmatter | Note 文件头部的 YAML 元数据块 | 存储 title、tags、created、updated |
| TERM-005 | Index | 本地搜索索引文件，加速全文搜索和标签查询 | 存储在 `.devnotes/` 下 |
| TERM-006 | TUI | 终端用户界面，提供交互式浏览和编辑体验 | 可选功能 |

## 3. 调研登记表

| ID | 主题 | 问题 | 结论 | 证据路径/来源 | 上次检查 | 重查条件 | 复用说明 |
|---|---|---|---|---|---|---|---|
| RES-001 | 全文搜索引擎 | 本地全文搜索用什么方案？ | tantivy（Rust 全文搜索库）或 SQLite FTS5 | tantivy.rs / SQLite 官方文档 | 2026-03-16 | 性能不达标时 | 两者均可嵌入，无外部依赖 |
| RES-002 | 终端 UI 框架 | Rust 生态的 TUI 框架选型 | ratatui 社区活跃度最高，API 稳定 | github.com/ratatui | 2026-03-16 | ratatui 不维护时 | 已成为 tui-rs 的继任者 |
| RES-003 | 竞品分析 | 同类工具有哪些？ | nb(bash)功能全但慢；zk(Go)轻量但搜索弱；wiki.vim 仅限 vim | GitHub 各项目 README | 2026-03-16 | 出现强竞品时 | 确认了差异化空间 |
| RES-004 | Frontmatter 解析 | 如何可靠解析 YAML frontmatter？ | 使用 gray-matter 规范，`---` 分隔符，serde_yaml 解析 | commonmark 规范 | 2026-03-16 | 规范变更时 | 与 Obsidian/Hugo 兼容 |

## 4. 目标与非目标

### 4.1 目标

| ID | 目标 | 衡量方式 | 优先级 |
|---|---|---|---|
| G-001 | 终端内 3 秒完成笔记创建 | 从命令输入到文件写入的端到端时间 | p0 |
| G-002 | 万条笔记全文搜索 < 200ms | 基准测试：10000 条平均 500 字的笔记 | p0 |
| G-003 | 标签管理：增删改查、组合过滤 | 支持 AND/OR 组合、层级标签展开 | p0 |
| G-004 | 笔记文件是标准 Markdown | 任意 Markdown 编辑器可直接打开编辑 | p0 |
| G-005 | 零网络依赖，完全离线可用 | 断网场景下所有功能正常 | p1 |
| G-006 | 支持模糊搜索和实时过滤 | 输入时逐字符刷新结果 | p1 |
| G-007 | 支持调用 $EDITOR 编辑笔记 | 默认 vim，可通过环境变量配置 | p1 |

### 4.2 非目标

| ID | 非目标 | 不做原因 |
|---|---|---|
| NG-001 | 云同步 / 多设备同步 | 用户可自行用 git/syncthing 解决，工具不内置 |
| NG-002 | 富文本编辑 / WYSIWYG | 目标用户是开发者，Markdown 原文编辑即可 |
| NG-003 | Web UI / GUI 界面 | 聚焦终端场景，GUI 偏离核心定位 |
| NG-004 | 协作编辑 / 多人共享 | 个人知识库工具，不做协作 |
| NG-005 | 内置 AI 摘要 / 生成 | 保持工具简洁，AI 集成留给插件或外部工具 |
| NG-006 | 支持非 Markdown 格式 | 聚焦 Markdown，不做 org-mode/rst 等 |

## 5. 范围图

| ID | 类型 | 摘要 | 输入 | 输出 | 负责人 | 状态 | 依赖 |
|---|---|---|---|---|---|---|---|
| REQ-001 | feature | 笔记 CRUD（创建/读取/更新/删除） | CLI 命令 + 参数 | .md 文件 + 索引更新 | developer | todo | - |
| REQ-002 | feature | 全文搜索 | 查询字符串 | 匹配笔记列表 + 高亮片段 | developer | todo | REQ-001 |
| REQ-003 | feature | 标签管理 | 标签操作命令 | 标签索引更新 + 过滤结果 | developer | todo | REQ-001 |
| REQ-004 | feature | Frontmatter 自动管理 | 笔记创建/更新事件 | 自动填充 created/updated/tags | developer | todo | REQ-001 |
| REQ-005 | feature | 交互式 TUI 浏览 | 键盘快捷键 | 笔记列表 + 预览 + 搜索 | developer | todo | REQ-002, REQ-003 |
| REQ-006 | feature | 索引构建与增量更新 | 文件系统变更 | 搜索索引文件 | developer | todo | REQ-001 |
| REQ-007 | feature | 配置管理 | 配置文件 / 环境变量 | 运行时配置 | developer | todo | - |
| REQ-008 | feature | 导入已有 Markdown 笔记 | 目录路径 | 索引入库 | developer | todo | REQ-006 |

## 6. 架构与边界

### 6.1 模块

| ID | 模块 | 职责 | 边界 | 备注 |
|---|---|---|---|---|
| MOD-001 | cli | 命令行入口，解析参数，分发子命令 | 不含业务逻辑，只做路由 | 使用 clap |
| MOD-002 | core | 笔记领域模型：Note、Tag、Vault 结构体与操作 | 不依赖 IO，纯逻辑 | 可独立测试 |
| MOD-003 | storage | 文件系统读写、frontmatter 解析/序列化 | 仅操作 Vault 目录 | serde_yaml |
| MOD-004 | index | 搜索索引构建、查询、增量更新 | 索引文件存储在 .devnotes/ | tantivy 或 SQLite FTS5 |
| MOD-005 | search | 全文搜索、模糊匹配、标签过滤的统一查询接口 | 依赖 index 模块 | 屏蔽底层引擎差异 |
| MOD-006 | tui | 交互式终端界面：列表、预览、搜索框 | 可选编译，不影响 CLI 模式 | ratatui |
| MOD-007 | config | 配置加载：默认值、配置文件、环境变量、CLI 参数 | 优先级：CLI > env > file > default | toml 格式 |

### 6.2 接口

| ID | 方向 | 契约 | 异常规则 | 备注 |
|---|---|---|---|---|
| IF-001 | cli -> core | `NoteService::create(title, tags, body) -> Result<Note>` | 标题为空时返回 Error | 主要写入接口 |
| IF-002 | cli -> search | `SearchService::query(q, filters) -> Result<Vec<SearchHit>>` | 空查询返回最近笔记 | 统一搜索入口 |
| IF-003 | core -> storage | `Storage::read(path) -> Result<Note>` | 文件不存在返回 NotFound | 文件 IO 抽象 |
| IF-004 | core -> index | `Index::add(note) / remove(id) / update(note)` | 索引损坏时自动重建 | 增量更新 |
| IF-005 | tui -> search | 复用 IF-002 | 同 IF-002 | TUI 搜索即 CLI 搜索 |

### 6.3 交互时序

1. 用户输入 `dn new "Rust lifetime 笔记" -t rust -t learning`
2. cli 解析参数，调用 `NoteService::create`
3. core 生成 Note 结构体（含 frontmatter、空 body）
4. storage 写入 .md 文件到 Vault 目录
5. index 增量更新索引
6. cli 输出创建成功信息，打开 $EDITOR

### 6.4 关键限制

- 单 Vault 模式，v1 不支持多 Vault 切换
- 索引文件与 Vault 目录绑定，不可跨目录共享
- frontmatter 仅支持 YAML 格式，不支持 TOML frontmatter
- 文件名由标题自动生成（slugify），不支持自定义文件名规则

## 7. 技术栈与方案概述

| 领域 | 选择 | 原因 | 备选 |
|---|---|---|---|
| 语言 | Rust | 性能好、单二进制分发、无运行时依赖 | Go（开发效率高但二进制大） |
| CLI 框架 | clap | Rust 生态标准，derive 模式开发快 | - |
| 全文搜索 | tantivy | Rust 原生，性能接近 Lucene，无需外部服务 | SQLite FTS5（更简单但功能少） |
| TUI 框架 | ratatui | 社区活跃，API 稳定，跨平台 | cursive |
| 配置格式 | TOML | Rust 生态标准配置格式 | YAML |
| Frontmatter | serde_yaml | 成熟稳定 | - |
| 测试 | cargo test + assert_cmd | 单元测试 + CLI 集成测试 | - |
| 构建分发 | cargo + GitHub Actions | 自动交叉编译 linux/macos/windows | - |

## 8. 实施计划

### 8.1 里程碑

| ID | 里程碑 | 交付物 | 验证方式 | 状态 |
|---|---|---|---|---|
| M-001 | 核心 CRUD | 可通过 CLI 创建、查看、编辑、删除笔记 | 集成测试覆盖全部子命令 | todo |
| M-002 | 全文搜索 | 可通过 `dn search` 全文检索笔记 | 基准测试：万条笔记 < 200ms | todo |
| M-003 | 标签管理 | 标签 CRUD + 组合过滤 + 标签列表 | 标签过滤集成测试 | todo |
| M-004 | TUI 交互 | 交互式浏览、搜索、预览笔记 | 手动验收 | todo |
| M-005 | 打磨与分发 | 配置文件、导入工具、安装脚本、README | 在干净系统上安装并使用 | todo |

### 8.2 任务拆解

| ID | 里程碑 | 任务 | worktree | 负责人 | 验证点 | 状态 |
|---|---|---|---|---|---|---|
| TSK-001 | M-001 | 初始化 Cargo 项目，建立模块骨架 | - | developer | VAL-001 | todo |
| TSK-002 | M-001 | 实现 Note 领域模型和 frontmatter 解析 | - | developer | VAL-002 | todo |
| TSK-003 | M-001 | 实现 storage 模块（文件读写） | - | developer | VAL-003 | todo |
| TSK-004 | M-001 | 实现 CLI 子命令：new, show, edit, rm, ls | - | developer | VAL-004 | todo |
| TSK-005 | M-002 | 集成 tantivy，实现索引构建 | - | developer | VAL-005 | todo |
| TSK-006 | M-002 | 实现 search 子命令和模糊搜索 | - | developer | VAL-006 | todo |
| TSK-007 | M-003 | 实现标签索引和 tag 子命令 | - | developer | VAL-007 | todo |
| TSK-008 | M-003 | 实现标签组合过滤（AND/OR） | - | developer | VAL-008 | todo |
| TSK-009 | M-004 | 实现 TUI 列表和搜索界面 | - | developer | VAL-009 | todo |
| TSK-010 | M-005 | 配置文件、导入工具、CI/CD | - | developer | VAL-010 | todo |

### 8.3 并行泳道

- lane a：M-001 (CRUD) -> M-002 (搜索) -> M-004 (TUI)
- lane b：M-003 (标签，M-001 完成后可并行于 M-002)
- lane c：M-005 (打磨，贯穿全程逐步完善)

## 9. 风险与应对

| ID | 风险 | 触发条件 | 影响 | 应对 | 状态 |
|---|---|---|---|---|---|
| RSK-001 | tantivy 索引体积过大 | 笔记数 > 10000 | 磁盘占用不可接受 | 评估 SQLite FTS5 作为替代方案 | open |
| RSK-002 | Rust 编译时间长影响迭代 | 依赖多、增量编译慢 | 开发效率降低 | 拆小 crate、使用 cargo-watch | open |
| RSK-003 | ratatui 跨平台兼容问题 | Windows terminal 渲染异常 | 部分用户无法使用 TUI | TUI 为可选功能，CLI 模式始终可用 | open |
| RSK-004 | frontmatter 解析边界情况多 | 用户手动编辑 frontmatter 格式错误 | 笔记无法被索引 | 宽容解析 + 错误提示 + 修复命令 | open |

## 10. ADR-lite

| ID | 决策 | 原因 | 取舍 | 日期 |
|---|---|---|---|---|
| ADR-001 | 选择 Rust 而非 Go | 单二进制、零运行时依赖、性能极致 | 开发速度较慢，学习曲线陡 | 2026-03-16 |
| ADR-002 | 选择 tantivy 而非 SQLite FTS5 | Rust 原生集成，全文搜索功能更全 | 索引体积可能较大 | 2026-03-16 |
| ADR-003 | 笔记以单文件 .md 存储 | 最大兼容性，用户可用任意编辑器 | 元数据管理依赖 frontmatter 约定 | 2026-03-16 |
| ADR-004 | TUI 作为可选 feature | 不强制依赖 TUI 库，CLI 模式始终可用 | 需维护两套交互逻辑 | 2026-03-16 |

## 11. 实施记录

| 时间 | 变更 | 提交 | 验证 | 备注 |
|---|---|---|---|---|
| 2026-03-16 | init | - | 骨架生成确认 | idea-ops-lite 初始化 |
| 2026-03-16 | idea -> scope | - | WORK.md 内容填充完成 | 完成想法收敛 |

## 12. 验证表

| ID | 检查项 | 方法 | 结果 | 状态 |
|---|---|---|---|---|
| VAL-001 | Cargo 项目可编译 | `cargo build` 无错误 | - | todo |
| VAL-002 | Note 模型 + frontmatter 解析正确 | 单元测试覆盖正常/异常输入 | - | todo |
| VAL-003 | 文件读写正确 | 创建、读取、删除文件的集成测试 | - | todo |
| VAL-004 | CLI 子命令可用 | `assert_cmd` 集成测试 | - | todo |
| VAL-005 | 索引构建完成 | 1000 条笔记索引 < 5s | - | todo |
| VAL-006 | 搜索返回正确结果 | 精确匹配 + 模糊匹配测试用例 | - | todo |
| VAL-007 | 标签 CRUD 正常 | 标签增删改查测试 | - | todo |
| VAL-008 | 组合过滤正确 | AND/OR 组合返回正确子集 | - | todo |
| VAL-009 | TUI 可启动且响应键盘 | 手动验收 | - | todo |
| VAL-010 | 全新系统可安装使用 | 在 Docker 容器中从零安装 | - | todo |

## 13. 当前状态报告

- 总体：yellow
- 已完成：想法收敛、术语定义、目标/非目标界定、架构设计、技术选型、任务拆解
- 进行中：-
- 下一步：TSK-001 初始化 Cargo 项目
- 阻塞项：无
- 待决策：tantivy vs SQLite FTS5 最终性能对比（可延迟到 M-002）

## 14. 材料登记表

| ID | 类型 | 路径 | 来源区块 | 保留规则 | 状态 | 删除条件 |
|---|---|---|---|---|---|---|
| ART-001 | scratch | scratch/ | 3. 调研登记表 | 吸收后删 | live | 已吸收或过期 |

## 15. 归档与删除记录

| 日期 | 材料 | 动作 | 原因 |
|---|---|---|---|
| 2026-03-16 | - | - | 初始化，尚无材料 |
