param(
    [Parameter(Mandatory = $true)]
    [string]$Target,

    [Parameter(Mandatory = $true)]
    [string]$LocalScriptPath,

    [string]$RemoteScriptPath,

    [string]$Shell = "bash",

    [switch]$KeepRemoteScript
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$resolvedLocalScript = Resolve-Path -LiteralPath $LocalScriptPath

if (-not $RemoteScriptPath) {
    $stamp = Get-Date -Format "yyyyMMddHHmmss"
    $RemoteScriptPath = "/tmp/codex-remote-$PID-$stamp.sh"
}

$tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("powershell-ssh-linux-ops-" + [System.Guid]::NewGuid().ToString("N"))
$normalizedScriptPath = Join-Path $tempDir "remote.sh"

New-Item -ItemType Directory -Path $tempDir | Out-Null

try {
    $content = [System.IO.File]::ReadAllText($resolvedLocalScript.Path)
    $normalized = $content.Replace("`r`n", "`n").Replace("`r", "`n")
    $encoding = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllText($normalizedScriptPath, $normalized, $encoding)

    & scp $normalizedScriptPath "${Target}:$RemoteScriptPath"
    if ($LASTEXITCODE -ne 0) {
        throw "scp failed with exit code $LASTEXITCODE"
    }

    & ssh $Target "$Shell '$RemoteScriptPath'"
    $remoteExitCode = $LASTEXITCODE

    if (-not $KeepRemoteScript) {
        & ssh $Target "rm -f '$RemoteScriptPath'"
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Failed to remove remote script: $RemoteScriptPath"
        }
    }

    if ($remoteExitCode -ne 0) {
        exit $remoteExitCode
    }
}
finally {
    if (Test-Path -LiteralPath $tempDir) {
        Remove-Item -LiteralPath $tempDir -Recurse -Force
    }
}
