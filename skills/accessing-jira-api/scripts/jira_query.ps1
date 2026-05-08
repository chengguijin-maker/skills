<#
.SYNOPSIS
    Scripted JIRA Server REST API helper.
.DESCRIPTION
    Provides a stable command line interface for common JIRA Server 7.6 REST API
    operations. Credentials are read from parameters, environment variables, or
    an optional DPAPI encrypted credential file. No password is stored in this
    script.
#>

param(
    [ValidateSet(
        "Search",
        "Issue",
        "CreateIssue",
        "UpdateIssue",
        "DeleteIssue",
        "AddComment",
        "Assign",
        "Transitions",
        "Transition",
        "Projects",
        "Project",
        "IssueTypes",
        "Statuses",
        "ServerInfo",
        "Myself",
        "RemoteLinks",
        "AddRemoteLink",
        "AttachFile",
        "Raw"
    )]
    [string]$Action = "Search",

    [string]$BaseUrl = $(if ($env:JIRA_BASE_URL) { $env:JIRA_BASE_URL } else { "http://tvjira.hisense.com" }),
    [ValidateSet("Basic", "Session", "SessionCookie")]
    [string]$AuthMethod = $(if ($env:JIRA_AUTH_METHOD) { $env:JIRA_AUTH_METHOD } else { "Basic" }),
    [string]$Username = $env:JIRA_USERNAME,
    [string]$PasswordPlainText = $env:JIRA_PASSWORD,
    [string]$CookieHeader = $env:JIRA_COOKIE,
    [string]$CredentialPath = (Join-Path (Split-Path $PSScriptRoot -Parent) "jira_credential.xml"),

    [string]$Jql = "project = MT9655 ORDER BY created DESC",
    [int]$StartAt = 0,
    [int]$MaxResults = 20,
    [string]$Fields = "",

    [string]$IssueKey = "",
    [string]$ProjectKey = "",
    [string]$Summary = "",
    [string]$Description = "",
    [string]$IssueType = "Task",
    [string]$Comment = "",
    [string]$Assignee = "",
    [string]$TransitionId = "",
    [string]$RemoteUrl = "",
    [string]$RemoteTitle = "",
    [string]$Relationship = "relates to",
    [string]$FilePath = "",

    [ValidateSet("Get", "Post", "Put", "Delete")]
    [string]$Method = "Get",
    [string]$Path = "",
    [string]$BodyJson = "",

    [switch]$RawJson
)

$ErrorActionPreference = "Stop"
$BaseUrl = $BaseUrl.TrimEnd("/")

function ConvertTo-QueryString {
    param([hashtable]$Query)

    $parts = New-Object System.Collections.Generic.List[string]
    foreach ($key in $Query.Keys) {
        $value = $Query[$key]
        if ($null -eq $value -or [string]::IsNullOrWhiteSpace([string]$value)) {
            continue
        }
        $encodedKey = [uri]::EscapeDataString([string]$key)
        $encodedValue = [uri]::EscapeDataString([string]$value)
        $parts.Add("$encodedKey=$encodedValue")
    }
    return ($parts -join "&")
}

function Get-StoredCredential {
    if (Test-Path -LiteralPath $CredentialPath) {
        return Import-Clixml -LiteralPath $CredentialPath
    }
    return $null
}

function Read-AndSaveCredential {
    if ([string]::IsNullOrWhiteSpace($script:Username)) {
        $script:Username = Read-Host "JIRA username"
    }

    $securePassword = Read-Host "JIRA password for $script:Username" -AsSecureString
    $credential = New-Object System.Management.Automation.PSCredential($script:Username, $securePassword)
    $credential | Export-Clixml -LiteralPath $CredentialPath
    Write-Host "JIRA credential saved with Windows DPAPI: $CredentialPath"
    return $credential
}

function Resolve-Credential {
    $credential = Get-StoredCredential
    if ([string]::IsNullOrWhiteSpace($script:Username) -and $credential) {
        $script:Username = $credential.UserName
    }

    if (-not [string]::IsNullOrWhiteSpace($PasswordPlainText)) {
        if ([string]::IsNullOrWhiteSpace($script:Username)) {
            $script:Username = Read-Host "JIRA username"
        }
        return @{
            Username = $script:Username
            Password = $PasswordPlainText
        }
    }

    if ($credential) {
        return @{
            Username = $script:Username
            Password = $credential.GetNetworkCredential().Password
        }
    }

    $credential = Read-AndSaveCredential
    return @{
        Username = $credential.UserName
        Password = $credential.GetNetworkCredential().Password
    }
}

function Get-BasicAuthHeaders {
    $credential = Resolve-Credential
    $pair = "$($credential.Username)`:$($credential.Password)"
    $bytes = [Text.Encoding]::UTF8.GetBytes($pair)
    $token = [Convert]::ToBase64String($bytes)
    return @{ Authorization = "Basic $token" }
}

function New-WebSessionFromCookieHeader {
    param([Parameter(Mandatory = $true)][string]$Header)

    $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
    $baseUri = [uri]$BaseUrl
    foreach ($part in ($Header -split ";")) {
        $trimmed = $part.Trim()
        if ([string]::IsNullOrWhiteSpace($trimmed)) {
            continue
        }
        $nameValue = $trimmed.Split("=", 2)
        if ($nameValue.Count -ne 2) {
            continue
        }
        $cookie = New-Object System.Net.Cookie
        $cookie.Name = $nameValue[0].Trim()
        $cookie.Value = $nameValue[1]
        $cookie.Path = "/"
        $cookie.Domain = $baseUri.Host
        $session.Cookies.Add($baseUri, $cookie)
    }
    return $session
}

function New-JiraSession {
    $credential = Resolve-Credential
    $body = @{ username = $credential.Username; password = $credential.Password } | ConvertTo-Json -Depth 4 -Compress
    Invoke-RestMethod -Uri "$BaseUrl/rest/auth/1/session" `
        -Method Post `
        -Body $body `
        -ContentType "application/json" `
        -SessionVariable jiraSession `
        -ErrorAction Stop | Out-Null
    return $jiraSession
}

function Get-RequestContext {
    if ($AuthMethod -eq "Basic") {
        return @{
            Headers = Get-BasicAuthHeaders
            WebSession = $null
        }
    }

    if ($AuthMethod -eq "SessionCookie") {
        if ([string]::IsNullOrWhiteSpace($CookieHeader)) {
            throw "Missing JIRA cookie. Set JIRA_COOKIE or pass -CookieHeader."
        }
        return @{
            Headers = @{}
            WebSession = New-WebSessionFromCookieHeader -Header $CookieHeader
        }
    }

    return @{
        Headers = @{}
        WebSession = New-JiraSession
    }
}

function Invoke-JiraApi {
    param(
        [Parameter(Mandatory = $true)][string]$ApiPath,
        [ValidateSet("Get", "Post", "Put", "Delete")][string]$HttpMethod = "Get",
        [hashtable]$Query = @{},
        $BodyObject = $null,
        [string]$ContentType = "application/json",
        [hashtable]$ExtraHeaders = @{}
    )

    $context = Get-RequestContext
    $headers = @{}
    foreach ($key in $context.Headers.Keys) { $headers[$key] = $context.Headers[$key] }
    foreach ($key in $ExtraHeaders.Keys) { $headers[$key] = $ExtraHeaders[$key] }

    $queryString = ConvertTo-QueryString -Query $Query
    $uri = "$BaseUrl$ApiPath"
    if (-not [string]::IsNullOrWhiteSpace($queryString)) {
        $uri = "$uri`?$queryString"
    }

    $parameters = @{
        Uri = $uri
        Method = $HttpMethod
        Headers = $headers
        ErrorAction = "Stop"
    }
    if ($context.WebSession) {
        $parameters.WebSession = $context.WebSession
    }
    if ($null -ne $BodyObject) {
        $parameters.Body = ($BodyObject | ConvertTo-Json -Depth 30 -Compress)
        $parameters.ContentType = $ContentType
    }

    return Invoke-RestMethod @parameters
}

function ConvertFrom-BodyJson {
    if ([string]::IsNullOrWhiteSpace($BodyJson)) {
        return $null
    }
    return $BodyJson | ConvertFrom-Json
}

function Show-Result {
    param($Object)

    if ($RawJson) {
        $Object | ConvertTo-Json -Depth 40
        return
    }

    switch ($Action) {
        "Search" {
            $Object.issues | Select-Object key,
                @{ Name = "summary"; Expression = { $_.fields.summary } },
                @{ Name = "status"; Expression = { $_.fields.status.name } },
                @{ Name = "assignee"; Expression = { if ($_.fields.assignee) { $_.fields.assignee.displayName } else { "" } } },
                @{ Name = "updated"; Expression = { $_.fields.updated } }
        }
        "Projects" {
            $Object | Select-Object key, name, id, projectTypeKey, lead
        }
        default {
            $Object
        }
    }
}

try {
    switch ($Action) {
        "Search" {
            $query = @{
                jql = $Jql
                startAt = $StartAt
                maxResults = $MaxResults
            }
            if (-not [string]::IsNullOrWhiteSpace($Fields)) {
                $query.fields = $Fields
            }
            $result = Invoke-JiraApi -ApiPath "/rest/api/2/search" -Query $query
            Show-Result $result
        }
        "Issue" {
            if ([string]::IsNullOrWhiteSpace($IssueKey)) { throw "Missing -IssueKey." }
            $query = @{}
            if (-not [string]::IsNullOrWhiteSpace($Fields)) { $query.fields = $Fields }
            $result = Invoke-JiraApi -ApiPath "/rest/api/2/issue/$IssueKey" -Query $query
            Show-Result $result
        }
        "CreateIssue" {
            $body = ConvertFrom-BodyJson
            if (-not $body) {
                if ([string]::IsNullOrWhiteSpace($ProjectKey)) { throw "Missing -ProjectKey." }
                if ([string]::IsNullOrWhiteSpace($Summary)) { throw "Missing -Summary." }
                $body = @{
                    fields = @{
                        project = @{ key = $ProjectKey }
                        summary = $Summary
                        description = $Description
                        issuetype = @{ name = $IssueType }
                    }
                }
            }
            $result = Invoke-JiraApi -ApiPath "/rest/api/2/issue" -HttpMethod Post -BodyObject $body
            Show-Result $result
        }
        "UpdateIssue" {
            if ([string]::IsNullOrWhiteSpace($IssueKey)) { throw "Missing -IssueKey." }
            $body = ConvertFrom-BodyJson
            if (-not $body) {
                $fieldsObject = @{}
                if (-not [string]::IsNullOrWhiteSpace($Summary)) { $fieldsObject.summary = $Summary }
                if (-not [string]::IsNullOrWhiteSpace($Description)) { $fieldsObject.description = $Description }
                if ($fieldsObject.Count -eq 0) { throw "Missing update content. Pass -BodyJson, -Summary, or -Description." }
                $body = @{ fields = $fieldsObject }
            }
            $result = Invoke-JiraApi -ApiPath "/rest/api/2/issue/$IssueKey" -HttpMethod Put -BodyObject $body
            Show-Result $result
        }
        "DeleteIssue" {
            if ([string]::IsNullOrWhiteSpace($IssueKey)) { throw "Missing -IssueKey." }
            $result = Invoke-JiraApi -ApiPath "/rest/api/2/issue/$IssueKey" -HttpMethod Delete
            Show-Result $result
        }
        "AddComment" {
            if ([string]::IsNullOrWhiteSpace($IssueKey)) { throw "Missing -IssueKey." }
            if ([string]::IsNullOrWhiteSpace($Comment)) { throw "Missing -Comment." }
            $result = Invoke-JiraApi -ApiPath "/rest/api/2/issue/$IssueKey/comment" -HttpMethod Post -BodyObject @{ body = $Comment }
            Show-Result $result
        }
        "Assign" {
            if ([string]::IsNullOrWhiteSpace($IssueKey)) { throw "Missing -IssueKey." }
            if ([string]::IsNullOrWhiteSpace($Assignee)) { throw "Missing -Assignee." }
            $result = Invoke-JiraApi -ApiPath "/rest/api/2/issue/$IssueKey/assignee" -HttpMethod Put -BodyObject @{ name = $Assignee }
            Show-Result $result
        }
        "Transitions" {
            if ([string]::IsNullOrWhiteSpace($IssueKey)) { throw "Missing -IssueKey." }
            $result = Invoke-JiraApi -ApiPath "/rest/api/2/issue/$IssueKey/transitions"
            Show-Result $result
        }
        "Transition" {
            if ([string]::IsNullOrWhiteSpace($IssueKey)) { throw "Missing -IssueKey." }
            if ([string]::IsNullOrWhiteSpace($TransitionId)) { throw "Missing -TransitionId." }
            $body = ConvertFrom-BodyJson
            if (-not $body) {
                $body = @{ transition = @{ id = $TransitionId } }
            }
            $result = Invoke-JiraApi -ApiPath "/rest/api/2/issue/$IssueKey/transitions" -HttpMethod Post -BodyObject $body
            Show-Result $result
        }
        "Projects" {
            $result = Invoke-JiraApi -ApiPath "/rest/api/2/project"
            Show-Result $result
        }
        "Project" {
            if ([string]::IsNullOrWhiteSpace($ProjectKey)) { throw "Missing -ProjectKey." }
            $result = Invoke-JiraApi -ApiPath "/rest/api/2/project/$ProjectKey"
            Show-Result $result
        }
        "IssueTypes" {
            $result = Invoke-JiraApi -ApiPath "/rest/api/2/issuetype"
            Show-Result $result
        }
        "Statuses" {
            $result = Invoke-JiraApi -ApiPath "/rest/api/2/status"
            Show-Result $result
        }
        "ServerInfo" {
            $result = Invoke-JiraApi -ApiPath "/rest/api/2/serverInfo"
            Show-Result $result
        }
        "Myself" {
            $result = Invoke-JiraApi -ApiPath "/rest/api/2/myself"
            Show-Result $result
        }
        "RemoteLinks" {
            if ([string]::IsNullOrWhiteSpace($IssueKey)) { throw "Missing -IssueKey." }
            $result = Invoke-JiraApi -ApiPath "/rest/api/2/issue/$IssueKey/remotelink"
            Show-Result $result
        }
        "AddRemoteLink" {
            if ([string]::IsNullOrWhiteSpace($IssueKey)) { throw "Missing -IssueKey." }
            $body = ConvertFrom-BodyJson
            if (-not $body) {
                if ([string]::IsNullOrWhiteSpace($RemoteUrl)) { throw "Missing -RemoteUrl." }
                if ([string]::IsNullOrWhiteSpace($RemoteTitle)) { throw "Missing -RemoteTitle." }
                $body = @{
                    object = @{
                        url = $RemoteUrl
                        title = $RemoteTitle
                    }
                    relationship = $Relationship
                }
            }
            $result = Invoke-JiraApi -ApiPath "/rest/api/2/issue/$IssueKey/remotelink" -HttpMethod Post -BodyObject $body
            Show-Result $result
        }
        "AttachFile" {
            if ($PSVersionTable.PSVersion.Major -lt 6) {
                throw "AttachFile requires PowerShell 7 or newer because it uses Invoke-RestMethod -Form."
            }
            if ([string]::IsNullOrWhiteSpace($IssueKey)) { throw "Missing -IssueKey." }
            if (-not (Test-Path -LiteralPath $FilePath)) { throw "File not found: $FilePath" }
            $context = Get-RequestContext
            $headers = @{}
            foreach ($key in $context.Headers.Keys) { $headers[$key] = $context.Headers[$key] }
            $headers["X-Atlassian-Token"] = "no-check"
            $parameters = @{
                Uri = "$BaseUrl/rest/api/2/issue/$IssueKey/attachments"
                Method = "Post"
                Headers = $headers
                Form = @{ file = Get-Item -LiteralPath $FilePath }
                ErrorAction = "Stop"
            }
            if ($context.WebSession) { $parameters.WebSession = $context.WebSession }
            $result = Invoke-RestMethod @parameters
            Show-Result $result
        }
        "Raw" {
            if ([string]::IsNullOrWhiteSpace($Path)) { throw "Missing -Path." }
            $body = ConvertFrom-BodyJson
            $result = Invoke-JiraApi -ApiPath $Path -HttpMethod $Method -BodyObject $body
            Show-Result $result
        }
    }
} catch {
    $message = $_.Exception.Message
    Write-Error "JIRA API request failed: $message"
    if ($_.Exception.Response) {
        $statusCode = $_.Exception.Response.StatusCode.value__
        Write-Error "HTTP status: $statusCode"
    }
    exit 1
}
