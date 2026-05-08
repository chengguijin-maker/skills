<#
.SYNOPSIS
    Configure Coremail session environment variables.
.DESCRIPTION
    Stores the current Coremail sid and Cookie header for coremail_query.ps1.
    Dot-source this script to set variables in the current PowerShell session:
    . .\set_coremail_session.ps1 -Sid "..." -CookieHeader "..."
.EXAMPLE
    . .\set_coremail_session.ps1 -Sid "current_sid" -CookieHeader "Coremail.sid=current_sid; Coremail=..."
.EXAMPLE
    .\set_coremail_session.ps1 -Sid "current_sid" -CookieHeader "..." -Persist
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$Sid,

    [Parameter(Mandatory = $true)]
    [string]$CookieHeader,

    [switch]$Persist
)

$ErrorActionPreference = "Stop"

if ($CookieHeader -notmatch [regex]::Escape($Sid)) {
    Write-Warning "Cookie header does not contain the sid. Coremail may return Cookie not matched."
}

$env:COREMAIL_SID = $Sid
$env:COREMAIL_COOKIE = $CookieHeader

if ($Persist) {
    [Environment]::SetEnvironmentVariable("COREMAIL_SID", $Sid, "User")
    [Environment]::SetEnvironmentVariable("COREMAIL_COOKIE", $CookieHeader, "User")
    Write-Host "Coremail session saved to user environment variables."
    Write-Host "Open a new terminal or set variables in the current process before use."
} else {
    Write-Host "Coremail session set for the current PowerShell process."
    Write-Host "If you did not dot-source this script, the variables are only available inside this script process."
}

