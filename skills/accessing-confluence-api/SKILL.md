---
name: accessing-confluence-api
description: Access Confluence Server REST API v1 for content search, page CRUD, comments, children, attachments, spaces, labels, restrictions, content body conversion, and JIRA integration. Use when working with Confluence pages, spaces, documents, attachments, CQL, or JIRA remote links.
---

# Accessing Confluence Server API

Server: `http://dmtks.hisense.com`
API base path: `/rest/api`
Login endpoint: `/login.action`
Version note: Confluence Server 6.13.5 uses `/login.action` for session login. Do not use the JIRA `/rest/auth/1/session` path.

## Scripts

Primary query interface:

```powershell
& "$HOME\.qoder\skills\accessing-confluence-api\scripts\confluence_query.ps1" -Action Search
```

Login and session helpers:

```powershell
& "$HOME\.qoder\skills\accessing-confluence-api\scripts\confluence_login.ps1" -SaveCredential
. "$HOME\.qoder\skills\accessing-confluence-api\scripts\set_confluence_session.ps1" -CookieHeader "JSESSIONID=..."
```

Script paths:

```text
$HOME\.qoder\skills\accessing-confluence-api\scripts\confluence_query.ps1
$HOME\.qoder\skills\accessing-confluence-api\scripts\confluence_login.ps1
$HOME\.qoder\skills\accessing-confluence-api\scripts\set_confluence_session.ps1
```

## Tests

Validate the generated directory graph references:

```powershell
& "$HOME\.qoder\skills\accessing-confluence-api\tests\validate-confluence-directory-graph.ps1"
```

This test checks node uniqueness, relationship endpoints, space coverage, page node coverage, directory containment counts, topic relationship weights, summary coverage, empty fetch errors, and sensitive terms. It also writes `references\system-map-2026-05-07\confluence-directory-graph-level2\confluence-目录图谱校验报告.md`.

## Authentication

The scripts support three modes:

- `Session`: login through `/login.action` and use the returned cookie. This is the default.
- `SessionCookie`: use an existing `CONFLUENCE_COOKIE` value.
- `Basic`: send username and password as an HTTP Basic header.

Recommended environment variables:

```powershell
$env:CONFLUENCE_BASE_URL = "http://dmtks.hisense.com"
$env:CONFLUENCE_USERNAME = "your_username"
$env:CONFLUENCE_PASSWORD = "password only in current process"
```

For unattended use, store the credential with Windows DPAPI:

```powershell
& "$HOME\.qoder\skills\accessing-confluence-api\scripts\confluence_login.ps1" `
  -Username $env:CONFLUENCE_USERNAME `
  -SaveCredential
```

You can also skip the setup command. If `confluence_query.ps1` cannot find a saved credential, it prompts for username and password once, saves them with Windows DPAPI, then continues the request.

After the first successful credential prompt or setup command, later commands do not need `-Username` or `-PasswordPlainText`:

```powershell
& "$HOME\.qoder\skills\accessing-confluence-api\scripts\confluence_query.ps1" -Action Search
```

The saved credential includes both username and password. It is encrypted by Windows DPAPI for the current Windows user.

This creates:

```text
$HOME\.qoder\skills\accessing-confluence-api\confluence_credential.xml
```

The file is encrypted for the current Windows user. Do not commit it.

## Common Operations

Search with CQL:

```powershell
& "$HOME\.qoder\skills\accessing-confluence-api\scripts\confluence_query.ps1" `
  -Action Search `
  -Cql "type=page AND space=DZKJSZDSPT ORDER BY lastModified DESC" `
  -Limit 25
```

Get one page with storage body:

```powershell
& "$HOME\.qoder\skills\accessing-confluence-api\scripts\confluence_query.ps1" `
  -Action Page `
  -PageId "123456" `
  -Expand "body.storage,version,space" `
  -RawJson
```

Create a page:

```powershell
& "$HOME\.qoder\skills\accessing-confluence-api\scripts\confluence_query.ps1" `
  -Action CreatePage `
  -SpaceKey "DZKJSZDSPT" `
  -Title "API test page" `
  -StorageValue "<p>Hello Confluence</p>" `
  -ParentPageId "123456"
```

Update a page. The script fetches the current version and increments it unless `-VersionNumber` is provided:

```powershell
& "$HOME\.qoder\skills\accessing-confluence-api\scripts\confluence_query.ps1" `
  -Action UpdatePage `
  -PageId "123456" `
  -Title "New title" `
  -StorageValue "<p>Updated content</p>"
```

Add a comment:

```powershell
& "$HOME\.qoder\skills\accessing-confluence-api\scripts\confluence_query.ps1" `
  -Action AddComment `
  -PageId "123456" `
  -Comment "<p>Investigation notes</p>"
```

List child pages and attachments:

```powershell
& "$HOME\.qoder\skills\accessing-confluence-api\scripts\confluence_query.ps1" -Action Children -PageId "123456"
& "$HOME\.qoder\skills\accessing-confluence-api\scripts\confluence_query.ps1" -Action Attachments -PageId "123456"
```

Convert a storage body:

```powershell
& "$HOME\.qoder\skills\accessing-confluence-api\scripts\confluence_query.ps1" `
  -Action ConvertBody `
  -Representation "storage" `
  -ConvertTo "view" `
  -StorageValue "<p>Hello</p>" `
  -RawJson
```

Call an endpoint directly:

```powershell
& "$HOME\.qoder\skills\accessing-confluence-api\scripts\confluence_query.ps1" `
  -Action Raw `
  -Method Get `
  -Path "/rest/api/space" `
  -RawJson
```

## Action Reference

| Action | Endpoint or behavior |
| --- | --- |
| `Search` | `GET /rest/api/content/search` |
| `Page` | `GET /rest/api/content/{id}` |
| `CreatePage` | `POST /rest/api/content` |
| `UpdatePage` | `PUT /rest/api/content/{id}` |
| `DeletePage` | `DELETE /rest/api/content/{id}` |
| `Children` | `GET /rest/api/content/{id}/child/page` |
| `Comments` | `GET /rest/api/content/{id}/child/comment` |
| `AddComment` | `POST /rest/api/content` with `type=comment` |
| `Attachments` | `GET /rest/api/content/{id}/child/attachment` |
| `UploadAttachment` | `POST /rest/api/content/{id}/child/attachment`, requires PowerShell 7 |
| `Spaces` | `GET /rest/api/space` |
| `Space` | `GET /rest/api/space/{key}` |
| `Labels` | `GET /rest/api/content/{id}/label` |
| `Restrictions` | `GET /rest/api/content/{id}/restriction` |
| `ConvertBody` | `POST /rest/api/contentbody/convert/{to}` |
| `Raw` | Direct call with `-Path`, `-Method`, and optional `-BodyJson` |

## Advanced Usage

Use `-BodyJson` when the compact parameters are not enough. The JSON is passed to the API unchanged after parsing.

```powershell
$body = @{
  type = "page"
  title = "Advanced page"
  space = @{ key = "DZKJSZDSPT" }
  ancestors = @(@{ id = "123456" })
  body = @{
    storage = @{
      value = "<p>Full custom body</p>"
      representation = "storage"
    }
  }
} | ConvertTo-Json -Depth 20 -Compress

& "$HOME\.qoder\skills\accessing-confluence-api\scripts\confluence_query.ps1" `
  -Action CreatePage `
  -BodyJson $body
```

Use `SessionCookie` when a browser or a previous login command already produced a valid cookie:

```powershell
& "$HOME\.qoder\skills\accessing-confluence-api\scripts\confluence_query.ps1" `
  -Action Search `
  -AuthMethod SessionCookie `
  -CookieHeader $env:CONFLUENCE_COOKIE
```

Use JIRA remote links to connect a Confluence page to a JIRA issue:

```powershell
& "$HOME\.qoder\skills\accessing-jira-api\scripts\jira_query.ps1" `
  -Action AddRemoteLink `
  -IssueKey "MT9655JPU9-9681" `
  -RemoteUrl "http://dmtks.hisense.com/pages/viewpage.action?pageId=123456" `
  -RemoteTitle "Confluence design page"
```

## References

Reference documents copied from `$HOME\work\api-docs` are stored in:

```text
$HOME\.qoder\skills\accessing-confluence-api\references
```

Start with `references\index.md`.

When the task is broad discovery, topic mapping, space selection, content inventory, or cross Confluence and Jira exploration, read `references\system-map-2026-05-07` first. It contains Confluence space maps, space category summaries, recent content samples, and per-space page samples.

For understanding what each Confluence space contains internally, start from `references\system-map-2026-05-07\confluence-directory-tree-level2`. The directory tree references only include page hierarchy, titles, paths, inferred topic categories, timestamps, and links. They do not include page bodies. Use `confluence-空间目录摘要.csv` first, then open the corresponding `空间-<空间键>-目录树.csv` for a selected space.

When graph-shaped exploration is needed, start from `references\system-map-2026-05-07\confluence-directory-graph-level2`. Use `confluence-空间图谱摘要.csv` for space selection, `confluence-目录图谱节点.csv` for space, page, and topic nodes, and `confluence-目录图谱关系.csv` for space homepage, directory containment, and topic inference edges.

Use these files to choose candidate space keys, CQL filters, page trees, and Jira cross-reference directions. They are snapshots and should guide discovery only. Verify important facts with live Confluence API calls before making conclusions or edits.

Use the local HTML files for endpoint details after the exploration scope is clear.
