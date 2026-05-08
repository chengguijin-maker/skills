<#
.SYNOPSIS
    JIRA JQL Search Techniques Demo
.DESCRIPTION
    Demonstrates all advanced JQL search techniques:
    - Operators: =, !=, ~, !~, >, <, >=, <=, IN, NOT IN, IS EMPTY, IS NOT EMPTY
    - Advanced: WAS, WAS IN, CHANGED, DURING
    - Functions: currentUser(), currentLogin(), lastLogin(), watchedIssues(), votedIssues(),
      componentsLeadByUser(), projectLead(), openSprints(), closedSprints(),
      startOfDay(), startOfWeek(), startOfMonth(), startOfYear(), now()
    - Relative dates: '-5d', '-2w', '-1m', '-1y'
    - Text search: wildcards (*), exact phrases ("phrase"), AND/OR, exclusion (-word)
    - Ordering: ORDER BY field1 DESC, field2 ASC
    - Pagination with startAt and maxResults
.NOTES
    Must be run as .ps1 file (not inline)
    Use new terminal each time (is_background=false)
.PARAMETER DemoIndex
    Run specific demo (1-12) or 0 for all demos
.EXAMPLE
    .\jira_search_demo.ps1
    .\jira_search_demo.ps1 -DemoIndex 5
#>

param(
    [ValidateSet("Basic", "Session")]
    [string]$AuthMethod = "Session",
    [int]$DemoIndex = 0
)

$ErrorActionPreference = "Stop"
$JIRA_URL = "http://tvjira.hisense.com"
$USERNAME = $env:JIRA_USERNAME
$PASSWORD = $env:JIRA_PASSWORD

function Get-PlainCredential {
    if ([string]::IsNullOrWhiteSpace($USERNAME)) {
        throw "Missing username. Set JIRA_USERNAME before running this demo."
    }
    if ([string]::IsNullOrWhiteSpace($PASSWORD)) {
        throw "Missing password. Set JIRA_PASSWORD before running this demo, or use jira_query.ps1 with a saved DPAPI credential."
    }
    return @{
        Username = $USERNAME
        Password = $PASSWORD
    }
}

function Get-BasicHeaders {
    $credential = Get-PlainCredential
    $pair = "$($credential.Username)`:$($credential.Password)"
    $bytes = [Text.Encoding]::ASCII.GetBytes($pair)
    $cred = [Convert]::ToBase64String($bytes)
    return @{ Authorization = "Basic $cred" }
}

function Get-Session {
    $credential = Get-PlainCredential
    $body = @{ username = $credential.Username; password = $credential.Password } | ConvertTo-Json
    $login = Invoke-RestMethod -Uri "$JIRA_URL/rest/auth/1/session" `
        -Method Post -Body $body -ContentType "application/json" `
        -SessionVariable jSession -ErrorAction Stop
    Write-Host "Login OK: $($login.session.name)" -ForegroundColor Green
    return $jSession
}

function Search-Jql {
    param([string]$Jql, [int]$MaxResults = 10)
    $jqlEnc = [uri]::EscapeDataString($Jql)
    $url = "$JIRA_URL/rest/api/2/search?jql=$jqlEnc&maxResults=$MaxResults&fields=*all"
    Write-Host "  JQL: $Jql" -ForegroundColor Yellow
    if ($AuthMethod -eq "Basic") {
        Invoke-RestMethod -Uri $url -Headers (Get-BasicHeaders) -ErrorAction Stop
    } else {
        Invoke-RestMethod -Uri $url -WebSession (Get-Session) -ErrorAction Stop
    }
}

function Show-Results {
    param($Result)
    Write-Host "  Results: $($Result.total)" -ForegroundColor Green
    foreach ($i in $Result.issues) {
        $key = $i.key
        $summary = $i.fields.summary
        $status = $i.fields.status.name
        $assignee = if ($i.fields.assignee) { $i.fields.assignee.displayName } else { "Unassigned" }
        $priority = $i.fields.priority.name
        Write-Host "  [$key] $summary ($status, $priority, $assignee)"
    }
}

try {
    Write-Host "=== JIRA JQL Search Techniques Demo ===" -ForegroundColor Cyan
    Write-Host ""

    # Demo 1: Basic = AND
    if ($DemoIndex -in 0,1) {
        Write-Host "Demo 1: Basic project and status filter" -ForegroundColor Magenta
        Write-Host "Pattern: project = KEY AND status = Value" -ForegroundColor DarkGray
        $r = Search-Jql -Jql "project = MT9655 AND status = Open" -MaxResults 5
        Show-Results $r
        Write-Host ""
    }

    # Demo 2: Text fuzzy search ~ !~
    if ($DemoIndex -in 0,2) {
        Write-Host "Demo 2: Text fuzzy search with ~ and !~" -ForegroundColor Magenta
        Write-Host "Pattern: field ~ 'keyword', field !~ 'exclude'" -ForegroundColor DarkGray
        Write-Host "  Searches: summary, description, environment, comments" -ForegroundColor DarkGray
        $r = Search-Jql -Jql "project = MT9655 AND summary ~ '3D'" -MaxResults 5
        Show-Results $r
        Write-Host "  Exclusion: summary !~ 'test'" -ForegroundColor DarkGray
        $r2 = Search-Jql -Jql "project = MT9655 AND summary ~ 'bug' AND summary !~ 'test'" -MaxResults 5
        Show-Results $r2
        Write-Host ""
    }

    # Demo 3: Relative dates
    if ($DemoIndex -in 0,3) {
        Write-Host "Demo 3: Relative dates with > < and functions" -ForegroundColor Magenta
        Write-Host "Pattern: created > '-7d', updated < '-2w'" -ForegroundColor DarkGray
        $r = Search-Jql -Jql "project = MT9655 AND created > '-7d' ORDER BY created DESC" -MaxResults 5
        Show-Results $r
        Write-Host ""
        Write-Host "  Relative date formats: '-5d' '-2w' '-1m' '-1y'" -ForegroundColor DarkGray
        Write-Host "  Functions: startOfDay(), startOfWeek(), startOfMonth(), startOfYear()" -ForegroundColor DarkGray
        Write-Host "  Session: currentLogin(), lastLogin()" -ForegroundColor DarkGray
        Write-Host ""
    }

    # Demo 4: IN NOT IN IS EMPTY IS NOT EMPTY
    if ($DemoIndex -in 0,4) {
        Write-Host "Demo 4: Multi-value and null checks" -ForegroundColor Magenta
        Write-Host "Pattern: status IN (Open, 'In Progress'), assignee IS EMPTY" -ForegroundColor DarkGray
        $r = Search-Jql -Jql "project = MT9655 AND status IN (Open, 'In Progress', Reopened)" -MaxResults 5
        Show-Results $r
        Write-Host "  Unassigned: assignee IS EMPTY AND resolution IS EMPTY" -ForegroundColor DarkGray
        $r2 = Search-Jql -Jql "project = MT9655 AND assignee IS EMPTY AND resolution IS EMPTY" -MaxResults 5
        Show-Results $r2
        Write-Host ""
    }

    # Demo 5: History operators WAS CHANGED DURING
    if ($DemoIndex -in 0,5) {
        Write-Host "Demo 5: History status change operators" -ForegroundColor Magenta
        Write-Host "NOTE: JIRA Server v7.6.1 support for WAS/CHANGED may vary" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "  status WAS 'In Progress' - Ever had this status" -ForegroundColor Gray
        Write-Host "  status CHANGED FROM 'Open' TO 'Resolved'" -ForegroundColor Gray
        Write-Host "  status CHANGED DURING ('2026-01-01', '2026-06-01')" -ForegroundColor Gray
        Write-Host "  assignee CHANGED - Reassigned" -ForegroundColor Gray
        Write-Host "  priority CHANGED FROM 'Minor' TO 'Major'" -ForegroundColor Gray
        Write-Host ""
    }

    # Demo 6: currentUser()
    if ($DemoIndex -in 0,6) {
        Write-Host "Demo 6: Current user queries" -ForegroundColor Magenta
        Write-Host "Pattern: assignee = currentUser(), reporter = currentUser()" -ForegroundColor DarkGray
        $r = Search-Jql -Jql "project = MT9655 AND reporter = currentUser() ORDER BY created DESC" -MaxResults 5
        Show-Results $r
        Write-Host "  My unresolved: assignee = currentUser() AND resolution IS EMPTY" -ForegroundColor DarkGray
        $r2 = Search-Jql -Jql "project = MT9655 AND assignee = currentUser() AND resolution IS EMPTY" -MaxResults 5
        Show-Results $r2
        Write-Host "  Watched: issueKey IN watchedIssues()" -ForegroundColor DarkGray
        $r3 = Search-Jql -Jql "project = MT9655 AND issueKey IN watchedIssues() AND resolution IS EMPTY" -MaxResults 5
        Show-Results $r3
        Write-Host ""
    }

    # Demo 7: componentsLeadByUser, projectLead
    if ($DemoIndex -in 0,7) {
        Write-Host "Demo 7: Project management functions" -ForegroundColor Magenta
        Write-Host "  My components: component IN componentsLeadByUser()" -ForegroundColor DarkGray
        $r = Search-Jql -Jql "project = MT9655 AND component IN componentsLeadByUser() AND resolution IS EMPTY" -MaxResults 5
        Show-Results $r
        Write-Host "  My projects: project = projectLead()" -ForegroundColor DarkGray
        $r2 = Search-Jql -Jql "project = projectLead() AND resolution IS EMPTY" -MaxResults 5
        Show-Results $r2
        Write-Host ""
    }

    # Demo 8: Sprint functions
    if ($DemoIndex -in 0,8) {
        Write-Host "Demo 8: Sprint functions" -ForegroundColor Magenta
        Write-Host "  Open sprint: sprint IN openSprints()" -ForegroundColor DarkGray
        $r = Search-Jql -Jql "project = MT9655 AND sprint IN openSprints() AND assignee = currentUser()" -MaxResults 5
        Show-Results $r
        Write-Host "  Closed sprint: sprint IN closedSprints()" -ForegroundColor DarkGray
        $r2 = Search-Jql -Jql "project = MT9655 AND sprint IN closedSprints() AND resolution IS EMPTY" -MaxResults 5
        Show-Results $r2
        Write-Host ""
    }

    # Demo 9: Advanced text search
    if ($DemoIndex -in 0,9) {
        Write-Host "Demo 9: Advanced text search syntax" -ForegroundColor Magenta
        Write-Host "  Wildcard: summary ~ '3D*' (starts with 3D)" -ForegroundColor DarkGray
        $r = Search-Jql -Jql "project = MT9655 AND summary ~ '3D*'" -MaxResults 5
        Show-Results $r
        Write-Host "  text ~ 'keyword' (searches summary+description+comments)" -ForegroundColor DarkGray
        $r2 = Search-Jql -Jql "project = MT9655 AND text ~ 'bug'" -MaxResults 5
        Show-Results $r2
        Write-Host "  Exact phrase: summary ~ '\"exact phrase\"'" -ForegroundColor DarkGray
        Write-Host ""
    }

    # Demo 10: Ordering and pagination
    if ($DemoIndex -in 0,10) {
        Write-Host "Demo 10: Multi-field ordering and pagination" -ForegroundColor Magenta
        Write-Host "  ORDER BY priority DESC, created ASC" -ForegroundColor DarkGray
        $r = Search-Jql -Jql "project = MT9655 AND status NOT IN (Closed, Resolved) ORDER BY priority DESC, created ASC" -MaxResults 5
        Show-Results $r
        Write-Host ""
        Write-Host "  Pagination code pattern:" -ForegroundColor DarkGray
        Write-Host '    $all = @(); $startAt = 0; $max = 100' -ForegroundColor DarkGray
        Write-Host '    do { $r = Invoke-RestMethod -Uri "...&startAt=$startAt&maxResults=$max"; $all += $r.issues; $startAt += $max } while ($startAt -lt $r.total)' -ForegroundColor DarkGray
        Write-Host ""
    }

    # Demo 11: 2D-to-3D project实战
    if ($DemoIndex -in 0,11) {
        Write-Host "Demo 11: 2D-to-3D project实战 queries" -ForegroundColor Magenta
        Write-Host "  All 3D-related unresolved:" -ForegroundColor DarkGray
        $r = Search-Jql -Jql "project = MT9655 AND (summary ~ '3D' OR summary ~ '2D' OR description ~ '3D') AND status NOT IN (Closed, Resolved) ORDER BY priority DESC" -MaxResults 5
        Show-Results $r
        Write-Host "  By version: affectedVersion = 'Q0430' AND issuetype = Bug AND summary ~ '3D'" -ForegroundColor DarkGray
        $r2 = Search-Jql -Jql "project = MT9655 AND affectedVersion = 'Q0430' AND issuetype = Bug AND summary ~ '3D'" -MaxResults 5
        Show-Results $r2
        Write-Host "  Recent 3D issues: updated > '-1m' AND (summary ~ '3D' OR component = '2D转3D')" -ForegroundColor DarkGray
        $r3 = Search-Jql -Jql "project = MT9655 AND updated > '-1m' AND (summary ~ '3D' OR component = '2D转3D') ORDER BY updated DESC" -MaxResults 5
        Show-Results $r3
        Write-Host ""
    }

    # Demo 12: Votes, watchers, attachments, duedate
    if ($DemoIndex -in 0,12) {
        Write-Host "Demo 12: Other useful queries" -ForegroundColor Magenta
        Write-Host "  Popular: votes > 2" -ForegroundColor DarkGray
        $r = Search-Jql -Jql "project = MT9655 AND votes > 2 ORDER BY votes DESC" -MaxResults 5
        Show-Results $r
        Write-Host "  With attachments: attachments IS NOT EMPTY" -ForegroundColor DarkGray
        $r2 = Search-Jql -Jql "project = MT9655 AND attachments IS NOT EMPTY ORDER BY updated DESC" -MaxResults 5
        Show-Results $r2
        Write-Host "  Overdue: duedate < now() AND resolution IS EMPTY" -ForegroundColor DarkGray
        $r3 = Search-Jql -Jql "project = MT9655 AND duedate < now() AND resolution IS EMPTY ORDER BY duedate ASC" -MaxResults 5
        Show-Results $r3
        Write-Host ""
    }

    Write-Host "=== All demos complete ===" -ForegroundColor Green
    Write-Host "Key functions:" -ForegroundColor Cyan
    Write-Host "  currentUser() currentLogin() lastLogin() watchedIssues() votedIssues()" -ForegroundColor Cyan
    Write-Host "  componentsLeadByUser() projectLead() openSprints() closedSprints()" -ForegroundColor Cyan
    Write-Host "  startOfDay() startOfWeek() startOfMonth() startOfYear()" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Rules:" -ForegroundColor Yellow
    Write-Host "  1. Always use [uri]::EscapeDataString() for JQL" -ForegroundColor Yellow
    Write-Host "  2. Save as .ps1 file, never inline" -ForegroundColor Yellow
    Write-Host "  3. New terminal per execution (is_background=false)" -ForegroundColor Yellow

} catch {
    $err = $_.Exception.Message
    Write-Host "Error: $err" -ForegroundColor Red
    if ($_.Exception.Response) {
        $code = $_.Exception.Response.StatusCode.value__
        Write-Host "HTTP: $code" -ForegroundColor Red
    }
    exit 1
}
