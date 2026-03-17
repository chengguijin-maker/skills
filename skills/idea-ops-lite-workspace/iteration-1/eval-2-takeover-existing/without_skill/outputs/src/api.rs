// RustNote - 存储层 API 定义
//
// NoteStore trait 定义了笔记存储的核心接口。
// 当前计划的实现为 SQLite 后端（使用 rusqlite + FTS5）。

/// 笔记 ID 类型别名
pub type NoteId = u64;

/// 笔记结构体
pub struct Note {
    pub id: NoteId,
    pub title: String,
    pub content: String,
    pub tags: Vec<Tag>,
    pub created_at: String,
    pub updated_at: String,
}

/// 标签结构体
pub struct Tag {
    pub id: u64,
    pub name: String,
}

/// 统一错误类型（待细化）
pub type Result<T> = std::result::Result<T, Box<dyn std::error::Error>>;

/// 笔记存储 trait
///
/// 抽象存储层接口，解耦业务逻辑与具体存储实现。
/// 便于未来更换存储后端或编写测试 mock。
pub trait NoteStore {
    /// 创建笔记，同时关联标签
    fn create(&self, title: &str, content: &str, tags: &[&str]) -> Result<NoteId>;

    /// 根据 ID 获取笔记
    fn get(&self, id: NoteId) -> Result<Note>;

    /// 全文搜索笔记
    fn search(&self, query: &str) -> Result<Vec<Note>>;

    /// 列出所有标签
    fn list_tags(&self) -> Result<Vec<Tag>>;

    /// 删除笔记
    fn delete(&self, id: NoteId) -> Result<()>;
}
