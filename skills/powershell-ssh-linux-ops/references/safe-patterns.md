# Safe Patterns

Use these patterns when Windows PowerShell is the controller and Linux is the execution target.

## 1. Pick The Simplest Boundary

- Trivial remote check: use one `ssh` one-liner.
- Repeated independent checks: use several small `ssh` calls instead of one nested remote loop.
- Multi-line Bash or quote-heavy logic: stage a `.sh` file and run `scripts/invoke_remote_bash.ps1`.

If a command needs more than one quoting layer, stop and change the shape instead of adding more escapes.

## 2. Quote For The Right Shell

- Default to single-quoted PowerShell strings around the remote command so PowerShell does not expand remote `$HOME`, `$d`, or globs.
- Use a double-quoted PowerShell string only when the Windows side must inject a local value.
- If a double-quoted PowerShell string must preserve a remote Bash variable, escape the dollar sign with a backtick.

Example:

```powershell
$user = 'jinchenggui'
ssh 630 "test -d /home/$user/.codex && echo OK"
ssh 630 "for d in /tmp; do echo `$d; done"
```

If the command starts looking like quote soup, move it into a shell script.

## 3. Respect PowerShell Version Differences

- Windows PowerShell 5.1 does not support `&&` and `||` as statement separators.
- Prefer separate commands when possible.
- If you must chain locally in PowerShell 5.1, use `;` plus explicit exit checks.

Example:

```powershell
git -C 'C:\Users\jinchenggui\skills' add .
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
git -C 'C:\Users\jinchenggui\skills' status --short
```

## 4. Avoid PowerShell Text Pipelines For Remote Bash

Do not pipe a PowerShell here-string or string variable directly into `ssh host 'bash -s'` on Windows PowerShell unless you have verified the encoding. Hidden BOM or UTF-16 bytes can reach Bash and break the first token.

Prefer one of these:

- `ssh <host> 'simple one-liner'`
- `scp local.sh <host>:/tmp/run.sh` then `ssh <host> 'bash /tmp/run.sh'`
- `scripts/invoke_remote_bash.ps1`

## 5. Keep Local And Remote Tools Separate

- Use PowerShell cmdlets locally: `Get-Content`, `Select-String`, `Test-Path`, `Resolve-Path`.
- Use POSIX tools remotely: `grep`, `find`, `sed`, `bash`, `python3`.
- Do not assume `grep`, `sed`, or `find` will behave the same way on Windows as on Linux.

## 6. Prefer Explicit Remote Runtimes

- Use `python3`, not `python`, unless the host confirms `python` exists.
- Use `bash`, not `/bin/sh`, when the script depends on Bash syntax.
- Use explicit remote paths for host-specific binaries when they are not guaranteed on PATH.

## 7. Use A Staged Script For Real Remote Logic

Use `scripts/invoke_remote_bash.ps1` when the remote work has any of these:

- loops
- conditionals
- multiple commands that must share variables
- heredocs
- both local Windows interpolation and remote Bash variables

Example:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\invoke_remote_bash.ps1 `
  -Target 630 `
  -LocalScriptPath .\remote-checks.sh
```
