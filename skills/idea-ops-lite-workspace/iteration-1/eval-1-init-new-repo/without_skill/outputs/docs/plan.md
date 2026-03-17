# DevNotes - 项目执行计划

## 项目概述

DevNotes 是一个本地优先的个人知识库 CLI 工具，面向开发者。支持 Markdown 编辑、全文搜索和标签管理，所有数据存储在本地文件系统中。

## 核心设计原则

1. **本地优先** - 所有数据以 Markdown 文件存储在本地，无需网络连接
2. **终端原生** - 所有操作通过 CLI 完成，支持管道和脚本集成
3. **零配置启动** - 开箱即用，`devnotes init` 一条命令初始化
4. **开放格式** - 使用标准 Markdown + YAML frontmatter，不锁定格式

## 技术选型

| 组件 | 选择 | 理由 |
|------|------|------|
| 语言 | TypeScript | 类型安全，开发者友好 |
| 运行时 | Node.js >= 18 | 稳定的 LTS，原生 ESM 支持 |
| CLI 框架 | Commander.js | 成熟稳定，功能完整 |
| 全文搜索 | lunr.js | 轻量级，无外部依赖，适合本地场景 |
| Frontmatter | gray-matter | 行业标准，解析速度快 |
| 终端样式 | chalk | 跨平台终端颜色支持 |
| 测试 | vitest | 快速，原生 TypeScript 支持 |

## 数据模型

笔记以 Markdown 文件存储，使用 YAML frontmatter 保存元数据：

```markdown
---
title: "我的笔记标题"
tags:
  - javascript
  - react
created: "2024-01-15T10:30:00.000Z"
modified: "2024-01-15T10:30:00.000Z"
id: "a1b2c3d4"
---

笔记正文内容...
```

## 功能路线图

### Phase 1: MVP (当前)
- [x] 项目初始化和构建配置
- [x] 笔记 CRUD 操作 (create/read/update/delete)
- [x] YAML frontmatter 元数据管理
- [x] 全文搜索 (lunr.js)
- [x] 标签管理 (add/remove/rename/list)
- [x] CLI 命令结构
- [x] 单元测试

### Phase 2: 增强体验
- [ ] 终端内 Markdown 渲染 (marked-terminal)
- [ ] 交互式模式 (inquirer 菜单导航)
- [ ] 笔记模板支持
- [ ] 配置文件自定义 (.devnotes.json)
- [ ] Stdin 管道输入支持
- [ ] 笔记链接 (wiki-style [[links]])

### Phase 3: 高级功能
- [ ] 持久化搜索索引 (增量更新)
- [ ] 笔记版本历史 (git 集成)
- [ ] 导入/导出 (Obsidian, Notion)
- [ ] 模糊搜索 (fzf 风格)
- [ ] 笔记图谱可视化
- [ ] 加密笔记支持

### Phase 4: 生态扩展
- [ ] 插件系统
- [ ] VS Code 扩展
- [ ] Web UI (可选)
- [ ] 多设备同步 (基于 git)

## CLI 命令设计

```
devnotes init                        # 初始化知识库
devnotes add <title> [-t tags] [-c]  # 创建笔记
devnotes list [--tag <tag>] [--sort] # 列出笔记
devnotes view <id>                   # 查看笔记
devnotes edit <id>                   # 编辑笔记
devnotes search <query>              # 全文搜索
devnotes tag list                    # 列出所有标签
devnotes tag add <id> <tag>          # 添加标签
devnotes tag remove <id> <tag>       # 移除标签
devnotes tag rename <old> <new>      # 重命名标签
```

## 目录结构

```
devnotes/
├── src/
│   ├── cli.ts              # CLI 入口
│   ├── index.ts             # 库入口
│   ├── commands/            # 命令实现
│   │   ├── init.ts
│   │   ├── add.ts
│   │   ├── search.ts
│   │   ├── list.ts
│   │   ├── view.ts
│   │   ├── edit.ts
│   │   └── tag.ts
│   ├── core/                # 核心业务逻辑
│   │   ├── types.ts
│   │   ├── store.ts         # 笔记存储
│   │   ├── search.ts        # 搜索引擎
│   │   └── tags.ts          # 标签管理
│   └── utils/
│       └── helpers.ts       # 工具函数
├── tests/                   # 测试文件
│   ├── store.test.ts
│   ├── search.test.ts
│   └── tags.test.ts
├── docs/
│   └── plan.md              # 项目计划
├── examples/                # 示例笔记
├── package.json
├── tsconfig.json
├── vitest.config.ts
└── .gitignore
```

## 开发指南

```bash
# 安装依赖
pnpm install

# 开发模式
pnpm run dev

# 构建
pnpm run build

# 运行测试
pnpm test

# 本地测试 CLI
node dist/cli.js init
node dist/cli.js add "My First Note" -t "test,demo"
node dist/cli.js list
node dist/cli.js search "first"
```
