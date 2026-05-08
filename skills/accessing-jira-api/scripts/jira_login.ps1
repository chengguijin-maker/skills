<#
.SYNOPSIS
    Create or persist a JIRA Server session.
.DESCRIPTION
    Logs in through /rest/auth/1/session, exports JIRA_COOKIE for the current
    process, and can persist the cookie or a DPAPI encrypted credential.
#>

param(
    [string]$BaseUrl = $(if ($env:JIRA_BASE_URL) { $env:JIRA_BASE_URL } else { "http://tvjira.hisense.com" }),
    [string]$Username = $env:JIRA_USERNAME,
    [string]$PasswordPlainText = $env:JIRA_PASSWORD,
    [string]$CredentialPath = (Join-Path (Split-Path $PSScriptRoot -Parent) "jira_credential.xml"),
    [switch]$SaveCredential,
    [switch]$Persist,
    [switch]$RunMyself
)

$ErrorActionPreference = "Stop"
$BaseUrl = $BaseUrl.TrimEnd("/")

function Get-Password {
    if (-not [string]::IsNullOrWhiteSpace($PasswordPlainText)) {
        return ConvertTo-SecureString $PasswordPlainText -AsPlainText -Force
    }
    if (Test-Path -LiteralPath $CredentialPath) {
        $stored = Import-Clixml -LiteralPath $CredentialPath
        if ([string]::IsNullOrWhiteSpace($script:Username)) {
            $script:Username = $stored.UserName
        }
        return $stored.Password
    }
    if ([string]::IsNullOrWhiteSpace($script:Username)) {
        $script:Username = Read-Host "JIRA username"
    }
    return Read-Host "JIRA password for $Username" -AsSecureString
}

function ConvertTo-PlainText {
    param([securestring]$SecureString)
    $credential = New-Object System.Management.Automation.PSCredential("user", $SecureString)
    return $credential.GetNetworkCredential().Password
}

$securePassword = Get-Password

if ([string]::IsNullOrWhiteSpace($Username)) {
    throw "Missing username. Set JIRA_USERNAME, pass -Username, or run jira_login.ps1 -SaveCredential once."
}

if ($SaveCredential) {
    $credential = New-Object System.Management.Automation.PSCredential($Username, $securePassword)
    $credential | Export-Clixml -LiteralPath $CredentialPath
    Write-Host "JIRA credential saved with Windows DPAPI: $CredentialPath"
}

$plainPassword = ConvertTo-PlainText -SecureString $securePassword
$body = @{ username = $Username; password = $plainPassword } | ConvertTo-Json -Depth 4 -Compress
$login = Invoke-RestMethod -Uri "$BaseUrl/rest/auth/1/session" `
    -Method Post `
    -Body $body `
    -ContentType "application/json" `
    -SessionVariable jiraSession `
    -ErrorAction Stop

$baseUri = [uri]$BaseUrl
$cookies = $jiraSession.Cookies.GetCookies($baseUri)
$cookieHeader = (($cookies | ForEach-Object { "$($_.Name)=$($_.Value)" }) -join "; ")

if ([string]::IsNullOrWhiteSpace($cookieHeader)) {
    throw "JIRA login succeeded, but no cookie was returned."
}

$env:JIRA_BASE_URL = $BaseUrl
$env:JIRA_USERNAME = $Username
$env:JIRA_COOKIE = $cookieHeader

if ($Persist) {
    [Environment]::SetEnvironmentVariable("JIRA_BASE_URL", $BaseUrl, "User")
    [Environment]::SetEnvironmentVariable("JIRA_USERNAME", $Username, "User")
    [Environment]::SetEnvironmentVariable("JIRA_COOKIE", $cookieHeader, "User")
    Write-Host "JIRA session saved to user environment variables."
} else {
    Write-Host "JIRA session set for the current PowerShell process."
}

Write-Host "JIRA session name: $($login.session.name)"

if ($RunMyself) {
    & (Join-Path $PSScriptRoot "jira_query.ps1") -Action Myself -AuthMethod SessionCookie -CookieHeader $cookieHeader -BaseUrl $BaseUrl
}
