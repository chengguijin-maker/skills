# Confluence API References

这些文件让 skill 同时具备两类上下文: API 调用手册和 Confluence 当前可见内容图谱。

## System Map Snapshot

这组文件来自 2026-05-07 的 Jira 和 Confluence 广度探索。它们是快照, 用于建立探索入口和范围判断, 不能替代实时 Confluence 查询。

建议读取顺序:

1. 先读 `system-map-2026-05-07\jira-confluence-system-map-v3.md`, 理解 Jira 和 Confluence 的整体内容分布以及跨系统使用策略。
2. 做 Confluence 广度探索前读 `system-map-2026-05-07\confluence-space-category-summary.csv` 和 `system-map-2026-05-07\confluence-spaces-classified.csv`, 先判断空间域和候选 space key。
3. 需要用图谱方式理解各空间内部内容分布时, 优先读 `system-map-2026-05-07\confluence-directory-graph-level2\confluence-空间图谱摘要.csv`, 再用节点表和关系表下钻。
4. 需要查看原始目录层级时, 读 `system-map-2026-05-07\confluence-directory-tree-level2\confluence-空间目录摘要.csv`, 再打开对应 `空间-<空间键>-目录树.csv`。
5. 需要找近期活跃知识内容时读 `system-map-2026-05-07\confluence-recent-content.csv`。
6. 需要按空间继续下钻时读 `system-map-2026-05-07\confluence-space-page-samples.csv`, 再使用 CQL 或 page children API 做实时扩展。

系统地图文件:

- `system-map-2026-05-07\jira-confluence-system-map-v3.md`
- `system-map-2026-05-07\confluence-spaces-map.csv`
- `system-map-2026-05-07\confluence-spaces-classified.csv`
- `system-map-2026-05-07\confluence-space-category-summary.csv`
- `system-map-2026-05-07\confluence-recent-content.csv`
- `system-map-2026-05-07\confluence-space-page-samples.csv`
- `system-map-2026-05-07\confluence-directory-tree-level2\README.md`
- `system-map-2026-05-07\confluence-directory-tree-level2\confluence-空间目录摘要.csv`
- `system-map-2026-05-07\confluence-directory-tree-level2\confluence-空间目录树总表.csv`
- `system-map-2026-05-07\confluence-directory-graph-level2\README.md`
- `system-map-2026-05-07\confluence-directory-graph-level2\confluence-目录图谱节点.csv`
- `system-map-2026-05-07\confluence-directory-graph-level2\confluence-目录图谱关系.csv`
- `system-map-2026-05-07\confluence-directory-graph-level2\confluence-空间图谱摘要.csv`

## Local API Documents

这些文件来自 `$HOME\work\api-docs`, 用于离线查看 Confluence Server REST API 用法。

- `2026-05-06T11-21-51-Confluence-Basic-Auth-for-REST-APIs.html`
- `2026-05-06T11-21-51-Confluence-Content-API-v1.html`
- `2026-05-06T11-21-51-Confluence-REST-API-Examples.html`
- `2026-05-06T11-21-51-Confluence-Server-REST-API-Reference.html`
- `2026-05-06T11-21-51-How-to-Link-Confluence-Page-to-JIRA-Issue-via-REST-API.html`
- `2026-05-06T11-34-59-JIRA-Confluence-API-能力总结.md`

## Quick Notes

- Prefer `confluence_query.ps1` for repeatable calls.
- Use session authentication by default. Confluence session login is `/login.action`.
- Use `-RawJson` when another script needs the complete response.
- Use `-BodyJson` for fields not covered by compact parameters.
- `UpdatePage` automatically increments the version when `-VersionNumber` is omitted.
- Use the JIRA skill `AddRemoteLink` action to connect a Confluence page to an issue.
- Treat system map CSV files as discovery guides, then verify important facts with live Confluence API calls.
