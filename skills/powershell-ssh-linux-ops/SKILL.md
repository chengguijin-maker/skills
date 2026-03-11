---
name: powershell-ssh-linux-ops
description: Use when Windows PowerShell is driving SSH, SCP, rsync, Git, or agent operations against Linux hosts. Covers PowerShell 5 versus 7 command chaining, local versus remote quoting, escaping remote `$` variables, avoiding BOM or UTF-16 stdin corruption, choosing `python3` explicitly, staging complex remote Bash safely, and debugging failures such as `unexpected EOF`, hidden BOM characters, or missing-command errors.
---

# PowerShell SSH Linux Ops

## Overview

Operate Linux hosts from Windows PowerShell without getting trapped by local interpolation, native-command encoding, or remote shell quoting. Default to small remote one-liners for trivial checks and switch early to staged shell scripts for anything with loops, nested quotes, or both PowerShell and Bash variables.

## Workflow

1. Pick the execution shape before writing the command.
   - Use one remote one-liner for trivial checks such as file existence, versions, or a single grep.
   - Use several small remote calls instead of one dense loop when collecting multiple facts.
   - Use `scripts/invoke_remote_bash.ps1` for multi-line Bash, loops, conditionals, heredocs, or commands that need both local PowerShell interpolation and remote Bash expansion.

2. Control where expansion happens.
   - Let PowerShell expand only values that must come from Windows.
   - Let the remote shell expand `~`, `$HOME`, `$d`, globs, and command substitutions.
   - If a double-quoted PowerShell string must contain a remote Bash variable, escape it as `` `$var ``.

3. Keep local PowerShell rules explicit.
   - Treat Windows PowerShell 5.1 and PowerShell 7 as different shells until proven otherwise.
   - Do not use `&&` in Windows PowerShell 5.1. Split commands or check `$LASTEXITCODE` explicitly.
   - Prefer PowerShell cmdlets locally and POSIX tools remotely.
   - Quote Windows paths fully.

4. Keep remote Linux assumptions explicit.
   - Prefer `python3` over `python` unless the host proves otherwise.
   - Prefer `bash` for scripts that use arrays, `[[ ... ]]`, brace expansion, or stricter error handling.
   - Keep remote commands ASCII unless non-ASCII is required.

5. Debug by failure signature.
   - Read `references/failure-signatures.md` when the failure looks like quoting, encoding, or expansion corruption.
   - Read `references/safe-patterns.md` when deciding between one-liners, repeated checks, and staged scripts.

## Safe Defaults

- Prefer one responsibility per `ssh` command.
- Prefer remote script staging over piping a PowerShell here-string into `bash -s`.
- Prefer `scp` plus remote execution over deeply nested quoting.
- Prefer explicit `python3`, `bash`, and quoted remote paths.
- Prefer separate controller-side calls over clever remote loops when reliability matters more than terseness.

## Resources

- `references/safe-patterns.md` for execution patterns and quoting rules.
- `references/failure-signatures.md` for symptom-to-fix troubleshooting.
- `scripts/invoke_remote_bash.ps1` to normalize a local `.sh` file to UTF-8 without BOM plus LF line endings, copy it with `scp`, execute it with `ssh`, and clean up.
