# 架构设计文档

## 1. 系统概览

RustNote 是一个单用户 CLI 笔记工具，采用分层架构设计。

```
┌─────────────────────┐
│   CLI 命令层        │  解析用户命令（create, search, tag...）
├─────────────────────┤
│   业务逻辑层        │  笔记管理、标签管理、搜索
├─────────────────────┤
│   存储抽象层        │  NoteStore trait
├─────────────────────┤
│   SQLite 实现层     │  rusqlite + FTS5
└─────────────────────┘
```

## 2. 核心 API 设计

存储层通过 `NoteStore` trait 进行抽象，解耦业务逻辑与具体存储实现：

```rust
pub trait NoteStore {
    fn create(&self, title: &str, content: &str, tags: &[&str]) -> Result<NoteId>;
    fn get(&self, id: NoteId) -> Result<Note>;
    fn search(&self, query: &str) -> Result<Vec<Note>>;
    fn list_tags(&self) -> Result<Vec<Tag>>;
    fn delete(&self, id: NoteId) -> Result<()>;
}
```

### 设计要点

- **trait 抽象**: 便于未来更换存储后端或编写测试 mock
- **Result 返回**: 统一错误处理
- **标签关联创建**: `create` 方法直接支持标签，简化调用方

## 3. 数据模型

### Notes 表
| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER PK | 笔记 ID |
| title | TEXT | 标题 |
| content | TEXT | 正文内容（Markdown） |
| created_at | DATETIME | 创建时间 |
| updated_at | DATETIME | 更新时间 |

### Tags 表
| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER PK | 标签 ID |
| name | TEXT UNIQUE | 标签名 |

### Note_Tags 关系表（多对多）
| 字段 | 类型 | 说明 |
|------|------|------|
| note_id | INTEGER FK | 笔记 ID |
| tag_id | INTEGER FK | 标签 ID |

### FTS5 虚拟表
```sql
CREATE VIRTUAL TABLE notes_fts USING fts5(title, content, content=notes);
```

## 4. 存储选型

经过对 SQLite、LevelDB、Sled 三个方案的调研对比（详见 `research-db.md`），最终选择 **SQLite**：

- 成熟稳定，社区支持好
- FTS5 原生支持全文搜索，无需额外依赖
- 单文件部署，便于备份和迁移
- 单用户场景下写并发不是问题
