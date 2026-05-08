---
name: accessing-coremail-api
description: Access Hisense Coremail webmail internal APIs for folder listing, thread listing, message reading, tags, contacts, user attributes, and session based operation. Use when working with Hisense Mail System or Coremail URLs.
---

# Accessing Hisense Coremail API

> Server: `https://mail.hisense.com`
> UI entry: `/coremail/XT/index.jsp?sid=...`
> Main JSON endpoint: `/coremail/s/json?sid=...&func=module:action`
> Authentication: SSO browser login plus matched `sid` and cookies

Coremail is different from JIRA and Confluence. The `sid` in the URL is not a standalone token. API calls must include a matching browser cookie set. If the cookie is missing or belongs to another session, the server returns:

```json
{
  "code": "FA_SECURITY",
  "securityReason": "Cookie"
}
```

## Automatic Login

Use `coremail_login.ps1` when you do not want to copy `sid` and cookies manually.

```powershell
& "$HOME\.qoder\skills\accessing-coremail-api\scripts\coremail_login.ps1" `
  -Username $env:COREMAIL_USERNAME `
  -RunFolders
```

The script prompts for the password if `-PasswordPlainText` or `$env:COREMAIL_PASSWORD` is not provided. It does not write the password to disk.

For unattended use, save the credential once with Windows DPAPI encryption:

```powershell
& "$HOME\.qoder\skills\accessing-coremail-api\scripts\coremail_login.ps1" `
  -Username $env:COREMAIL_USERNAME `
  -SaveCredential
```

The credential is stored at:

```text
$HOME\.qoder\skills\accessing-coremail-api\coremail_credential.xml
```

It is encrypted for the current Windows user through `Export-Clixml`.

You can also let the query script log in automatically when no session exists:

```powershell
& "$HOME\.qoder\skills\accessing-coremail-api\scripts\coremail_query.ps1" `
  -AutoLogin `
  -Username $env:COREMAIL_USERNAME `
  -Action Threads `
  -FolderId 2778360 `
  -Limit 20
```

Persist the generated Coremail session for later terminals:

```powershell
& "$HOME\.qoder\skills\accessing-coremail-api\scripts\coremail_login.ps1" `
  -Username $env:COREMAIL_USERNAME `
  -Persist
```

The automatic login script performs:

- SSO session initialization.
- Login policy query.
- RSA encryption using `publicKey` and `publicKeyId`.
- `webLocalAuth` login.
- OAuth redirect into Coremail.
- Extraction of `COREMAIL_SID` and `COREMAIL_COOKIE`.

If SSO requires slider captcha, MFA, OTP, or other extra verification, the script stops with a clear message and browser login is still required.

## Manual Session Requirements

After logging in through SSO, copy these from the active browser session:

- Current `sid` from the URL.
- Full `Cookie` request header from a Coremail XHR request.

Do not store passwords in this skill. Use environment variables for reusable sessions:

```powershell
$env:COREMAIL_SID = "current_sid"
$env:COREMAIL_COOKIE = "BIGipServer...; ssoLoginToken=...; Coremail.sid=current_sid; Coremail=..."
```

Then run:

```powershell
& "$HOME\.qoder\skills\accessing-coremail-api\scripts\coremail_query.ps1" -Action Folders
```

## Script

Script path:

```text
$HOME\.qoder\skills\accessing-coremail-api\scripts\coremail_query.ps1
```

Automatic login helper:

```text
$HOME\.qoder\skills\accessing-coremail-api\scripts\coremail_login.ps1
```

Session helper:

```text
$HOME\.qoder\skills\accessing-coremail-api\scripts\set_coremail_session.ps1
```

Set a session for the current PowerShell window:

```powershell
. "$HOME\.qoder\skills\accessing-coremail-api\scripts\set_coremail_session.ps1" `
  -Sid "current_sid" `
  -CookieHeader "full Cookie header"
```

Persist it for future terminals:

```powershell
& "$HOME\.qoder\skills\accessing-coremail-api\scripts\set_coremail_session.ps1" `
  -Sid "current_sid" `
  -CookieHeader "full Cookie header" `
  -Persist
```

Common parameters:

- `-Sid`: Coremail session id. Defaults to `$env:COREMAIL_SID`.
- `-CookieHeader`: full cookie header. Defaults to `$env:COREMAIL_COOKIE`.
- `-Action`: operation name.
- `-RawJson`: output complete JSON response.

## Common Operations

### List Folders

```powershell
.\coremail_query.ps1 -Action Folders
```

Endpoint:

```text
POST /coremail/XT/jsp/mail.jsp?func=getAllFolders&sid=...
```

Body:

```text
stats=true&threads=true
```

Purpose: list system and user folders with message and thread counts.

### List Threads in a Folder

```powershell
.\coremail_query.ps1 -Action Threads -FolderId 2778360 -Limit 20
```

Endpoint:

```text
POST /coremail/s/json?sid=...&func=mbox:listThreads
```

Typical body:

```json
{
  "start": 0,
  "limit": 100,
  "mode": "count",
  "order": "receivedDate",
  "desc": true,
  "returnTotal": true,
  "returnTag": true,
  "summaryWindowSize": 100,
  "fid": 2778360,
  "mboxa": "",
  "topFirst": true
}
```

Purpose: list messages or conversation threads in a folder.

### List Messages in a Thread

```powershell
.\coremail_query.ps1 -Action ThreadMessages -MessageId "1:1tbiAQsCEGn8QvUR-QAAsW"
```

Endpoint:

```text
POST /coremail/s/json?sid=...&func=mbox:getThreadMessageInfos
```

Purpose: list all messages in the same conversation.

### Read Message Body

```powershell
.\coremail_query.ps1 -Action Read -MessageId "1:1tbiAQsCEGn8QvUR-QAAsW"
```

Endpoint:

```text
POST /coremail/XT/jsp/readMessage.jsp
```

Body:

```text
mid=<message-id>&part=&mboxa=&mailCipherPassword=&markRead=true
```

Purpose: read metadata, attachments, and HTML body. Use `-RawJson` when the raw HTML body or attachment data is needed.

### List Tags

```powershell
.\coremail_query.ps1 -Action Tags
```

Endpoint:

```text
POST /coremail/s/json?sid=...&func=mbox:listTags
```

### Search Messages

```powershell
.\coremail_query.ps1 -Action Search -Keyword "MT9655" -Limit 20
```

Endpoint exposed by frontend:

```text
POST /coremail/s/json?sid=...&func=mail:searchMessages
```

Search request schemas may vary by Coremail version. If this action fails, capture a browser search request and mirror its JSON body.

## Observed Interfaces

### Verified in Browser

| Function | Endpoint | Purpose |
| --- | --- | --- |
| `mail.jsp?func=getAllFolders` | `/coremail/XT/jsp/mail.jsp` | List folders and stats |
| `mbox:listThreads` | `/coremail/s/json` | List folder threads |
| `mbox:getThreadMessageInfos` | `/coremail/s/json` | List messages in a thread |
| `readMessage.jsp` | `/coremail/XT/jsp/readMessage.jsp` | Read message body |
| `mbox:listTags` | `/coremail/s/json` | List labels |
| `user:getAttrs` | `/coremail/s/json` | User preferences and AI config |
| `user:getFaces` | `/coremail/s/json` | UI theme and locale config |
| `pab:searchContacts` | `/coremail/s/json` | Search or preload contacts |
| `user:getAllOrgDomains` | `/coremail/XT/jsp/setting.jsp` | List organization mail domains |
| `mq:historyQuery` | `/coremail/s/json` | Delivery and message event history |
| `user:offSiteRemind` | `/coremail/s/json` | Login area and last login reminder |

### Exposed by Frontend JS

Mail and folder:

```text
mail:getAllFolders
mail:getAllAccounts
mail:searchMessages
mbox:listThreads
mbox:listMessages
mbox:listTags
mbox:listAttachments
mbox:getMessageInfos
mbox:getThreadMessageInfos
mbox:getMessageData
mbox:readMessage
mbox:updateFolders
```

Compose and send:

```text
mbox:compose
mbox:getComposeData
mbox:replyMessage
mbox:saveMessageToNF
mbox:sendMDN
```

Message operations:

```text
mbox:deleteMessages
mbox:emptyFolder
mbox:moveMessageArea
mbox:updateMessageInfos
mbox:updateMessageTags
mbox:cancelDeliver
mbox:recallMessage2
mbox:destroyAutoDelMail
```

Attachments and encrypted mail:

```text
mbox:saveAttach
mbox:editAttach
mbox:decryptMessage
mbox:decryptMessageToNF
user:authenticateSmimeKeyPass
```

Contacts:

```text
pab:searchContacts
pab:getContacts
pab:createContacts
pab:updateContacts
pab:deleteContacts
pab:getAllGroups
pab:getContactKeys
pab:importContacts
pab:importMessageData
pab:expandMessageData
pab:attachAndForwardContacts
pab:addContactAvatar
pab:addContactAvatarStd
pab:addContactKeyStd
contact:oabSearch
```

User and settings:

```text
user:getAttrs
user:setAttrs
user:getFaces
user:changeFaceSettings
user:getTempSession
user:lockScreen
user:checkSpelling
user:getPOPAccounts
user:migratePOPAccount
user:syncAutoSyncPOPAccounts
user:listDeliveryHistory
user:addMailRules
user:updateMailRules
user:adjustMailRuleOrder
user:addSegments
user:switches
user:getHitCounter
user:setPrefOpHistoryRecord
user:offSiteRemind
user:getCACBannerOption
user:setCACBannerOption
user:sendFeedbackOnCACBanner
```

Security:

```text
user:querySecondAuth
user:prepareUpdateSecondAuth
user:updateSecondAuth
user:validateSecondAuth
user:triggerSecondAuth
user:querySecondAuthValidateStage
user:passKey
setting:unbindAuthKey
```

Message queue:

```text
mq:historyQuery
mq:historySetLastId
```

## Useful JSP Pages

```text
/coremail/XT/detach.jsp
/coremail/XT/jsp/viewMailHTML.jsp?CSP=true
/coremail/public/mailprint.jsp
/coremail/viewDownloadFile.jsp?key=...
/coremail/comupload.jsp
/coremail/displayVerifyCode.jsp?category=compose
/coremail/displayVerifyCode.jsp?category=login
/coremail/jsp/pluginInstall.jsp
/coremail/help/mobile.jsp
/coremail/help/inviteupload.jsp
/coremail/XT5/cal/eventEdit.jsp?func=add
```

## Practical Notes

- Use `-RawJson` when implementing a new action or debugging schema differences.
- Keep `sid` and cookies synchronized. A copied old URL usually fails with `Cookie not matched`.
- If a request fails with `FA_SECURITY`, refresh the browser session and update both `$env:COREMAIL_SID` and `$env:COREMAIL_COOKIE`.
- Reading a message with `markRead=true` may mark unread mail as read. Use `-MarkRead:$false` when preserving unread state matters.
