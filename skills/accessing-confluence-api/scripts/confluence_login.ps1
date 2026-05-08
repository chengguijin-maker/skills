<#
.SYNOPSIS
    Create or persist a Confluence Server session.
.DESCRIPTION
    Logs in through /login.action, exports CONFLUENCE_COOKIE for the current
    process, and can persist the cookie or a DPAPI encrypted credential.
#>

param(
    [string]$BaseUrl = $(if ($env:CONFLUENCE_BASE_URL) { $env:CONFLUENCE_BASE_URL } else { "http://dmtks.hisense.com" }),
    [string]$Username = $env:CONFLUENCE_USERNAME,
    [string]$PasswordPlainText = $env:CONFLUENCE_PASSWORD,
    [string]$CredentialPath = (Join-Path (Split-Path $PSScriptRoot -Parent) "confluence_credential.xml"),
    [switch]$SaveCredential,
    [switch]$Persist,
    [switch]$RunSearch
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
        $script:Username = Read-Host "Confluence username"
    }
    return Read-Host "Confluence password for $Username" -AsSecureString
}

function ConvertTo-PlainText {
    param([securestring]$SecureString)
    $credential = New-Object System.Management.Automation.PSCredential("user", $SecureString)
    return $credential.GetNetworkCredential().Password
}

$securePassword = Get-Password

if ([string]::IsNullOrWhiteSpace($Username)) {
    throw "Missing username. Set CONFLUENCE_USERNAME, pass -Username, or run confluence_login.ps1 -SaveCredential once."
}

if ($SaveCredential) {
    $credential = New-Object System.Management.Automation.PSCredential($Username, $securePassword)
    $credential | Export-Clixml -LiteralPath $CredentialPath
    Write-Host "Confluence credential saved with Windows DPAPI: $CredentialPath"
}

$plainPassword = ConvertTo-PlainText -SecureString $securePassword
Invoke-WebRequest -Uri "$BaseUrl/login.action" `
    -Method Post `
    -Body @{ os_username = $Username; os_password = $plainPassword; os_cookie = "true" } `
    -SessionVariable confluenceSession `
    -MaximumRedirection 5 `
    -ErrorAction Stop | Out-Null

$baseUri = [uri]$BaseUrl
$cookies = $confluenceSession.Cookies.GetCookies($baseUri)
$cookieHeader = (($cookies | ForEach-Object { "$($_.Name)=$($_.Value)" }) -join "; ")

if ([string]::IsNullOrWhiteSpace($cookieHeader)) {
    throw "Confluence login succeeded, but no cookie was returned."
}

$env:CONFLUENCE_BASE_URL = $BaseUrl
$env:CONFLUENCE_USERNAME = $Username
$env:CONFLUENCE_COOKIE = $cookieHeader

if ($Persist) {
    [Environment]::SetEnvironmentVariable("CONFLUENCE_BASE_URL", $BaseUrl, "User")
    [Environment]::SetEnvironmentVariable("CONFLUENCE_USERNAME", $Username, "User")
    [Environment]::SetEnvironmentVariable("CONFLUENCE_COOKIE", $cookieHeader, "User")
    Write-Host "Confluence session saved to user environment variables."
} else {
    Write-Host "Confluence session set for the current PowerShell process."
}

if ($RunSearch) {
    & (Join-Path $PSScriptRoot "confluence_query.ps1") -Action Search -AuthMethod SessionCookie -CookieHeader $cookieHeader -BaseUrl $BaseUrl -Limit 5
}
