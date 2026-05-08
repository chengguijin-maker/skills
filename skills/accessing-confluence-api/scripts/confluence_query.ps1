<#
.SYNOPSIS
    Scripted Confluence Server REST API helper.
.DESCRIPTION
    Provides a stable command line interface for common Confluence Server 6.13
    REST API operations. Credentials are read from parameters, environment
    variables, or an optional DPAPI encrypted credential file. No password is
    stored in this script.
#>

param(
    [ValidateSet(
        "Search",
        "Page",
        "CreatePage",
        "UpdatePage",
        "DeletePage",
        "Children",
        "Comments",
        "AddComment",
        "Attachments",
        "UploadAttachment",
        "Spaces",
        "Space",
        "Labels",
        "Restrictions",
        "ConvertBody",
        "Raw"
    )]
    [string]$Action = "Search",

    [string]$BaseUrl = $(if ($env:CONFLUENCE_BASE_URL) { $env:CONFLUENCE_BASE_URL } else { "http://dmtks.hisense.com" }),
    [ValidateSet("Basic", "Session", "SessionCookie")]
    [string]$AuthMethod = $(if ($env:CONFLUENCE_AUTH_METHOD) { $env:CONFLUENCE_AUTH_METHOD } else { "Session" }),
    [string]$Username = $env:CONFLUENCE_USERNAME,
    [string]$PasswordPlainText = $env:CONFLUENCE_PASSWORD,
    [string]$CookieHeader = $env:CONFLUENCE_COOKIE,
    [string]$CredentialPath = (Join-Path (Split-Path $PSScriptRoot -Parent) "confluence_credential.xml"),

    [string]$Cql = "type=page AND space=DZKJSZDSPT ORDER BY lastModified DESC",
    [int]$Start = 0,
    [int]$Limit = 25,
    [string]$Expand = "space,version",

    [string]$PageId = "",
    [string]$SpaceKey = "",
    [string]$Title = "",
    [string]$StorageValue = "",
    [string]$ParentPageId = "",
    [int]$VersionNumber = 0,
    [string]$Comment = "",
    [string]$FilePath = "",
    [string]$ConvertTo = "storage",
    [string]$Representation = "storage",

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
        $script:Username = Read-Host "Confluence username"
    }

    $securePassword = Read-Host "Confluence password for $script:Username" -AsSecureString
    $credential = New-Object System.Management.Automation.PSCredential($script:Username, $securePassword)
    $credential | Export-Clixml -LiteralPath $CredentialPath
    Write-Host "Confluence credential saved with Windows DPAPI: $CredentialPath"
    return $credential
}

function Resolve-Credential {
    $credential = Get-StoredCredential
    if ([string]::IsNullOrWhiteSpace($script:Username) -and $credential) {
        $script:Username = $credential.UserName
    }

    if (-not [string]::IsNullOrWhiteSpace($PasswordPlainText)) {
        if ([string]::IsNullOrWhiteSpace($script:Username)) {
            $script:Username = Read-Host "Confluence username"
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

function New-ConfluenceSession {
    $credential = Resolve-Credential
    Invoke-WebRequest -Uri "$BaseUrl/login.action" `
        -Method Post `
        -Body @{ os_username = $credential.Username; os_password = $credential.Password; os_cookie = "true" } `
        -SessionVariable confluenceSession `
        -MaximumRedirection 5 `
        -ErrorAction Stop | Out-Null
    return $confluenceSession
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
            throw "Missing Confluence cookie. Set CONFLUENCE_COOKIE or pass -CookieHeader."
        }
        return @{
            Headers = @{}
            WebSession = New-WebSessionFromCookieHeader -Header $CookieHeader
        }
    }

    return @{
        Headers = @{}
        WebSession = New-ConfluenceSession
    }
}

function ConvertFrom-ConfluenceResponse {
    param($Response)

    if ($null -eq $Response) {
        return $null
    }

    $contentText = [string]$Response.Content

    try {
        $latinBytes = [Text.Encoding]::GetEncoding("iso-8859-1").GetBytes($contentText)
        $decodedText = [Text.Encoding]::UTF8.GetString($latinBytes)
        if ($decodedText -match "[\u4e00-\u9fff]") {
            $contentText = $decodedText
        }
    } catch {
        $contentText = [string]$Response.Content
    }

    if ([string]::IsNullOrWhiteSpace($contentText)) {
        return $null
    }

    $contentType = [string]$Response.Headers["Content-Type"]
    if ($contentType -match "json" -or $contentText.TrimStart().StartsWith("{") -or $contentText.TrimStart().StartsWith("[")) {
        return $contentText | ConvertFrom-Json
    }

    return $contentText
}

function Invoke-ConfluenceApi {
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
    if ($PSVersionTable.PSVersion.Major -lt 6) {
        $parameters.UseBasicParsing = $true
    }
    if ($context.WebSession) {
        $parameters.WebSession = $context.WebSession
    }
    if ($null -ne $BodyObject) {
        $parameters.Body = ($BodyObject | ConvertTo-Json -Depth 40 -Compress)
        $parameters.ContentType = $ContentType
    }

    $response = Invoke-WebRequest @parameters
    return ConvertFrom-ConfluenceResponse -Response $response
}

function ConvertFrom-BodyJson {
    if ([string]::IsNullOrWhiteSpace($BodyJson)) {
        return $null
    }
    return $BodyJson | ConvertFrom-Json
}

function Get-CurrentPage {
    param([Parameter(Mandatory = $true)][string]$Id)
    return Invoke-ConfluenceApi -ApiPath "/rest/api/content/$Id" -Query @{ expand = "version,space,body.storage" }
}

function New-PageBody {
    param(
        [Parameter(Mandatory = $true)][string]$PageTitle,
        [Parameter(Mandatory = $true)][string]$PageSpaceKey,
        [Parameter(Mandatory = $true)][string]$PageStorageValue,
        [string]$AncestorId = "",
        [int]$PageVersionNumber = 0
    )

    $body = @{
        type = "page"
        title = $PageTitle
        space = @{ key = $PageSpaceKey }
        body = @{
            storage = @{
                value = $PageStorageValue
                representation = "storage"
            }
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($AncestorId)) {
        $body.ancestors = @(@{ id = $AncestorId })
    }
    if ($PageVersionNumber -gt 0) {
        $body.version = @{ number = $PageVersionNumber }
    }

    return $body
}

function Show-Result {
    param($Object)

    if ($RawJson) {
        $Object | ConvertTo-Json -Depth 50
        return
    }

    switch ($Action) {
        "Search" {
            $Object.results | Select-Object id, type, title,
                @{ Name = "space"; Expression = { if ($_.space) { $_.space.key } else { "" } } },
                @{ Name = "version"; Expression = { if ($_.version) { $_.version.number } else { "" } } },
                @{ Name = "link"; Expression = { $_._links.webui } }
        }
        "Spaces" {
            $Object.results | Select-Object key, name, type, status
        }
        default {
            $Object
        }
    }
}

try {
    switch ($Action) {
        "Search" {
            $result = Invoke-ConfluenceApi -ApiPath "/rest/api/content/search" -Query @{
                cql = $Cql
                start = $Start
                limit = $Limit
                expand = $Expand
            }
            Show-Result $result
        }
        "Page" {
            if ([string]::IsNullOrWhiteSpace($PageId)) { throw "Missing -PageId." }
            $result = Invoke-ConfluenceApi -ApiPath "/rest/api/content/$PageId" -Query @{ expand = $Expand }
            Show-Result $result
        }
        "CreatePage" {
            $body = ConvertFrom-BodyJson
            if (-not $body) {
                if ([string]::IsNullOrWhiteSpace($SpaceKey)) { throw "Missing -SpaceKey." }
                if ([string]::IsNullOrWhiteSpace($Title)) { throw "Missing -Title." }
                if ([string]::IsNullOrWhiteSpace($StorageValue)) { throw "Missing -StorageValue." }
                $body = New-PageBody -PageTitle $Title -PageSpaceKey $SpaceKey -PageStorageValue $StorageValue -AncestorId $ParentPageId
            }
            $result = Invoke-ConfluenceApi -ApiPath "/rest/api/content" -HttpMethod Post -BodyObject $body
            Show-Result $result
        }
        "UpdatePage" {
            if ([string]::IsNullOrWhiteSpace($PageId)) { throw "Missing -PageId." }
            $body = ConvertFrom-BodyJson
            if (-not $body) {
                $current = Get-CurrentPage -Id $PageId
                $nextVersion = if ($VersionNumber -gt 0) { $VersionNumber } else { [int]$current.version.number + 1 }
                $pageTitle = if (-not [string]::IsNullOrWhiteSpace($Title)) { $Title } else { $current.title }
                $pageSpaceKey = if (-not [string]::IsNullOrWhiteSpace($SpaceKey)) { $SpaceKey } else { $current.space.key }
                $pageStorage = if (-not [string]::IsNullOrWhiteSpace($StorageValue)) { $StorageValue } else { $current.body.storage.value }
                $body = New-PageBody -PageTitle $pageTitle -PageSpaceKey $pageSpaceKey -PageStorageValue $pageStorage -PageVersionNumber $nextVersion
                $body.id = $PageId
            }
            $result = Invoke-ConfluenceApi -ApiPath "/rest/api/content/$PageId" -HttpMethod Put -BodyObject $body
            Show-Result $result
        }
        "DeletePage" {
            if ([string]::IsNullOrWhiteSpace($PageId)) { throw "Missing -PageId." }
            $result = Invoke-ConfluenceApi -ApiPath "/rest/api/content/$PageId" -HttpMethod Delete
            Show-Result $result
        }
        "Children" {
            if ([string]::IsNullOrWhiteSpace($PageId)) { throw "Missing -PageId." }
            $result = Invoke-ConfluenceApi -ApiPath "/rest/api/content/$PageId/child/page" -Query @{ limit = $Limit; expand = $Expand }
            Show-Result $result
        }
        "Comments" {
            if ([string]::IsNullOrWhiteSpace($PageId)) { throw "Missing -PageId." }
            $result = Invoke-ConfluenceApi -ApiPath "/rest/api/content/$PageId/child/comment" -Query @{ limit = $Limit; expand = $Expand }
            Show-Result $result
        }
        "AddComment" {
            if ([string]::IsNullOrWhiteSpace($PageId)) { throw "Missing -PageId." }
            if ([string]::IsNullOrWhiteSpace($Comment)) { throw "Missing -Comment." }
            $body = @{
                type = "comment"
                container = @{ id = $PageId; type = "page" }
                body = @{
                    storage = @{
                        value = $Comment
                        representation = "storage"
                    }
                }
            }
            $result = Invoke-ConfluenceApi -ApiPath "/rest/api/content" -HttpMethod Post -BodyObject $body
            Show-Result $result
        }
        "Attachments" {
            if ([string]::IsNullOrWhiteSpace($PageId)) { throw "Missing -PageId." }
            $result = Invoke-ConfluenceApi -ApiPath "/rest/api/content/$PageId/child/attachment" -Query @{ limit = $Limit; expand = $Expand }
            Show-Result $result
        }
        "UploadAttachment" {
            if ($PSVersionTable.PSVersion.Major -lt 6) {
                throw "UploadAttachment requires PowerShell 7 or newer because it uses Invoke-RestMethod -Form."
            }
            if ([string]::IsNullOrWhiteSpace($PageId)) { throw "Missing -PageId." }
            if (-not (Test-Path -LiteralPath $FilePath)) { throw "File not found: $FilePath" }
            $context = Get-RequestContext
            $headers = @{}
            foreach ($key in $context.Headers.Keys) { $headers[$key] = $context.Headers[$key] }
            $headers["X-Atlassian-Token"] = "no-check"
            $parameters = @{
                Uri = "$BaseUrl/rest/api/content/$PageId/child/attachment"
                Method = "Post"
                Headers = $headers
                Form = @{ file = Get-Item -LiteralPath $FilePath }
                ErrorAction = "Stop"
            }
            if ($context.WebSession) { $parameters.WebSession = $context.WebSession }
            $result = Invoke-RestMethod @parameters
            Show-Result $result
        }
        "Spaces" {
            $result = Invoke-ConfluenceApi -ApiPath "/rest/api/space" -Query @{ limit = $Limit }
            Show-Result $result
        }
        "Space" {
            if ([string]::IsNullOrWhiteSpace($SpaceKey)) { throw "Missing -SpaceKey." }
            $result = Invoke-ConfluenceApi -ApiPath "/rest/api/space/$SpaceKey"
            Show-Result $result
        }
        "Labels" {
            if ([string]::IsNullOrWhiteSpace($PageId)) { throw "Missing -PageId." }
            $result = Invoke-ConfluenceApi -ApiPath "/rest/api/content/$PageId/label"
            Show-Result $result
        }
        "Restrictions" {
            if ([string]::IsNullOrWhiteSpace($PageId)) { throw "Missing -PageId." }
            $result = Invoke-ConfluenceApi -ApiPath "/rest/api/content/$PageId/restriction"
            Show-Result $result
        }
        "ConvertBody" {
            if ([string]::IsNullOrWhiteSpace($StorageValue)) { throw "Missing -StorageValue." }
            $body = @{
                value = $StorageValue
                representation = $Representation
            }
            $result = Invoke-ConfluenceApi -ApiPath "/rest/api/contentbody/convert/$ConvertTo" -HttpMethod Post -BodyObject $body
            Show-Result $result
        }
        "Raw" {
            if ([string]::IsNullOrWhiteSpace($Path)) { throw "Missing -Path." }
            $body = ConvertFrom-BodyJson
            $result = Invoke-ConfluenceApi -ApiPath $Path -HttpMethod $Method -BodyObject $body
            Show-Result $result
        }
    }
} catch {
    $message = $_.Exception.Message
    Write-Error "Confluence API request failed: $message"
    if ($_.Exception.Response) {
        $statusCode = $_.Exception.Response.StatusCode.value__
        Write-Error "HTTP status: $statusCode"
    }
    exit 1
}
