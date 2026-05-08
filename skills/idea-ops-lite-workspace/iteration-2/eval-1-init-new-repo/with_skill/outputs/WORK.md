# DevNotes - 本地优先的个人知识库工具

- 项目 UID：PRJ-20260316-001
- 当前状态：scope
- 负责人：developer
- 仓库路径：/tmp/test-idea-ops-1
- 当前分支：
- 当前 worktree：
- 最后更新：2026-03-16

## 1. Idea

### 1.1 一句话想法

做一个本地优先的个人知识库工具，支持 Markdown 编辑、全文搜索和标签管理，面向开发者，可在终端里快速查找和编辑笔记。

### 1.2 背景

开发者日常积累大量碎片知识：代码片段、调试经验、API 用法、架构笔记等。现有方案的痛点：

- **云端工具（Notion、语雀）**：依赖网络，数据不在本地，隐私担忧，Markdown 兼容性差
- **Obsidian / Logseq**：GUI 优先，终端党需要离开工作环境切换窗口
- **纯文件夹 + grep**：没有标签管理，搜索结果无上下文，无结构化元数据
- **Wiki 类（TiddlyWiki）**：浏览器依赖，不适合终端工作流

核心痛点：开发者希望**不离开终端**就能快速记录、检索和组织知识，数据以纯 Markdown 文件存储在本地，可用 git 同步，无需任何云服务。

### 1.3 成功信号

- 从打开终端到找到目标笔记 < 5 秒
- 新建一条带标签的笔记 < 10 秒
- 支持 1 万条笔记下全文搜索响应 < 500ms
- 数据格式为纯 Markdown，可用任何编辑器打开
- 零外部服务依赖，离线可用

## 2. 术语表

| ID | 术语 | 解释 | 备注 |
|---|---|---|---|
| TERM-001 | Note | 一条知识条目，对应一个 .md 文件 | 最小管理单元 |
| TERM-002 | Tag | 笔记的分类标签，存储在 frontmatter 中 | 支持多标签 |
| TERM-003 | Frontmatter | Markdown 文件顶部 YAML 元数据块 | 存储 tags、created、updated 等 |
| TERM-004 | Vault | 笔记存储的根目录 | 默认 ~/.devnotes |
| TERM-005 | Index | 全文搜索索引文件 | 本地持久化，增量更新 |
| TERM-006 | FZF | 模糊查找工具，用于交互式搜索 | 可选外部依赖 |

## 3. 调研登记表

| ID | 主题 | 问题 | 结论 | 证据路径/来源 | 上次检查 | 重查条件 | 复用说明 |
|---|---|---|---|---|---|---|---|
| RES-001 | CLI 框架选型 | Rust vs Go vs Python 做 CLI 工具哪个更合适？ | Rust：性能最优，单二进制分发，生态有 clap/tantivy；Go：编译快分发易；Python：开发快但性能和分发差。推荐 Rust。 | clap.rs, tantivy 文档 | 2026-03-16 | 团队技术栈变化 | 技术栈决策基础 |
| RES-002 | 全文搜索引擎 | 本地嵌入式全文搜索用什么？ | tantivy（Rust 实现的 Lucene 替代）：支持中文分词、增量索引、嵌入式使用，性能优于 SQLite FTS5 | tantivy GitHub, benchmark 对比 | 2026-03-16 | 搜索性能不达标时 | 搜索模块核心依赖 |
| RES-003 | 标签存储方案 | 标签信息存在哪里？ | 存储在 Markdown frontmatter 的 tags 字段，同时在本地 SQLite 维护标签索引用于快速查询 | Obsidian/Zettlr 方案参考 | 2026-03-16 | 性能瓶颈或格式冲突 | 标签管理模块设计依据 |
| RES-004 | 终端 UI 方案 | 终端内交互式界面用什么？ | ratatui（Rust TUI 框架）用于笔记浏览/预览，日常操作走纯 CLI 子命令 | ratatui GitHub | 2026-03-16 | 用户反馈交互体验差 | UI 模块选型 |

## 4. 目标与非目标

### 4.1 目标

| ID | 目标 | 衡量方式 | 优先级 |
|---|---|---|---|
| G-001 | 终端内快速创建、编辑、删除 Markdown 笔记 | 新建笔记 < 10s，打开编辑 < 3s | p0 |
| G-002 | 全文搜索，支持中英文 | 1 万条笔记搜索 < 500ms | p0 |
| G-003 | 标签管理：添加、删除、按标签筛选 | 标签筛选 < 200ms | p0 |
| G-004 | 数据本地存储，纯 Markdown 文件 | 文件可用 vim/vscode 直接编辑 | p0 |
| G-005 | 零配置开箱即用 | 安装后无需配置即可使用 | p1 |
| G-006 | 笔记模板支持 | 可自定义笔记模板 | p1 |
| G-007 | 终端内笔记预览（渲染 Markdown） | 支持代码高亮、表格渲染 | p2 |

### 4.2 非目标

| ID | 非目标 | 不做原因 |
|---|---|---|
| NG-001 | 云同步服务 | 用户可自行用 git/syncthing 同步，不做内置云服务避免复杂度 |
| NG-002 | GUI 界面 | 目标用户是终端党，GUI 不在核心范围 |
| NG-003 | 多人协作 | 个人工具定位，协作需求可用 git 分支解决 |
| NG-004 | 富文本编辑 | 坚持纯 Markdown，不引入 WYSIWYG |
| NG-005 | 移动端 App | 超出 MVP 范围，后续视需求决定 |
| NG-006 | AI 摘要/嵌入 | 可作为插件扩展，不纳入核心 |

## 5. 范围图

| ID | 类型 | 摘要 | 输入 | 输出 | 负责人 | 状态 | 依赖 |
|---|---|---|---|---|---|---|---|
| REQ-001 | feature | 笔记 CRUD（创建/读取/更新/删除） | CLI 命令 + 参数 | Markdown 文件操作 | developer | todo | - |
| REQ-002 | feature | 全文搜索 | 搜索关键词 | 匹配笔记列表 + 上下文片段 | developer | todo | REQ-001 |
| REQ-003 | feature | 标签管理 | 标签名 + 笔记 ID | 标签索引更新 | developer | todo | REQ-001 |
| REQ-004 | feature | 笔记列表与筛选 | 筛选条件（标签/日期/关键词） | 排序后的笔记列表 | developer | todo | REQ-001, REQ-003 |
| REQ-005 | feature | 配置管理 | 配置文件/CLI 参数 | 运行时配置 | developer | todo | - |
| REQ-006 | feature | 笔记模板 | 模板名称 | 预填充的新笔记 | developer | todo | REQ-001 |
| REQ-007 | feature | 终端 Markdown 预览 | 笔记路径 | 渲染后的终端输出 | developer | todo | REQ-001 |
| REQ-008 | infra | 搜索索引构建与增量更新 | Vault 目录 | tantivy 索引文件 | developer | todo | REQ-002 |

## 6. 架构与边界

### 6.1 模块

| ID | 模块 | 职责 | 边界 | 备注 |
|---|---|---|---|---|
| MOD-001 | cli | 解析命令行参数，路由到子命令 | 不含业务逻辑，只做参数解析和调度 | 使用 clap |
| MOD-002 | note | 笔记 CRUD 操作，frontmatter 解析 | 只操作单个笔记文件，不涉及搜索 | 核心模块 |
| MOD-003 | search | 全文搜索引擎封装 | 只负责索引和查询，不修改笔记 | 使用 tantivy |
| MOD-004 | tag | 标签索引维护与查询 | 标签来源仅限 frontmatter | 使用 SQLite |
| MOD-005 | config | 配置文件加载与默认值 | 只读配置，不写用户数据 | TOML 格式 |
| MOD-006 | render | 终端 Markdown 渲染 | 只做输出渲染，不修改文件 | 可选模块 |
| MOD-007 | template | 笔记模板管理 | 模板存储在 vault/.templates/ | 内置默认模板 |

### 6.2 接口

| ID | 方向 | 契约 | 异常规则 | 备注 |
|---|---|---|---|---|
| IF-001 | cli -> note | NoteService::create(title, tags, template?) -> Result<NotePath> | 标题为空时返回错误 | - |
| IF-002 | cli -> search | SearchService::query(keyword, limit?) -> Result<Vec<SearchHit>> | 索引不存在时自动构建 | - |
| IF-003 | cli -> tag | TagService::list_tags() -> Result<Vec<TagInfo>> | 无标签时返回空列表 | - |
| IF-004 | note -> tag | 笔记保存后触发 TagService::sync(note_path) | frontmatter 解析失败时跳过该笔记 | - |
| IF-005 | note -> search | 笔记变更后触发 SearchService::index_one(note_path) | 索引失败不阻塞写入 | 增量更新 |

### 6.3 交互时序

1. 用户输入 `dn search "rust lifetime"` -> cli 解析 -> search.query() -> tantivy 查询 -> 返回匹配列表 -> 终端输出
2. 用户输入 `dn new "Rust借用规则" -t rust,lang` -> cli 解析 -> template 加载 -> note.create() -> tag.sync() -> search.index_one() -> 打开 $EDITOR
3. 用户输入 `dn tags` -> cli 解析 -> tag.list_tags() -> 终端输出标签列表及计数

### 6.4 关键限制

- 单用户单进程，不考虑并发写入
- Vault 目录深度限制 3 层，避免索引爆炸
- 单条笔记大小限制 1MB，超出跳过索引
- frontmatter 仅支持 YAML 格式

## 7. 技术栈与方案概述

| 领域 | 选择 | 原因 | 备选 |
|---|---|---|---|
| runtime | Rust (stable) | 性能好，单二进制分发，无运行时依赖 | Go |
| CLI 框架 | clap v4 | Rust 生态最成熟的 CLI 框架，支持子命令/补全 | argh |
| 全文搜索 | tantivy | Rust 原生，支持中文分词（jieba），嵌入式使用 | SQLite FTS5 |
| 标签索引 | SQLite (rusqlite) | 轻量嵌入式数据库，标签关系查询方便 | serde_json 文件 |
| 配置格式 | TOML | Rust 生态标准，人类可读 | YAML |
| frontmatter 解析 | gray_matter / serde_yaml | 解析 Markdown frontmatter | - |
| 终端渲染 | termimad / bat 库 | Markdown 终端渲染，支持代码高亮 | mdcat |
| TUI（可选） | ratatui | 交互式浏览器/预览 | - |
| 测试 | cargo test + assert_cmd | 单元测试 + CLI 集成测试 | - |

## 8. 实施计划

### 8.1 里程碑

| ID | 里程碑 | 交付物 | 验证方式 | 状态 |
|---|---|---|---|---|
| M-001 | 核心骨架 | CLI 框架 + 配置加载 + Vault 初始化 | `dn init` 可创建 vault 目录 | todo |
| M-002 | 笔记 CRUD | 创建/编辑/删除/列表笔记 | `dn new`, `dn edit`, `dn rm`, `dn ls` 可用 | todo |
| M-003 | 全文搜索 | tantivy 索引构建 + 搜索命令 | `dn search` 返回正确结果，< 500ms | todo |
| M-004 | 标签管理 | 标签索引 + 按标签筛选 | `dn tags`, `dn ls -t rust` 可用 | todo |
| M-005 | 体验完善 | 模板、预览、shell 补全 | `dn new --template`, `dn view` 可用 | todo |
| M-006 | 发布准备 | README、CI、homebrew formula | cargo install 可用，CI 绿 | todo |

### 8.2 任务拆解

| ID | 里程碑 | 任务 | worktree | 负责人 | 验证点 | 状态 |
|---|---|---|---|---|---|---|
| TSK-001 | M-001 | 初始化 Cargo 项目，配置 clap 子命令框架 | - | developer | VAL-001 | todo |
| TSK-002 | M-001 | 实现配置文件加载（~/.config/devnotes/config.toml） | - | developer | VAL-002 | todo |
| TSK-003 | M-001 | 实现 `dn init` 命令创建 vault 目录结构 | - | developer | VAL-003 | todo |
| TSK-004 | M-002 | 实现 frontmatter 解析器 | - | developer | VAL-004 | todo |
| TSK-005 | M-002 | 实现 `dn new` 创建笔记 | - | developer | VAL-005 | todo |
| TSK-006 | M-002 | 实现 `dn edit` 打开编辑器 | - | developer | VAL-006 | todo |
| TSK-007 | M-002 | 实现 `dn rm` 删除笔记 | - | developer | VAL-007 | todo |
| TSK-008 | M-002 | 实现 `dn ls` 列出笔记 | - | developer | VAL-008 | todo |
| TSK-009 | M-003 | 集成 tantivy，实现索引构建 | - | developer | VAL-009 | todo |
| TSK-010 | M-003 | 实现 `dn search` 全文搜索 | - | developer | VAL-010 | todo |
| TSK-011 | M-003 | 实现索引增量更新 | - | developer | VAL-011 | todo |
| TSK-012 | M-004 | 实现 SQLite 标签索引 | - | developer | VAL-012 | todo |
| TSK-013 | M-004 | 实现 `dn tags` 和 `dn ls -t` | - | developer | VAL-013 | todo |
| TSK-014 | M-005 | 实现笔记模板系统 | - | developer | VAL-014 | todo |
| TSK-015 | M-005 | 实现 `dn view` 终端预览 | - | developer | VAL-015 | todo |
| TSK-016 | M-005 | 生成 shell 补全脚本 | - | developer | VAL-016 | todo |
| TSK-017 | M-006 | 编写 README 和使用文档 | - | developer | VAL-017 | todo |
| TSK-018 | M-006 | 配置 GitHub Actions CI | - | developer | VAL-018 | todo |

### 8.3 并行泳道

- lane a：TSK-001 -> TSK-002 -> TSK-003 -> TSK-004 -> TSK-005/TSK-006/TSK-007/TSK-008（笔记 CRUD 可并行）
- lane b：TSK-009 -> TSK-010 -> TSK-011（搜索链路，依赖 M-002 完成）
- lane c：TSK-012 -> TSK-013（标签链路，依赖 M-002 完成）

## 9. 风险与应对

| ID | 风险 | 触发条件 | 影响 | 应对 | 状态 |
|---|---|---|---|---|---|
| RSK-001 | tantivy 中文分词效果差 | 中文搜索召回率低 | 搜索体验差，用户弃用 | 集成 jieba-rs 分词器；降级方案：回退到 SQLite FTS5 + simple 分词 | open |
| RSK-002 | 大量笔记时索引构建慢 | 笔记超过 5000 条 | 首次索引等待时间长 | 后台异步建索引，增量更新；显示进度条 | open |
| RSK-003 | 跨平台兼容性 | Windows 路径/编码差异 | Windows 用户无法使用 | MVP 先保证 Linux/macOS，Windows 作为 M-006 后续 | open |
| RSK-004 | frontmatter 格式不规范 | 用户手动编辑导致 YAML 语法错误 | 标签/元数据丢失 | 宽容解析 + 错误提示，不阻塞其他功能 | open |

## 10. ADR-lite

| ID | 决策 | 原因 | 取舍 | 日期 |
|---|---|---|---|---|
| ADR-001 | 选择 Rust 作为开发语言 | 性能、单二进制分发、无运行时依赖 | 开发速度慢于 Go/Python，学习曲线陡 | 2026-03-16 |
| ADR-002 | 数据存储为纯 Markdown 文件 + frontmatter | 可移植、人类可读、git 友好 | 元数据查询性能不如数据库 | 2026-03-16 |
| ADR-003 | 标签索引用 SQLite 而非内存 | 持久化、支持复杂查询、重启无需重建 | 引入 SQLite 依赖 | 2026-03-16 |
| ADR-004 | CLI 优先，TUI 可选 | 日常操作 CLI 最快，TUI 只在浏览时需要 | TUI 开发额外工作量 | 2026-03-16 |
| ADR-005 | 命令名使用 `dn` 短名 | 终端工具要求输入效率，短名更快 | 可能与其他工具冲突，允许用户配置别名 | 2026-03-16 |

## 11. 实施记录

| 时间 | 变更 | 提交 | 验证 | 备注 |
|---|---|---|---|---|
| 2026-03-16 | init：初始化项目仓库骨架 | - | 目录结构完整 | idea-ops-lite 初始化 |
| 2026-03-16 | scope：完成想法收敛，填充所有 WORK.md 区块 | - | 所有区块已填充 | 状态从 intake 推进到 scope |

## 12. 验证表

| ID | 检查项 | 方法 | 结果 | 状态 |
|---|---|---|---|---|
| VAL-001 | clap 子命令框架可用 | `dn --help` 输出子命令列表 | - | todo |
| VAL-002 | 配置文件加载正确 | 单元测试：默认值 + 自定义值 | - | todo |
| VAL-003 | vault 目录创建成功 | `dn init` 后检查目录结构 | - | todo |
| VAL-004 | frontmatter 解析正确 | 单元测试：正常/异常/空 frontmatter | - | todo |
| VAL-005 | 笔记创建成功 | `dn new "test"` 生成 .md 文件 | - | todo |
| VAL-006 | 编辑器打开正确 | `dn edit <id>` 打开 $EDITOR | - | todo |
| VAL-007 | 笔记删除成功 | `dn rm <id>` 后文件消失 | - | todo |
| VAL-008 | 笔记列表正确 | `dn ls` 输出所有笔记 | - | todo |
| VAL-009 | 索引构建成功 | `dn index` 生成索引文件 | - | todo |
| VAL-010 | 搜索返回正确结果 | `dn search "test"` 匹配已知笔记 | - | todo |
| VAL-011 | 增量更新有效 | 新增笔记后搜索可命中 | - | todo |
| VAL-012 | 标签索引正确 | 单元测试：标签增删查 | - | todo |
| VAL-013 | 标签筛选可用 | `dn tags` 列出标签，`dn ls -t rust` 筛选 | - | todo |
| VAL-014 | 模板创建笔记 | `dn new --template daily` 使用模板 | - | todo |
| VAL-015 | 终端预览渲染 | `dn view <id>` 输出格式化 Markdown | - | todo |
| VAL-016 | shell 补全可用 | bash/zsh/fish 补全脚本生成 | - | todo |
| VAL-017 | README 完整 | 包含安装、使用、配置说明 | - | todo |
| VAL-018 | CI 通过 | GitHub Actions 绿色 | - | todo |

## 13. 当前状态报告

- 总体：green
- 已完成：项目初始化、想法收敛、需求分析、架构设计、技术选型、任务拆解
- 进行中：-
- 下一步：TSK-001 初始化 Cargo 项目，搭建 CLI 骨架
- 阻塞项：无
- 待决策：无

## 14. 材料登记表

| ID | 类型 | 路径 | 来源区块 | 保留规则 | 状态 | 删除条件 |
|---|---|---|---|---|---|---|
| ART-001 | scratch | scratch/ | 3. 调研登记表 | 吸收后删 | live | 已吸收或过期 |

## 15. 归档与删除记录

| 日期 | 材料 | 动作 | 原因 |
|---|---|---|---|
| 2026-03-16 | - | - | 初始化阶段，暂无归档 |
