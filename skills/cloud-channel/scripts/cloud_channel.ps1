param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$RemainingArgs
)

$ScriptPath = Join-Path $PSScriptRoot "cloud_channel.py"
python $ScriptPath @RemainingArgs
exit $LASTEXITCODE
