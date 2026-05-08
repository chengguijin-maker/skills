# 开发日志

## 2026-03-01 - 项目启动

- 确定项目方向：用 Rust 编写一个 CLI 笔记工具
- 性能是选择 Rust 的主要原因
- 参考了同类工具：nb、joplin、obsidian
- 明确了核心功能需求：笔记管理 + 全文搜索 + 标签系统

## 2026-03-05 - 技术选型

- 完成数据库选型调研（SQLite vs LevelDB vs Sled）
- 最终决定使用 SQLite 存储
  - FTS5 支持全文搜索是决定性因素
  - 单文件部署适合 CLI 工具分发
- 确定标签系统使用多对多关系表实现
- 编写了 NoteStore trait 作为存储层 API 草稿
