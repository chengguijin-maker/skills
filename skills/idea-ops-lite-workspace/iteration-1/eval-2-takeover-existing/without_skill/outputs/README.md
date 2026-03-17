# RustNote - CLI 笔记工具

一个用 Rust 编写的高性能命令行笔记管理工具，支持全文搜索和标签系统。

## 项目概述

RustNote 是一款面向开发者的 CLI 笔记工具，灵感来源于 nb、joplin、obsidian 等工具。
采用 SQLite 作为存储后端，支持 FTS5 全文搜索，单文件部署，适合个人使用场景。

## 核心功能

- 笔记的创建、读取、删除（CRUD）
- 基于 SQLite FTS5 的全文搜索
- 多对多关系的标签系统
- Markdown front matter 解析
- 笔记导入/导出

## 技术栈

- **语言**: Rust
- **存储**: SQLite（FTS5 全文搜索）
- **架构**: Trait-based 抽象存储层

## 项目结构

```
.
├── README.md                 # 项目说明（本文件）
├── docs/
│   ├── architecture.md       # 架构设计文档
│   └── research-db.md        # 数据库选型调研报告
├── src/
│   └── api.rs                # API 接口定义
└── planning/
    ├── roadmap.md            # 开发路线图与 TODO
    └── devlog.md             # 开发日志
```

## 快速开始

> 项目仍处于设计阶段，尚无可运行代码。请参阅 `planning/roadmap.md` 了解开发计划。

## 许可证

待定
