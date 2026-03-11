# Failure Signatures

Use this table to diagnose the common cross-shell failures quickly.

## `The token '&&' is not a valid statement separator`

Cause:
Windows PowerShell 5.1 is parsing the local command.

Fix:
- split the commands
- use `;` with `$LASTEXITCODE`
- or run under PowerShell 7 if the environment allows it

## `unexpected EOF while looking for matching '"'`

Cause:
PowerShell quoting and remote Bash quoting are fighting each other.

Fix:
- reduce the command to one quote layer
- switch the local wrapper to single quotes
- or stage the remote logic in a `.sh` file

## `syntax error near unexpected token 'do'` with a hidden character before `for`

Cause:
The remote shell received a BOM or other encoding artifact from a PowerShell text pipeline.

Fix:
- stop piping a here-string into `bash -s`
- normalize the script to UTF-8 without BOM
- copy the script with `scp` and execute it remotely

## `python: command not found`

Cause:
The Linux host only has `python3`.

Fix:
- use `python3`
- check `command -v python3` before assuming anything else

## Remote `$HOME`, `~`, or `$d` expanded wrong or did not expand

Cause:
Expansion happened on the wrong side, or PowerShell consumed the dollar sign before SSH sent it.

Fix:
- use a single-quoted PowerShell wrapper when the expansion should happen remotely
- if local interpolation is required, escape the remote dollar sign with a backtick

## The command works on Linux directly but fails from Windows PowerShell

Cause:
You are mixing local PowerShell semantics with remote POSIX semantics.

Fix:
- move local file inspection to PowerShell cmdlets
- keep Linux-only commands entirely inside the remote shell
- simplify the local command line until only one layer is doing parsing
