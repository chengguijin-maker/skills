# Transcript: DevNotes 项目初始化

## 任务描述

将"本地优先的个人知识库工具"这一想法，整理为可执行方案并从零初始化项目。要求支持 Markdown 编辑、全文搜索和标签管理，目标用户为开发者，支持终端操作。

## 执行步骤

### 1. 需求分析与技术选型

根据需求分析，确定了以下技术方案：
- **语言**: TypeScript（类型安全，开发者友好）
- **运行时**: Node.js >= 18（ESM 原生支持）
- **CLI 框架**: Commander.js（成熟稳定）
- **全文搜索**: lunr.js（轻量级，无外部依赖，适合本地场景）
- **Frontmatter 解析**: gray-matter（行业标准）
- **终端样式**: chalk（跨平台颜色）
- **测试框架**: vitest（快速，原生 TypeScript）

### 2. 项目结构设计

创建了清晰的分层架构：
```
src/
├── cli.ts              # CLI 入口点
├── index.ts            # 库导出入口
├── commands/           # 7 个命令实现
│   ├── init.ts, add.ts, search.ts, list.ts, view.ts, edit.ts, tag.ts
├── core/               # 核心业务逻辑
│   ├── types.ts        # 类型定义
│   ├── store.ts        # NoteStore - 笔记存储（CRUD）
│   ├── search.ts       # SearchEngine - 全文搜索
│   └── tags.ts         # TagManager - 标签管理
└── utils/
    └── helpers.ts      # 工具函数
```

### 3. 核心模块实现

**NoteStore (store.ts)**: 文件系统笔记存储，使用 Markdown + YAML frontmatter 格式。实现了完整的 CRUD 操作（create/read/update/delete），支持按标签过滤和按文件名/ID 查找。

**SearchEngine (search.ts)**: 基于 lunr.js 的全文搜索引擎，支持标题（10x权重）、标签（5x权重）和正文搜索，返回带相关性评分和匹配片段的结果。

**TagManager (tags.ts)**: 标签管理器，支持列出所有标签及计数、添加/移除标签、跨笔记重命名/删除标签。

### 4. CLI 命令实现

实现了 7 个命令：
- `init` - 初始化知识库
- `add` - 创建笔记（支持 -t 标签和 -c 内容参数）
- `list/ls` - 列出笔记（支持标签过滤和排序）
- `view` - 查看笔记
- `edit` - 在编辑器中打开笔记
- `search` - 全文搜索
- `tag` - 标签管理子命令（list/add/remove/rename）

### 5. 测试编写

创建了 3 个测试文件，共 19 个测试用例：
- `store.test.ts` (8 tests) - 覆盖 CRUD、标签过滤、错误处理
- `search.test.ts` (5 tests) - 覆盖空库搜索、标题/内容/标签搜索、权重排序
- `tags.test.ts` (6 tests) - 覆盖列出/添加/移除/重命名/删除标签

### 6. 项目文档

- `docs/plan.md` - 完整的项目执行计划，包含4阶段路线图
- `README.md` - 项目说明和使用指南

### 7. 构建与验证

**遇到的问题**: 初次构建时出现 ESM/CJS 兼容性错误（chalk v5 是纯 ESM 包）和 lunr 缺少类型定义。

**修复措施**:
- 在 package.json 中添加 `"type": "module"` 启用 ESM
- 添加 `@types/lunr` 开发依赖

**最终结果**:
- TypeScript 编译: 通过
- 19/19 测试: 全部通过
- CLI 功能测试: init/add/list/search/tag 均正常工作

## 创建的文件清单

| 文件 | 用途 |
|------|------|
| `package.json` | 项目配置、依赖、脚本 |
| `tsconfig.json` | TypeScript 编译配置 |
| `vitest.config.ts` | 测试框架配置 |
| `.gitignore` | Git 忽略规则 |
| `README.md` | 项目说明文档 |
| `docs/plan.md` | 项目执行计划与路线图 |
| `src/cli.ts` | CLI 入口 |
| `src/index.ts` | 库导出入口 |
| `src/core/types.ts` | 类型定义 |
| `src/core/store.ts` | 笔记存储核心逻辑 |
| `src/core/search.ts` | 全文搜索引擎 |
| `src/core/tags.ts` | 标签管理器 |
| `src/utils/helpers.ts` | 工具函数 |
| `src/commands/init.ts` | init 命令 |
| `src/commands/add.ts` | add 命令 |
| `src/commands/list.ts` | list 命令 |
| `src/commands/view.ts` | view 命令 |
| `src/commands/edit.ts` | edit 命令 |
| `src/commands/search.ts` | search 命令 |
| `src/commands/tag.ts` | tag 命令 |
| `tests/store.test.ts` | 存储层测试 |
| `tests/search.test.ts` | 搜索引擎测试 |
| `tests/tags.test.ts` | 标签管理测试 |

## 关键决策

1. **本地文件存储 + YAML frontmatter**: 选择开放格式，避免锁定，便于与其他工具（Obsidian等）互操作
2. **lunr.js 内存索引**: MVP 阶段采用按需构建索引，后续可优化为持久化增量索引
3. **Commander.js**: 选择成熟的 CLI 框架，内置帮助、版本、子命令支持
4. **分层架构**: core（业务逻辑）与 commands（CLI 层）分离，便于后续添加 API 或 UI 层
