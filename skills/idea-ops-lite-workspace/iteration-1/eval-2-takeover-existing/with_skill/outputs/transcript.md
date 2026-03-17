# Transcript: idea-ops-lite 接管已有项目

## 任务

接管 `/tmp/test-idea-ops-2/` 已有项目，将散乱材料整理收敛到 WORK.md 主控文件。

## 输入材料

| 文件 | 内容概要 | 行数 |
|---|---|---|
| notes.md | 项目笔记：想法、技术决策、TODO 列表 | 18 |
| research-db.md | 数据库选型调研：SQLite vs LevelDB vs Sled | 17 |
| api-draft.rs | NoteStore trait 草稿，定义 CRUD 和搜索接口 | 9 |

## 执行步骤

### 1. 判断场景

接管已有仓库（非初始化新仓库）。项目目录已有 3 个散乱文件，无结构化管理。

### 2. 材料分析与去重

逐文件分析内容，识别信息类型：

- **notes.md**：混合了 idea（CLI 笔记工具想法）、技术决策（SQLite、标签多对多）、TODO 列表。属于临时脑暴记录。
- **research-db.md**：完整的数据库选型调研，有明确结论（选 SQLite）。属于有价值的调研材料，支撑关键决策。
- **api-draft.rs**：API 设计草稿，定义了 NoteStore trait。属于设计阶段代码产物。

去重检查：notes.md 中"决定用 SQLite 存储"与 research-db.md 结论重复，在 WORK.md 中只记录一次（RES-001），不重复开行。

### 3. 材料分类

按 idea-ops-lite 生命周期规则分类：

| 原文件 | 分类 | 目标位置 | 理由 |
|---|---|---|---|
| notes.md | 临时材料 | scratch/notes.md | 脑暴草稿+TODO，内容已吸收到 WORK.md |
| research-db.md | 归档材料 | archive/research-db.md | 有价值的选型调研，支撑 ADR-001，未来可能复查 |
| api-draft.rs | 代码 | src/api-draft.rs | 设计草稿代码，后续迭代演进 |

### 4. 创建 WORK.md 主控文件

按模板创建，填入从现有材料提取的实际内容：

- **项目 UID**：PRJ-20260316-001
- **状态**：frame（已完成 intake，正在框架化）
- **Idea**：从 notes.md 提取核心想法
- **术语表**：3 条（NoteStore, FTS5, front matter）
- **调研登记表**：1 条（RES-001 数据库选型，从 research-db.md 吸收）
- **目标**：5 条（从 notes.md TODO 和上下文提取）
- **非目标**：3 条（根据项目定位推断）
- **范围图**：5 条功能需求
- **架构**：4 个模块，1 个接口
- **技术栈**：Rust + SQLite + FTS5
- **任务拆解**：7 个任务，2 个并行泳道
- **风险**：2 条
- **ADR**：1 条（数据库选型决策）
- **材料登记表**：3 条（对应 3 个原始文件）
- **归档记录**：3 条（记录每个文件的处置动作）

### 5. 创建 AGENTS.md

使用模板内容，追加项目特定约束（项目 UID、语言、存储选择）。

### 6. 创建 README.md

一句话入口，指向 WORK.md。

### 7. 创建目录结构

```
outputs/
├── README.md
├── AGENTS.md
├── WORK.md
├── archive/
│   └── research-db.md    (有价值调研，添加回链头)
├── scratch/
│   └── notes.md          (临时材料，添加已吸收标记)
├── src/
│   └── api-draft.rs      (API 草稿，添加回链注释)
└── tests/
```

## 去重处理

| 重复项 | 处理方式 |
|---|---|
| notes.md "决定用 SQLite" 与 research-db.md 结论重复 | 统一记录为 RES-001，不重复开行 |
| notes.md TODO 与范围图 REQ 重复 | TODO 吸收为 REQ-001~005，scratch/notes.md 标记已吸收 |

## 材料生命周期规则应用

- notes.md → scratch/（临时材料，已吸收，后续可删除）
- research-db.md → archive/（满足"未来可能复查"和"支撑关键决策"两个归档条件）
- api-draft.rs → src/（代码产物，迭代演进）

## 输出文件清单

| 文件 | 用途 |
|---|---|
| WORK.md | 主控文件，所有信息的唯一事实来源 |
| AGENTS.md | agent 约束入口 |
| README.md | 一句话入口 |
| scratch/notes.md | 已吸收的临时笔记（带回链头和吸收标记） |
| archive/research-db.md | 数据库选型调研归档（带回链头和保留原因） |
| src/api-draft.rs | API 设计草稿（带回链注释） |
| transcript.md | 本文件，执行过程记录 |
