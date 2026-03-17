# 开发路线图

## 项目状态：设计阶段

## Phase 1 - 基础框架（优先）

- [ ] 初始化 Cargo 项目（`cargo init`）
- [ ] 添加核心依赖（rusqlite, clap, serde）
- [ ] 实现 SQLite 数据库初始化（建表、FTS5 虚拟表）
- [ ] 实现 `NoteStore` trait 的 SQLite 后端

## Phase 2 - 核心 CRUD

- [ ] 实现笔记创建（`create` 命令）
- [ ] 实现笔记查看（`get` 命令）
- [ ] 实现笔记删除（`delete` 命令）
- [ ] 实现笔记列表（`list` 命令）

## Phase 3 - 搜索与标签

- [ ] 实现全文搜索命令（`search`）
- [ ] 标签 CRUD（创建、列表、删除、重命名）
- [ ] 按标签筛选笔记

## Phase 4 - 高级功能

- [ ] 解析 Markdown front matter
- [ ] 笔记导入功能（从 Markdown 文件）
- [ ] 笔记导出功能（导出为 Markdown 文件）
- [ ] 批量操作支持

## Phase 5 - 打磨

- [ ] 错误信息优化
- [ ] 彩色终端输出
- [ ] 配置文件支持（`~/.config/rustnote/`）
- [ ] Shell 补全生成
- [ ] 编写 README 使用文档
