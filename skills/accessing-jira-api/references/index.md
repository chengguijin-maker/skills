# JIRA API References

这些文件让 skill 同时具备两类上下文: API 调用手册和 Jira 当前可见内容图谱。

## System Map Snapshot

这组文件来自 2026-05-07 的 Jira 和 Confluence 广度探索。它们是快照, 用于建立探索入口和范围判断, 不能替代实时 Jira 查询。

建议读取顺序:

1. 先读 `system-map-2026-05-07\jira-confluence-system-map-v3.md`, 理解 Jira 和 Confluence 的整体内容分布以及跨系统使用策略。
2. 做 Jira 广度探索前读 `system-map-2026-05-07\jira-project-category-summary.csv` 和 `system-map-2026-05-07\jira-projects-classified.csv`, 先判断项目域和候选 project key。
3. 写 JQL 前读 `system-map-2026-05-07\jira-fields-map.csv`, `system-map-2026-05-07\jira-issue-types-map.csv`, `system-map-2026-05-07\jira-statuses-map.csv`, 避免字段名, 类型和状态假设错误。
4. 需要找近期活跃线索时读 `system-map-2026-05-07\jira-recent-category-summary.csv`, `system-map-2026-05-07\jira-active-projects-from-recent1000.csv`, `system-map-2026-05-07\jira-recent-issues-1000.csv`。

系统地图文件:

- `system-map-2026-05-07\jira-confluence-system-map-v3.md`
- `system-map-2026-05-07\jira-projects-map.csv`
- `system-map-2026-05-07\jira-projects-classified.csv`
- `system-map-2026-05-07\jira-project-category-summary.csv`
- `system-map-2026-05-07\jira-recent-category-summary.csv`
- `system-map-2026-05-07\jira-active-projects-from-recent1000.csv`
- `system-map-2026-05-07\jira-recent-issues-1000.csv`
- `system-map-2026-05-07\jira-recent-status-summary.csv`
- `system-map-2026-05-07\jira-recent-issue-type-summary.csv`
- `system-map-2026-05-07\jira-fields-map.csv`
- `system-map-2026-05-07\jira-issue-types-map.csv`
- `system-map-2026-05-07\jira-statuses-map.csv`

## Local API Documents

这些文件来自 `$HOME\work\api-docs`, 用于离线查看 JIRA Server REST API 用法。

- `2026-05-06T11-21-51-JIRA-Basic-Auth-for-REST-APIs.html`
- `2026-05-06T11-21-51-JIRA-Issue-Remote-Links-API.html`
- `2026-05-06T11-21-51-JIRA-REST-API-Examples.html`
- `2026-05-06T11-21-51-JIRA-Server-REST-API-Reference.html`
- `2026-05-06T11-34-59-JIRA-Confluence-API-能力总结.md`

## Quick Notes

- Prefer `jira_query.ps1` for repeatable calls.
- Use `-RawJson` when another script needs the complete response.
- Use `-BodyJson` for fields not covered by compact parameters.
- Avoid unsupported `expand` parameters on JIRA Server 7.6.1. Use `fields=*all` or explicit field lists.
- Use `AddRemoteLink` to connect a JIRA issue to a Confluence page.
- Treat system map CSV files as discovery guides, then verify important facts with live Jira API calls.
