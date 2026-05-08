<#
.SYNOPSIS
    Configure Confluence session environment variables.
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$CookieHeader,

    [string]$BaseUrl = $(if ($env:CONFLUENCE_BASE_URL) { $env:CONFLUENCE_BASE_URL } else { "http://dmtks.hisense.com" }),
    [string]$Username = $env:CONFLUENCE_USERNAME,
    [switch]$Persist
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($Username)) {
    throw "Missing username. Set CONFLUENCE_USERNAME or pass -Username."
}

$env:CONFLUENCE_BASE_URL = $BaseUrl.TrimEnd("/")
$env:CONFLUENCE_USERNAME = $Username
$env:CONFLUENCE_COOKIE = $CookieHeader

if ($Persist) {
    [Environment]::SetEnvironmentVariable("CONFLUENCE_BASE_URL", $env:CONFLUENCE_BASE_URL, "User")
    [Environment]::SetEnvironmentVariable("CONFLUENCE_USERNAME", $Username, "User")
    [Environment]::SetEnvironmentVariable("CONFLUENCE_COOKIE", $CookieHeader, "User")
    Write-Host "Confluence session saved to user environment variables."
} else {
    Write-Host "Confluence session set for the current PowerShell process."
    Write-Host "Dot-source this script when you need the variables in the caller process."
}
