<#
.SYNOPSIS
    Configure JIRA session environment variables.
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$CookieHeader,

    [string]$BaseUrl = $(if ($env:JIRA_BASE_URL) { $env:JIRA_BASE_URL } else { "http://tvjira.hisense.com" }),
    [string]$Username = $env:JIRA_USERNAME,
    [switch]$Persist
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($Username)) {
    throw "Missing username. Set JIRA_USERNAME or pass -Username."
}

$env:JIRA_BASE_URL = $BaseUrl.TrimEnd("/")
$env:JIRA_USERNAME = $Username
$env:JIRA_COOKIE = $CookieHeader

if ($Persist) {
    [Environment]::SetEnvironmentVariable("JIRA_BASE_URL", $env:JIRA_BASE_URL, "User")
    [Environment]::SetEnvironmentVariable("JIRA_USERNAME", $Username, "User")
    [Environment]::SetEnvironmentVariable("JIRA_COOKIE", $CookieHeader, "User")
    Write-Host "JIRA session saved to user environment variables."
} else {
    Write-Host "JIRA session set for the current PowerShell process."
    Write-Host "Dot-source this script when you need the variables in the caller process."
}
