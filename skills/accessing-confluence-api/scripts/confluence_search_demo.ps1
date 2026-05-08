<#
.SYNOPSIS
    Confluence CQL Search Techniques Demo
.DESCRIPTION
    Demonstrates all advanced CQL search techniques:
    - Operators: =, ~, !=, >, <, IN, NOT IN, IS, IS NOT
    - Functions: currentUser(), startOfYear(), startOfMonth(), startOfWeek(), now()
    - Fields: favourite, macro, parent, contributor, mention, label, title, text
    - Sorting: ORDER BY with DESC/ASC
    - Pagination with _links.next
    - Chinese full-text search
.NOTES
    Must be run as .ps1 file (not inline)
    Use new terminal each time (is_background=false)
.PARAMETER DemoIndex
    Run specific demo (1-12) or 0 for all demos
.EXAMPLE
    .\confluence_search_demo.ps1
    .\confluence_search_demo.ps1 -DemoIndex 3
#>

param(
    [ValidateSet("Basic", "Session")]
    [string]$AuthMethod = "Session",
    [int]$DemoIndex = 0
)

$ErrorActionPreference = "Stop"
$CONF_URL = "http://dmtks.hisense.com"
$USERNAME = $env:CONFLUENCE_USERNAME
$PASSWORD = $env:CONFLUENCE_PASSWORD

$script:cSession = $null

function Get-PlainCredential {
    if ([string]::IsNullOrWhiteSpace($USERNAME)) {
        throw "Missing username. Set CONFLUENCE_USERNAME before running this demo."
    }
    if ([string]::IsNullOrWhiteSpace($PASSWORD)) {
        throw "Missing password. Set CONFLUENCE_PASSWORD before running this demo, or use confluence_query.ps1 with a saved DPAPI credential."
    }
    return @{
        Username = $USERNAME
        Password = $PASSWORD
    }
}

function Test-Session {
    param($Session)
    if (-not $Session) { return $false }
    try {
        $t = Invoke-RestMethod -Uri "$CONF_URL/rest/api/content?limit=1" `
            -WebSession $Session -ErrorAction SilentlyContinue
        return $t -ne $null
    } catch { return $false }
}

function Get-Session {
    if (-not (Test-Session $script:cSession)) {
        Write-Host "Logging in to Confluence..." -ForegroundColor Cyan
        $credential = Get-PlainCredential
        Invoke-RestMethod -Uri "$CONF_URL/login.action" `
            -Method Post `
            -Body @{ os_username = $credential.Username; os_password = $credential.Password } `
            -SessionVariable cSession -ErrorAction Stop | Out-Null
        $script:cSession = $cSession
        Write-Host "Login OK" -ForegroundColor Green
    }
    return $script:cSession
}

function Get-BasicHeaders {
    $credential = Get-PlainCredential
    $pair = "$($credential.Username)`:$($credential.Password)"
    $bytes = [Text.Encoding]::ASCII.GetBytes($pair)
    $cred = [Convert]::ToBase64String($bytes)
    return @{ Authorization = "Basic $cred" }
}

function Search-Cql {
    param([string]$Cql, [int]$Limit = 10)
    $cqlEnc = [uri]::EscapeDataString($Cql)
    $url = "$CONF_URL/rest/api/content/search?cql=$cqlEnc&limit=$Limit&expand=space,version"
    Write-Host "  CQL: $Cql" -ForegroundColor Yellow
    if ($AuthMethod -eq "Basic") {
        Invoke-RestMethod -Uri $url -Headers (Get-BasicHeaders) -ErrorAction Stop
    } else {
        Invoke-RestMethod -Uri $url -WebSession (Get-Session) -ErrorAction Stop
    }
}

function Show-Results {
    param($Result)
    Write-Host "  Results: $($Result.size)" -ForegroundColor Green
    foreach ($p in $Result.results) {
        $id = $p.id
        $title = $p.title
        $space = if ($p.space) { $p.space.key } else { "N/A" }
        $creator = if ($p.version.by) { $p.version.by.displayName } else { "?" }
        Write-Host "  [$id] $title ($space, by: $creator)"
    }
}

try {
    Write-Host "=== Confluence CQL Search Techniques Demo ===" -ForegroundColor Cyan
    Write-Host ""

    # Demo 1: Basic = AND
    if ($DemoIndex -in 0,1) {
        Write-Host "Demo 1: Basic search with = and AND" -ForegroundColor Magenta
        Write-Host "Pattern: type=page AND space=KEY" -ForegroundColor DarkGray
        $r = Search-Cql -Cql "type=page AND space=DZKJSZDSPT" -Limit 5
        Show-Results $r
        Write-Host ""
    }

    # Demo 2: Fuzzy match ~
    if ($DemoIndex -in 0,2) {
        Write-Host "Demo 2: Title fuzzy match with ~" -ForegroundColor Magenta
        Write-Host "Pattern: title~'keyword' (LIKE semantics)" -ForegroundColor DarkGray
        $r = Search-Cql -Cql "type=page AND space=DZKJDSHWKF AND title~'ceshi'" -Limit 5
        Show-Results $r
        Write-Host ""
    }

    # Demo 3: Full-text search (text~)
    if ($DemoIndex -in 0,3) {
        Write-Host "Demo 3: Full-text search with text~ (most powerful)" -ForegroundColor Magenta
        Write-Host "Pattern: text~'keyword' searches page body content" -ForegroundColor DarkGray
        $r = Search-Cql -Cql "type=page AND text~'2Dzhuan3D'" -Limit 5
        Show-Results $r
        Write-Host ""
    }

    # Demo 4: OR combination with parentheses
    if ($DemoIndex -in 0,4) {
        Write-Host "Demo 4: Multiple conditions with OR" -ForegroundColor Magenta
        Write-Host "Pattern: (A OR B) AND C" -ForegroundColor DarkGray
        $r = Search-Cql -Cql "type=page AND space=DZKJSZDSPT AND (title~'3D' OR text~'3D')" -Limit 5
        Show-Results $r
        Write-Host ""
    }

    # Demo 5: Date range with > and <
    if ($DemoIndex -in 0,5) {
        Write-Host "Demo 5: Date range with lastModified" -ForegroundColor Magenta
        Write-Host "Pattern: lastModified > '2026-01-01' ORDER BY lastModified DESC" -ForegroundColor DarkGray
        $r = Search-Cql -Cql "type=page AND space=DZKJSZDSPT AND lastModified>2026-01-01 ORDER BY lastModified DESC" -Limit 5
        Show-Results $r
        Write-Host ""
        Write-Host "  Date functions: startOfYear(), startOfMonth(), startOfWeek(), now('-1y')" -ForegroundColor DarkGray
        Write-Host ""
    }

    # Demo 6: != and NOT IN
    if ($DemoIndex -in 0,6) {
        Write-Host "Demo 6: Exclusion with != and NOT IN" -ForegroundColor Magenta
        Write-Host "Pattern: field != value, field NOT IN (v1,v2)" -ForegroundColor DarkGray
        $r = Search-Cql -Cql "type=page AND space=DZKJSZDSPT AND title!='Home'" -Limit 5
        Show-Results $r
        Write-Host "  NOT IN example: label NOT IN (draft, review)" -ForegroundColor DarkGray
        $r2 = Search-Cql -Cql "type=page AND space=DZKJSZDSPT AND label NOT IN (draft)" -Limit 3
        Show-Results $r2
        Write-Host ""
    }

    # Demo 7: creator field
    if ($DemoIndex -in 0,7) {
        Write-Host "Demo 7: Filter by creator" -ForegroundColor Magenta
        Write-Host "Pattern: creator='username'" -ForegroundColor DarkGray
        $r = Search-Cql -Cql "type=page AND creator='liufang' AND space=DZKJDSHWKF" -Limit 5
        Show-Results $r
        Write-Host ""
    }

    # Demo 8: label field
    if ($DemoIndex -in 0,8) {
        Write-Host "Demo 8: Label search" -ForegroundColor Magenta
        Write-Host "Pattern: label='tagname'" -ForegroundColor DarkGray
        $r = Search-Cql -Cql "type=page AND space=DZKJSZDSPT AND label='workflow'" -Limit 5
        Show-Results $r
        Write-Host ""
    }

    # Demo 9: ORDER BY
    if ($DemoIndex -in 0,9) {
        Write-Host "Demo 9: Sorting with ORDER BY" -ForegroundColor Magenta
        Write-Host "Pattern: ORDER BY field [DESC]" -ForegroundColor DarkGray
        Write-Host "  Sortable fields: lastModified, created, title" -ForegroundColor DarkGray
        $r = Search-Cql -Cql "type=page AND space=DZKJSZDSPT ORDER BY created DESC" -Limit 5
        Show-Results $r
        Write-Host ""
    }

    # Demo 10: IN operator
    if ($DemoIndex -in 0,10) {
        Write-Host "Demo 10: Multi-value match with IN" -ForegroundColor Magenta
        Write-Host "Pattern: field IN (val1, val2) - shorter than multiple OR" -ForegroundColor DarkGray
        $r = Search-Cql -Cql "type IN (page, blogpost) AND space=DZKJSZDSPT ORDER BY lastModified DESC" -Limit 5
        Show-Results $r
        Write-Host ""
    }

    # Demo 11: Pagination
    if ($DemoIndex -in 0,11) {
        Write-Host "Demo 11: Pagination with _links.next" -ForegroundColor Magenta
        Write-Host "Pattern: Check _links.next for more pages" -ForegroundColor DarkGray
        $r = Search-Cql -Cql "type=page AND space=DZKJSZDSPT" -Limit 5
        Show-Results $r
        if ($r._links.next) {
            Write-Host "  Next page: $($r._links.next)" -ForegroundColor Cyan
        } else {
            Write-Host "  No more pages" -ForegroundColor Cyan
        }
        Write-Host ""
        Write-Host "  Pagination code pattern:" -ForegroundColor DarkGray
        Write-Host "    `$all = @(); `$url = '...&limit=100'" -ForegroundColor DarkGray
        Write-Host "    while (`$url) { `$r = Invoke-RestMethod -Uri `$url; `$all += `$r.results; `$url = if (`$r._links.next) { `$CONF_URL + `$r._links.next } else { `$null } }" -ForegroundColor DarkGray
        Write-Host ""
    }

    # Demo 12: Advanced combinations
    if ($DemoIndex -in 0,12) {
        Write-Host "Demo 12: Advanced combinations for 2D-to-3D project" -ForegroundColor Magenta
        Write-Host "  Multi-space + multi-keyword:" -ForegroundColor DarkGray
        $r = Search-Cql -Cql "type=page AND space IN (DZKJSZDSPT, DZKJDSHWKF) AND (text~'3D' OR text~'2D')" -Limit 5
        Show-Results $r
        Write-Host ""
    }

    Write-Host "=== All demos complete ===" -ForegroundColor Green
    Write-Host "Key rules:" -ForegroundColor Yellow
    Write-Host "  1. Always use [uri]::EscapeDataString() for CQL" -ForegroundColor Yellow
    Write-Host "  2. Single quotes must be encoded: ' -> %27" -ForegroundColor Yellow
    Write-Host "  3. Use Session Cookie for page content, Basic Auth for search" -ForegroundColor Yellow
    Write-Host "  4. Save as .ps1 file, never inline" -ForegroundColor Yellow

} catch {
    $err = $_.Exception.Message
    Write-Host "Error: $err" -ForegroundColor Red
    if ($_.Exception.Response) {
        $code = $_.Exception.Response.StatusCode.value__
        Write-Host "HTTP: $code" -ForegroundColor Red
        if ($code -eq 400) {
            Write-Host "400: Check CQL syntax, especially URL encoding of single quotes" -ForegroundColor Yellow
        }
    }
    exit 1
}
