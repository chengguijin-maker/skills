// 回链：WORK.md > IF-001, MOD-002
// 项目 UID：PRJ-20260316-001
// 状态：设计草稿，后续迭代演进为正式实现

pub trait NoteStore {
    fn create(&self, title: &str, content: &str, tags: &[&str]) -> Result<NoteId>;
    fn get(&self, id: NoteId) -> Result<Note>;
    fn search(&self, query: &str) -> Result<Vec<Note>>;
    fn list_tags(&self) -> Result<Vec<Tag>>;
    fn delete(&self, id: NoteId) -> Result<()>;
}
