<#
.SYNOPSIS
    Hisense Coremail API helper.
.DESCRIPTION
    Calls Coremail webmail APIs with an existing browser session.
    The sid and Cookie header must come from the same logged-in Coremail session.
    Passwords are intentionally not stored in this script.
.EXAMPLE
    $env:COREMAIL_SID = "current_sid"
    $env:COREMAIL_COOKIE = "Coremail.sid=current_sid; Coremail=..."
    .\coremail_query.ps1 -Action Folders
.EXAMPLE
    .\coremail_query.ps1 -Action Threads -FolderId 2778360 -Limit 20
.EXAMPLE
    .\coremail_query.ps1 -Action Read -MessageId "1:1tbiAQsCEGn8QvUR-QAAsW" -MarkRead:$false
#>

param(
    [ValidateSet(
        "Folders",
        "Threads",
        "ThreadMessages",
        "Read",
        "Tags",
        "UserAttrs",
        "Faces",
        "Contacts",
        "OrgDomains",
        "History",
        "OffSiteRemind",
        "Search"
    )]
    [string]$Action = "Folders",

    [string]$Sid = $env:COREMAIL_SID,
    [string]$CookieHeader = $env:COREMAIL_COOKIE,
    [switch]$AutoLogin,
    [string]$Username = $env:COREMAIL_USERNAME,
    [string]$PasswordPlainText = $env:COREMAIL_PASSWORD,
    [string]$BaseUrl = "https://mail.hisense.com",

    [int]$FolderId = 1,
    [string]$MessageId = "",
    [string]$Keyword = "",
    [int]$Start = 0,
    [int]$Limit = 20,
    [string]$Order = "receivedDate",
    [switch]$RawJson,
    [bool]$MarkRead = $true
)

$ErrorActionPreference = "Stop"

function Assert-CoremailSession {
    if (($AutoLogin -or $env:COREMAIL_AUTO_LOGIN -eq "1") -and
        ([string]::IsNullOrWhiteSpace($Sid) -or [string]::IsNullOrWhiteSpace($CookieHeader))) {
        $loginScript = Join-Path $PSScriptRoot "coremail_login.ps1"
        if (-not (Test-Path -LiteralPath $loginScript)) {
            throw "AutoLogin requested, but coremail_login.ps1 was not found."
        }

        $loginArgs = @{}
        if (-not [string]::IsNullOrWhiteSpace($Username)) {
            $loginArgs["Username"] = $Username
        }
        if (-not [string]::IsNullOrWhiteSpace($PasswordPlainText)) {
            $loginArgs["PasswordPlainText"] = $PasswordPlainText
        }

        & $loginScript @loginArgs | Out-Null
        $script:Sid = $env:COREMAIL_SID
        $script:CookieHeader = $env:COREMAIL_COOKIE
    }

    if ([string]::IsNullOrWhiteSpace($Sid)) {
        throw "Missing Sid. Set COREMAIL_SID or pass -Sid."
    }
    if ([string]::IsNullOrWhiteSpace($CookieHeader)) {
        throw "Missing Cookie header. Set COREMAIL_COOKIE or pass -CookieHeader."
    }
    if ($CookieHeader -notmatch [regex]::Escape($Sid)) {
        Write-Warning "Cookie header does not contain the sid. Coremail may return Cookie not matched."
    }
}

function Get-CoremailHeaders {
    param([string]$ContentType = 'text/x-json; tz="Asia/Shanghai"')

    return @{
        "Accept" = "text/x-json"
        "Content-Type" = $ContentType
        "X-Requested-With" = "XMLHttpRequest"
        "Origin" = $BaseUrl
        "Referer" = "$BaseUrl/coremail/XT/index.jsp?sid=$Sid"
        "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36"
    }
}

function New-CoremailWebSession {
    $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
    $baseUri = [uri]$BaseUrl

    foreach ($part in ($CookieHeader -split ';')) {
        $trimmed = $part.Trim()
        if ([string]::IsNullOrWhiteSpace($trimmed)) {
            continue
        }

        $nameValue = $trimmed.Split('=', 2)
        if ($nameValue.Count -ne 2) {
            continue
        }

        $cookie = New-Object System.Net.Cookie
        $cookie.Name = $nameValue[0].Trim()
        $cookie.Value = $nameValue[1]
        $cookie.Path = "/"
        $cookie.Domain = $baseUri.Host
        $session.Cookies.Add($baseUri, $cookie)

        if ($baseUri.Host.EndsWith(".hisense.com")) {
            $parentCookie = New-Object System.Net.Cookie
            $parentCookie.Name = $cookie.Name
            $parentCookie.Value = $cookie.Value
            $parentCookie.Path = "/"
            $parentCookie.Domain = ".hisense.com"
            $session.Cookies.Add($baseUri, $parentCookie)
        }
    }

    return $session
}

function Invoke-CoremailJson {
    param(
        [Parameter(Mandatory = $true)][string]$Func,
        [Parameter(Mandatory = $true)]$BodyObject
    )

    $funcEncoded = [uri]::EscapeDataString($Func)
    $uri = "$BaseUrl/coremail/s/json?sid=$([uri]::EscapeDataString($Sid))&func=$funcEncoded"
    $body = $BodyObject | ConvertTo-Json -Depth 20 -Compress
    $headers = Get-CoremailHeaders
    $webSession = New-CoremailWebSession

    $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body -WebSession $webSession -ErrorAction Stop
    if ($response.code -and $response.code -ne "S_OK") {
        $message = ($response.messages | ConvertTo-Json -Depth 6 -Compress)
        throw "Coremail API failed. code=$($response.code) detail=$message"
    }
    return $response
}

function Invoke-CoremailForm {
    param(
        [Parameter(Mandatory = $true)][string]$PathAndQuery,
        [Parameter(Mandatory = $true)][hashtable]$BodyTable
    )

    $uri = "$BaseUrl$PathAndQuery"
    $headers = Get-CoremailHeaders -ContentType "application/x-www-form-urlencoded; charset=UTF-8"
    $webSession = New-CoremailWebSession
    $pairs = foreach ($key in $BodyTable.Keys) {
        "$([uri]::EscapeDataString([string]$key))=$([uri]::EscapeDataString([string]$BodyTable[$key]))"
    }
    $body = $pairs -join "&"

    $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body -WebSession $webSession -ErrorAction Stop
    if ($response.code -and $response.code -ne "S_OK") {
        $message = ($response.messages | ConvertTo-Json -Depth 6 -Compress)
        throw "Coremail API failed. code=$($response.code) detail=$message"
    }
    return $response
}

function Convert-HtmlToText {
    param([string]$Html)

    if ([string]::IsNullOrWhiteSpace($Html)) {
        return ""
    }

    $text = $Html -replace '<br\s*/?>', "`n"
    $text = $text -replace '</p>', "`n"
    $text = $text -replace '<[^>]+>', ''
    $text = [System.Net.WebUtility]::HtmlDecode($text)
    return ($text -replace "`r", "").Trim()
}

function Show-JsonOrObject {
    param($Object)

    if ($RawJson) {
        $Object | ConvertTo-Json -Depth 30
    } else {
        $Object
    }
}

Assert-CoremailSession

switch ($Action) {
    "Folders" {
        $path = "/coremail/XT/jsp/mail.jsp?func=getAllFolders&sid=$([uri]::EscapeDataString($Sid))"
        $result = Invoke-CoremailForm -PathAndQuery $path -BodyTable @{ stats = "true"; threads = "true" }
        if ($RawJson) {
            Show-JsonOrObject $result
        } else {
            $result.var | Select-Object id, name,
                @{ Name = "messages"; Expression = { $_.stats.messageCount } },
                @{ Name = "unread"; Expression = { $_.stats.unreadMessageCount } },
                @{ Name = "threads"; Expression = { $_.stats.threadCount } },
                @{ Name = "unreadThreads"; Expression = { $_.stats.unreadThreadCount } }
        }
    }

    "Threads" {
        $body = @{
            start = $Start
            limit = $Limit
            mode = "count"
            order = $Order
            desc = $true
            returnTotal = $true
            returnTag = $true
            summaryWindowSize = 100
            fid = $FolderId
            mboxa = ""
            topFirst = $true
        }
        $result = Invoke-CoremailJson -Func "mbox:listThreads" -BodyObject $body
        if ($RawJson) {
            Show-JsonOrObject $result
        } else {
            $result.var | Select-Object id, fid, subject, from, to, sentDate, receivedDate, size,
                @{ Name = "read"; Expression = { $_.flags.read } },
                threadMessageCount, summary
        }
    }

    "ThreadMessages" {
        if ([string]::IsNullOrWhiteSpace($MessageId)) {
            throw "Missing -MessageId."
        }
        $body = @{
            id = $MessageId
            mboxa = ""
            order = "date"
            summaryWindowSize = 2147483647
            returnTag = $true
        }
        $result = Invoke-CoremailJson -Func "mbox:getThreadMessageInfos" -BodyObject $body
        if ($RawJson) {
            Show-JsonOrObject $result
        } else {
            $result.var | Select-Object id, fid, subject, from, to, sentDate, receivedDate, size,
                @{ Name = "read"; Expression = { $_.flags.read } },
                summary
        }
    }

    "Read" {
        if ([string]::IsNullOrWhiteSpace($MessageId)) {
            throw "Missing -MessageId."
        }
        $path = "/coremail/XT/jsp/readMessage.jsp"
        $result = Invoke-CoremailForm -PathAndQuery $path -BodyTable @{
            mid = $MessageId
            part = ""
            mboxa = ""
            mailCipherPassword = ""
            markRead = ([string]$MarkRead).ToLowerInvariant()
        }
        if ($RawJson) {
            Show-JsonOrObject $result
        } else {
            $mail = $result.var.mail
            [pscustomobject]@{
                subject = $mail.subject
                from = ($mail.from -join "; ")
                to = ($mail.to -join "; ")
                cc = ($mail.cc -join "; ")
                attachments = @($mail.attachments).Count
                bodyText = Convert-HtmlToText $mail.mainPartData.content
            }
        }
    }

    "Tags" {
        $result = Invoke-CoremailJson -Func "mbox:listTags" -BodyObject @{ mboxa = "" }
        Show-JsonOrObject $result
    }

    "UserAttrs" {
        $result = Invoke-CoremailJson -Func "user:getAttrs" -BodyObject @{
            optionalAttrIds = @(
                "email",
                "true_name",
                "@ou",
                "safelist",
                "refuselist",
                "preview_layout",
                "maxlist",
                "read_filter_img",
                "auto_mark_read",
                "login_area_range",
                '$ai'
            )
        }
        Show-JsonOrObject $result
    }

    "Faces" {
        $result = Invoke-CoremailJson -Func "user:getFaces" -BodyObject @{ useExtOptions = $true }
        Show-JsonOrObject $result
    }

    "Contacts" {
        $result = Invoke-CoremailJson -Func "pab:searchContacts" -BodyObject @{
            returnAttrs = @("id", "groups", "FN", "EMAIL;PREF", "TEL;CELL;VOICE")
            fullPY = $true
        }
        if ($RawJson) {
            Show-JsonOrObject $result
        } else {
            $result.var | Select-Object id, FN, "EMAIL;PREF", "TEL;CELL;VOICE"
        }
    }

    "OrgDomains" {
        $path = "/coremail/XT/jsp/setting.jsp?func=user:getAllOrgDomains&seed&sid=$([uri]::EscapeDataString($Sid))"
        $result = Invoke-CoremailForm -PathAndQuery $path -BodyTable @{}
        Show-JsonOrObject $result
    }

    "History" {
        $result = Invoke-CoremailJson -Func "mq:historyQuery" -BodyObject @{ key = @{}; limit = $Limit }
        Show-JsonOrObject $result
    }

    "OffSiteRemind" {
        $result = Invoke-CoremailForm -PathAndQuery "/coremail/s/json?sid=$([uri]::EscapeDataString($Sid))&func=user%3AoffSiteRemind" -BodyTable @{}
        Show-JsonOrObject $result
    }

    "Search" {
        if ([string]::IsNullOrWhiteSpace($Keyword)) {
            throw "Missing -Keyword."
        }
        $body = @{
            start = $Start
            limit = $Limit
            keyword = $Keyword
            order = "date"
            desc = $true
            returnTotal = $true
            mboxa = ""
        }
        $result = Invoke-CoremailJson -Func "mail:searchMessages" -BodyObject $body
        Show-JsonOrObject $result
    }
}
