---
name: accessing-jira-api
description: Access JIRA Server REST API v2 for issue search, issue CRUD, comments, assignees, workflow transitions, projects, metadata, attachments, and remote links. Use when working with JIRA issues, tickets, projects, JQL, or Confluence integration.
---

# Accessing JIRA Server API

Server: `http://tvjira.hisense.com`
API base path: `/rest/api/2`
Login endpoint: `/rest/auth/1/session`
Version note: JIRA Server 7.6.1 can return 404 for unsupported `expand` usage. Prefer `fields=*all` or explicit `fields`.

## Scripts

Primary query interface:

```powershell
& "$HOME\.qoder\skills\accessing-jira-api\scripts\jira_query.ps1" -Action Search
```

Login and session helpers:

```powershell
& "$HOME\.qoder\skills\accessing-jira-api\scripts\jira_login.ps1" -SaveCredential
. "$HOME\.qoder\skills\accessing-jira-api\scripts\set_jira_session.ps1" -CookieHeader "JSESSIONID=..."
```

Script paths:

```text
$HOME\.qoder\skills\accessing-jira-api\scripts\jira_query.ps1
$HOME\.qoder\skills\accessing-jira-api\scripts\jira_login.ps1
$HOME\.qoder\skills\accessing-jira-api\scripts\set_jira_session.ps1
```

## Authentication

The scripts support three modes:

- `Basic`: username and password are sent as an HTTP Basic header for each request.
- `Session`: the script logs in through `/rest/auth/1/session` and uses the returned cookie for the request.
- `SessionCookie`: the script uses an existing `JIRA_COOKIE` value.

Recommended environment variables:

```powershell
$env:JIRA_BASE_URL = "http://tvjira.hisense.com"
$env:JIRA_USERNAME = "your_username"
$env:JIRA_PASSWORD = "password only in current process"
```

For unattended use, store the credential with Windows DPAPI:

```powershell
& "$HOME\.qoder\skills\accessing-jira-api\scripts\jira_login.ps1" `
  -Username $env:JIRA_USERNAME `
  -SaveCredential
```

You can also skip the setup command. If `jira_query.ps1` cannot find a saved credential, it prompts for username and password once, saves them with Windows DPAPI, then continues the request.

After the first successful credential prompt or setup command, later commands do not need `-Username` or `-PasswordPlainText`:

```powershell
& "$HOME\.qoder\skills\accessing-jira-api\scripts\jira_query.ps1" -Action Search
```

The saved credential includes both username and password. It is encrypted by Windows DPAPI for the current Windows user.

This creates:

```text
$HOME\.qoder\skills\accessing-jira-api\jira_credential.xml
```

The file is encrypted for the current Windows user. Do not commit it.

## Common Operations

Search with JQL:

```powershell
& "$HOME\.qoder\skills\accessing-jira-api\scripts\jira_query.ps1" `
  -Action Search `
  -Jql "project = MT9655 ORDER BY created DESC" `
  -MaxResults 20
```

Get one issue:

```powershell
& "$HOME\.qoder\skills\accessing-jira-api\scripts\jira_query.ps1" `
  -Action Issue `
  -IssueKey "MT9655JPU9-9681" `
  -Fields "*all" `
  -RawJson
```

Create an issue:

```powershell
& "$HOME\.qoder\skills\accessing-jira-api\scripts\jira_query.ps1" `
  -Action CreateIssue `
  -ProjectKey "MT9655" `
  -IssueType "Bug" `
  -Summary "Issue title" `
  -Description "Issue description"
```

Update summary or description:

```powershell
& "$HOME\.qoder\skills\accessing-jira-api\scripts\jira_query.ps1" `
  -Action UpdateIssue `
  -IssueKey "MT9655JPU9-9681" `
  -Summary "New title"
```

Add a comment:

```powershell
& "$HOME\.qoder\skills\accessing-jira-api\scripts\jira_query.ps1" `
  -Action AddComment `
  -IssueKey "MT9655JPU9-9681" `
  -Comment "Investigation notes"
```

List and apply workflow transitions:

```powershell
& "$HOME\.qoder\skills\accessing-jira-api\scripts\jira_query.ps1" -Action Transitions -IssueKey "MT9655JPU9-9681" -RawJson
& "$HOME\.qoder\skills\accessing-jira-api\scripts\jira_query.ps1" -Action Transition -IssueKey "MT9655JPU9-9681" -TransitionId "31"
```

Create a remote link to a Confluence page:

```powershell
& "$HOME\.qoder\skills\accessing-jira-api\scripts\jira_query.ps1" `
  -Action AddRemoteLink `
  -IssueKey "MT9655JPU9-9681" `
  -RemoteUrl "http://dmtks.hisense.com/pages/viewpage.action?pageId=123456" `
  -RemoteTitle "Design document"
```

Call an endpoint directly:

```powershell
& "$HOME\.qoder\skills\accessing-jira-api\scripts\jira_query.ps1" `
  -Action Raw `
  -Method Get `
  -Path "/rest/api/2/serverInfo" `
  -RawJson
```

## Action Reference

| Action | Endpoint or behavior |
| --- | --- |
| `Search` | `GET /rest/api/2/search` |
| `Issue` | `GET /rest/api/2/issue/{key}` |
| `CreateIssue` | `POST /rest/api/2/issue` |
| `UpdateIssue` | `PUT /rest/api/2/issue/{key}` |
| `DeleteIssue` | `DELETE /rest/api/2/issue/{key}` |
| `AddComment` | `POST /rest/api/2/issue/{key}/comment` |
| `Assign` | `PUT /rest/api/2/issue/{key}/assignee` |
| `Transitions` | `GET /rest/api/2/issue/{key}/transitions` |
| `Transition` | `POST /rest/api/2/issue/{key}/transitions` |
| `Projects` | `GET /rest/api/2/project` |
| `Project` | `GET /rest/api/2/project/{key}` |
| `IssueTypes` | `GET /rest/api/2/issuetype` |
| `Statuses` | `GET /rest/api/2/status` |
| `ServerInfo` | `GET /rest/api/2/serverInfo` |
| `Myself` | `GET /rest/api/2/myself` |
| `RemoteLinks` | `GET /rest/api/2/issue/{key}/remotelink` |
| `AddRemoteLink` | `POST /rest/api/2/issue/{key}/remotelink` |
| `AttachFile` | `POST /rest/api/2/issue/{key}/attachments`, requires PowerShell 7 |
| `Raw` | Direct call with `-Path`, `-Method`, and optional `-BodyJson` |

## Advanced Usage

Use `-BodyJson` when the compact parameters are not enough. The JSON is passed to the API unchanged after parsing.

```powershell
$body = @{
  fields = @{
    labels = @("api", "automation")
  }
} | ConvertTo-Json -Depth 10 -Compress

& "$HOME\.qoder\skills\accessing-jira-api\scripts\jira_query.ps1" `
  -Action UpdateIssue `
  -IssueKey "MT9655JPU9-9681" `
  -BodyJson $body
```

Use `-RawJson` when the full server response is needed for another script.

Use `SessionCookie` when a browser or a previous login command already produced a valid cookie:

```powershell
& "$HOME\.qoder\skills\accessing-jira-api\scripts\jira_query.ps1" `
  -Action Search `
  -AuthMethod SessionCookie `
  -CookieHeader $env:JIRA_COOKIE
```

## References

Reference documents copied from `$HOME\work\api-docs` are stored in:

```text
$HOME\.qoder\skills\accessing-jira-api\references
```

Start with `references\index.md`.

When the task is broad discovery, topic mapping, project selection, field analysis, or cross Jira and Confluence exploration, read `references\system-map-2026-05-07` first. It contains Jira project maps, project category summaries, field maps, issue type maps, status maps, recent active project summaries, and recent issue samples.

Use these files to choose candidate project keys, fields, issue types, statuses, and JQL entry points. They are snapshots and should guide discovery only. Verify important facts with live Jira API calls before making conclusions or edits.

Use the local HTML files for endpoint details after the exploration scope is clear.
