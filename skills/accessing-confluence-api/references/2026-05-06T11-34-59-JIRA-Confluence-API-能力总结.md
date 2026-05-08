# JIRA Server 与 Confluence Server REST API 能力总结

> 基于官方 Atlassian 文档整理
> - JIRA Server: `http://tvjira.hisense.com` (版本 7.6.1)
> - Confluence Server: `http://dmtks.hisense.com` (版本 6.13.5)

---

## 一、认证方式

> ⚠️ **Server/Data Center 版注意事项**：这两个服务器是内部部署的 Server 版，**不是 Cloud 版**。
> Cloud 的 API Token / 邮箱认证方式不适用，Server 版直接用系统用户名+密码。

### 1.1 三种认证方式对比

| 方式 | 安全性 | 配置难度 | 说明 |
|------|--------|---------|------|
| **Basic Auth** | ⭐⭐ | 最简单 | 密码每次请求都明文发送，脚本中需存储密码 |
| **Session Cookie** ⭐推荐 | ⭐⭐⭐⭐ | 简单 | 密码仅登录时发送一次，后续用 Cookie，可手动登出过期 |
| **OAuth** | ⭐⭐⭐⭐⭐ | 复杂 | 无需密码，用令牌授权，需管理员先在服务端配置 |

### 1.2 Session Cookie（推荐）

密码只在登录时发送一次，后续请求全部使用 Cookie，更安全。

**JIRA 登录（`/rest/auth/1/session`）：**
```powershell
$body = @{username=$env:JIRA_USERNAME; password=$env:JIRA_PASSWORD} | ConvertTo-Json
$login = Invoke-RestMethod -Uri "http://tvjira.hisense.com/rest/auth/1/session" `
  -Method Post -Body $body -ContentType "application/json" -SessionVariable jSession
# 后续调用只需 -WebSession $jSession，不需要密码
$me = Invoke-RestMethod -Uri "http://tvjira.hisense.com/rest/api/2/myself" -WebSession $jSession
```

**Confluence 登录（`/login.action`）：**
```powershell
$login = Invoke-RestMethod -Uri "http://dmtks.hisense.com/login.action" `
  -Method Post -Body @{os_username=$env:CONFLUENCE_USERNAME; os_password=$env:CONFLUENCE_PASSWORD} `
  -SessionVariable cSession
# 后续调用只需 -WebSession $cSession，不需要密码
$spaces = Invoke-RestMethod -Uri "http://dmtks.hisense.com/rest/api/space?limit=5" -WebSession $cSession
```

> **已验证可用** ✅ — JIRA 和 Confluence 的 Session Cookie 均已实际测试通过。
> JIRA 返回的 `JSESSIONID` 和 Confluence 登录后自动获取的 Cookie 均可用于后续 API 调用。

### 1.3 Basic Auth（快速测试用）

适合快速测试，但不建议在生产脚本中长期使用（密码在脚本中明文存储）。

```powershell
$pair = "$($env:JIRA_USERNAME):$($env:JIRA_PASSWORD)"
$cred = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($pair))
$headers = @{Authorization="Basic $cred"}
```

### 1.4 OAuth（最安全，需管理员配置）

OAuth 需要 JIRA 管理员先在服务端配置（`JIRA管理 > 系统 > OAuth > 添加消费者`），
生成密钥对注册应用后才能使用。由于需要管理员权限，当前未做可用性测试。

---

## 二、JIRA Server REST API v2

**基础URL**: `http://tvjira.hisense.com/rest/api/2/`

### 2.1 Issue 管理（核心）

| 操作 | HTTP | 端点 | 说明 |
|------|------|------|------|
| 创建 Issue | POST | `/issue` | 创建新问题 |
| 获取 Issue | GET | `/issue/{key}` | 支持 `?expand=renderedFields,names` |
| 编辑 Issue | PUT | `/issue/{key}` | 更新任意字段 |
| 删除 Issue | DELETE | `/issue/{key}` | 删除问题 |
| 分配经办人 | PUT | `/issue/{key}/assignee` | 重新分配负责人 |
| 获取子任务 | GET | `/issue/{key}/subtask` | 子任务列表 |
| Issue 属性 | GET/PUT/DELETE | `/issue/{key}/properties/{propertyKey}` | 自定义属性键值 |
| 上传附件 | POST | `/issue/{key}/attachments` | 需 `X-Atlassian-Token: no-check` 头 |

### 2.2 Issue 链接

| 操作 | HTTP | 端点 | 说明 |
|------|------|------|------|
| 创建 Issue 链接 | POST | `/issueLink` | 两个 Issue 之间建立关联（如"阻塞/被阻塞"） |
| 获取链接类型 | GET | `/issueLinkType` | 查询系统定义的链接类型列表 |
| 创建/更新远程链接 | POST | `/issue/{key}/remotelink` | **JIRA ↔ Confluence 集成的核心 API** |
| 获取远程链接 | GET | `/issue/{key}/remotelink` | 可指定 `?globalId=` 过滤 |
| 删除远程链接 | DELETE | `/issue/{key}/remotelink` | 需指定 `?globalId=` 参数 |

**远程链接示例（关联 Confluence 页面）：**
```json
POST /rest/api/2/issue/MT9655JPU9-9681/remotelink
{
  "globalId": "appId=confluence&pageId=279531451",
  "object": {
    "url": "http://dmtks.hisense.com/pages/viewpage.action?pageId=279531451",
    "title": "技术调研、对外交流、技术难题等重点任务追踪",
    "icon": { "url16x16": "http://dmtks.hisense.com/favicon.ico", "title": "Confluence" }
  }
}
```

### 2.3 搜索

| 操作 | HTTP | 端点 | 说明 |
|------|------|------|------|
| JQL 搜索 | GET | `/search?jql=` | 强大的 Issue 搜索，支持分页 (`startAt`, `maxResults`) |
| JQL 自动补全 | GET | `/jql/autocompletedata` | 获取 JQL 字段/运算符/值的建议 |

### 2.4 项目管理

| 操作 | HTTP | 端点 |
|------|------|------|
| 获取所有项目 | GET | `/project` |
| 获取单个项目 | GET | `/project/{keyOrId}` |
| 创建项目 | POST | `/project` |
| 更新项目 | PUT | `/project/{keyOrId}` |
| 删除项目 | DELETE | `/project/{keyOrId}` |
| 项目角色 | GET | `/project/{key}/role` |
| 项目类型 | GET | `/project/type` |
| 项目分类 | GET | `/projectCategory` |
| 项目校验 | GET | `/projectvalidate` |
| 安全级别 | GET | `/project/{key}/securitylevel` |

### 2.5 用户与组管理

| 操作 | HTTP | 端点 |
|------|------|------|
| 获取用户 | GET | `/user?username=` |
| 创建用户 | POST | `/user` |
| 更新用户 | PUT | `/user` |
| 用户属性 | GET/PUT/DELETE | `/user/properties/{key}` |
| 当前用户 | GET | `/myself` |
| 获取组 | GET | `/group?groupname=` |
| 创建组 | POST | `/group` |
| 添加用户到组 | POST | `/group/user` |
| 用户/组搜索 | GET | `/groupuserpicker` |

### 2.6 工作流与配置

| 操作 | HTTP | 端点 |
|------|------|------|
| 获取所有工作流 | GET | `/workflow` |
| 创建工作流方案 | POST | `/workflowscheme` |
| 所有问题类型 | GET | `/issuetype` |
| 所有状态 | GET | `/status` |
| 状态分类 | GET | `/statuscategory` |
| 所有优先级 | GET | `/priority` |
| 所有解决方案 | GET | `/resolution` |
| 自定义字段 | GET | `/field` |
| 系统配置 | GET | `/configuration` |
| 权限方案 | GET/PUT | `/permissionscheme` |
| 通知方案 | GET | `/notificationscheme` |
| 安全方案 | GET | `/issuesecurityschemes` |

### 2.7 附件管理

| 操作 | HTTP | 端点 |
|------|------|------|
| 获取附件元数据 | GET | `/attachment/{id}` |
| 删除附件 | DELETE | `/attachment/{id}` |
| 解压附件 | GET | `/attachment/{id}/expand/human` (实验性) |

### 2.8 系统管理

| 操作 | HTTP | 端点 |
|------|------|------|
| 仪表盘列表 | GET | `/dashboard` |
| 过滤器 | GET/POST | `/filter` |
| 版本管理 | POST/PUT | `/version` |
| 服务器信息 | GET | `/serverInfo` |
| 应用属性 | GET/PUT | `/application-properties` |
| 应用角色 | GET/PUT | `/applicationrole` |
| 审计记录 | GET | `/auditing` |
| 重新索引 | POST | `/reindex` |
| 集群升级 | GET/POST | `/cluster/zdu/*` |
| 当前用户权限 | GET | `/mypermissions` |
| 个人偏好 | GET/PUT/DELETE | `/mypreferences` |
| 修改密码 | POST | `/password` |
| 系统设置 | PUT | `/settings/baseUrl` |
| 升级任务 | POST | `/upgrade` |

### 2.9 官方示例涵盖场景

1. ✅ **创建 Issue** — 含不同字段类型、自定义字段的完整示例
2. ✅ **编辑 Issue** — 分配经办人、多字段同时更新
3. ✅ **添加评论** — 编辑时附加评论、独立添加评论
4. ✅ **JQL 搜索** — 搜索语法、分页处理、结果字段过滤
5. ✅ **获取创建元数据** — 查询 Issue 创建时的可用字段/值列表
6. ✅ **跨版本兼容检测** — 检测 API 新功能以适配多版本

---

## 三、Confluence Server REST API v1

**基础URL**: `http://dmtks.hisense.com/rest/api/content/`

### 3.1 内容管理（核心）

| 操作 | HTTP | 端点 | 说明 |
|------|------|------|------|
| **获取页面** | GET | `/content/{id}` | 使用 `?expand=body.storage,version,space` 获取完整内容 |
| **按标题搜索** | GET | `/content?title={title}&spaceKey={key}` | 按标题和空间查找页面 |
| **创建页面** | POST | `/content` | 创建新页面 |
| **创建子页面** | POST | `/content` | 指定 `ancestors[{id}]` 创建子页面 |
| **更新页面** | PUT | `/content/{id}` | 更新页面内容和属性 |
| **删除页面** | DELETE | `/content/{id}` | 删除指定页面 |
| **CQL 搜索** | GET | `/content/search?cql=` | 强大的 CQL 查询语言，支持光标分页，如 `type=page&limit=25` |
| **获取子内容** | GET | `/content/{id}/child/{type}` | type 可选 `page`, `comment`, `attachment` |

### 3.2 评论

| 操作 | HTTP | 端点 |
|------|------|------|
| 获取页面评论 | GET | `/content/{id}/child/comment` |
| 添加评论 | POST | `/content` (type=comment, 含 container 指向父页面) |

### 3.3 附件

| 操作 | HTTP | 端点 |
|------|------|------|
| 上传附件 | POST | `/content/{id}/child/attachment` |
| 附件列表 | GET | `/content/{id}/child/attachment` |
| 下载附件 | GET | `/content/{id}/child/attachment/{attId}/download` |
| 更新附件 | PUT | `/content/{id}/child/attachment/{attId}` |

### 3.4 空间管理

| 操作 | HTTP | 端点 |
|------|------|------|
| 获取所有空间 | GET | `/space` |
| 获取空间详情 | GET | `/space/{key}` |
| 创建空间 | POST | `/space` |

### 3.5 用户与权限

| 操作 | HTTP | 端点 |
|------|------|------|
| 获取用户 | GET | `/user?key=` |
| 用户所属组 | GET | `/user/memberOf` |
| 组信息 | GET | `/group?name=` |
| 审计记录 | GET | `/audit` |
| 页面限制 | GET | `/content/{id}/restriction` |

### 3.6 模板与内容转换

| 操作 | HTTP | 端点 |
|------|------|------|
| 获取模板 | GET | `/template` |
| 内容格式转换 | POST | `/contentbody/convert/{to}` | 支持 `storage`、`view`、`editor` 格式互转 |
| 创建蓝图实例 | POST | `/content/blueprint/instance/{draftId}` |

### 3.7 标签

| 操作 | HTTP | 端点 |
|------|------|------|
| 获取标签 | GET | `/label` |
| 页面标签 | GET | `/content/{id}/label` |
| 添加标签 | POST | `/content/{id}/label` |
| 删除标签 | DELETE | `/content/{id}/label/{labelId}` |

### 3.8 官方示例涵盖场景

1. ✅ **浏览内容** — 获取所有页面列表
2. ✅ **分页浏览** — 控制返回数量和偏移
3. ✅ **读取内容并展开 body** — 获取页面的实际 HTML 内容 (body.storage)
4. ✅ **搜索页面/博客** — 按标题、空间等条件搜索
5. ✅ **创建新页面** — jQuery 和 Python 双语言示例
6. ✅ **创建子页面** — 指定父页面创建层级结构
7. ✅ **更新页面** — 修改已有页面内容
8. ✅ **删除页面** — 按 ID 删除
9. ✅ **上传附件** — 文件上传到页面
10. ✅ **下载附件** — 从页面下载文件
11. ✅ **获取评论** — 查看页面的全部评论
12. ✅ **添加评论** — 为页面添加新评论
13. ✅ **创建含任务列表的页面** — 使用高级内容格式
14. ✅ **创建空间** — 完整空间创建流程
15. ✅ **内容格式转换** — 不同表示格式间转换

---

## 四、JIRA ↔ Confluence 集成

### 方式1：Remote Link API（最正式）

JIRA Issue 直接关联到 Confluence 页面：

```
POST /rest/api/2/issue/{issueKey}/remotelink
```

请求体包含 Confluence 页面的 URL、标题和图标。关联后，JIRA Issue 界面会显示"Confluence 页面"链接。

### 方式2：Application Links（自动关联）

通过 JIRA 管理界面的 **Application Links** 配置两个系统关联：
- 配置后自动在 Issue 界面嵌入 Confluence 内容
- 支持双向链接和共享导航

### 方式3：URL 引用（非结构化）

在 Issue 的 description/comment 中直接包含 Confluence 页面 URL：
- 优点：实现最简单
- 缺点：无法通过 API 程序化查询关联关系

### 方式4：OAuth 2.0 (3LO)

- 支持 JIRA ↔ Confluence 间的用户授权
- 需在两个应用中分别注册
- 适合生产环境的自动化脚本

---

## 五、关键区别对比

| 维度 | JIRA Server | Confluence Server |
|------|-------------|-------------------|
| **API 版本** | REST API v2 | REST API v1 |
| **基础路径** | `/rest/api/2/` | `/rest/api/content/` |
| **内容格式** | JSON | JSON |
| **搜索语言** | JQL | CQL |
| **分页参数** | `startAt` / `maxResults` | `start` / `limit` (新版支持 cursor) |
| **字段扩展** | `?expand=names,renderedFields` | `?expand=body.storage,version,space` |
| **附件上传** | 需 `X-Atlassian-Token` 头 | 标准 POST |
| **远程链接** | `/issue/{key}/remotelink` | 不支持（仅 JIRA 端支持） |

---

## 六、常用组合场景

### 场景1：从 Confluence 页面读取需求 → 自动创建 JIRA Issue
```
GET  /rest/api/content/{pageId}?expand=body.storage    → 获取页面内容
POST /rest/api/2/issue                                  → 创建 Issue
POST /rest/api/2/issue/{key}/remotelink                 → 关联回 Confluence 页面
```

### 场景2：JIRA Issue 状态变更 → 更新 Confluence 页面
```
GET  /rest/api/2/issue/{key}                           → 获取 Issue 状态
PUT  /rest/api/content/{pageId}                        → 更新关联页面内容
```

### 场景3：批量搜索关联信息
```
GET /rest/api/2/search?jql=project=MT9655&status=Open  → JQL 搜索
GET /rest/api/content/search?cql=space=DZKJSZDSPT      → CQL 搜索
```

---

> **文档来源**: `$HOME\work\api-docs\jira\`、`$HOME\work\api-docs\confluence\`、`$HOME\work\api-docs\integration\`
> **整理日期**: 2026-05-06
