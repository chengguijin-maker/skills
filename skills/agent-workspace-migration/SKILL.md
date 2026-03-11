---
name: agent-workspace-migration
description: Use when migrating a Claude, Codex, Gemini, or similar agent workspace from one Linux server to another. Covers source and target host inventory, target user bootstrap, SSH key login, passwordless sudo, nvm with Node LTS plus pnpm, standard `gh` setup, GitHub-backed skill installation, selective shell config sync, MCP and agent dotdir migration, filtered project transfer, and final verification.
---

# Agent Workspace Migration

## Overview

Standardize migration of a user-scoped agent environment between Linux servers. Keep the private GitHub skills repository as the source of truth for reusable skills, recreate runtimes deliberately, copy only the state that should survive, and patch host-specific paths after restore.

Read these references before touching the target host:

- `references/sync-scope.md` for what to sync directly, merge selectively, patch after restore, or exclude.
- `references/migration-checklist.md` for concrete commands and verification.

## Workflow

1. Inventory both hosts first.
   - Record OS, hostname, disk layout, free space, login path, and whether the source can reach the target directly.
   - Measure the source footprint for agent homes such as `~/.codex`, `~/.claude`, `~/.gemini`, `~/.copilot`, `~/.lingma`, and project trees such as `~/open`.
   - Inspect shell files such as `~/.bashrc`, `~/.profile`, and `~/.bash_aliases`.
   - Enumerate installed skills and key runtimes such as `node`, `pnpm`, `gh`, `codex`, `claude`, and MCP helper binaries if present.
   - Classify each path with `references/sync-scope.md` before copying anything.

2. Bootstrap the target user and access path.
   - Start from an admin-capable account if the target user does not exist yet.
   - Create the target user with a real home directory and shell.
   - Install the operator's SSH public key into `~/.ssh/authorized_keys`.
   - Verify key login works before changing anything else.
   - Prefer `NOPASSWD sudo` when the stated goal is passwordless admin access.

3. Recreate the base runtime deliberately.
   - Default to `nvm` plus current Node LTS unless the user explicitly asks for latest.
   - Install `pnpm` under the `nvm` managed Node, not under the system Node.
   - Install agent CLIs with `pnpm add -g ...`, not `npm -g`.
   - If the user requests `npm` to map to `pnpm`, implement it as an interactive shell alias and call out that scripts and CI should still invoke `pnpm` directly.
   - Install `gh` through the OS package manager when practical, or place the official binary in a standard user bin directory already on PATH such as `~/.local/bin`.
   - Sync only the intended shell customizations such as PATH, `nvm`, `pnpm`, tmux aliases, and helper functions. Remove proxy settings on hosts that should not use a proxy.
   - Keep large installs and project data under `/home/<user>` when root space is tight.

4. Restore the skills operating model from GitHub.
   - Do not introduce ad hoc sync scripts when the repository is the intended source of truth.
   - Configure private repository access with `gh` auth or a deploy key.
   - Install `skills-manager` first, then use it to install or sync managed skills into `~/.codex/skills` and `~/.claude/skills`.
   - Treat first-party skills and mirrored third-party skills as repository content, not one-off local copies.

5. Sync agent state and MCP dependencies with patch rules.
   - Copy the agent directories and companion assets defined in `references/sync-scope.md`.
   - Preserve useful state such as configs, prompts, plugins, HUD assets, MCP definitions, and trusted project lists.
   - Skip caches, logs, build output, proxy-specific config, and copied package-manager state unless the user explicitly asks for them.
   - Patch restored files for the new username, home path, hostname, Node version, and executable locations before first run.
   - Verify every configured MCP command resolves on the target host.

6. Copy projects with filtered archives and verification.
   - For large trees such as `~/open`, build a filtered archive that excludes transient build and cache directories instead of mutating the source tree.
   - Prefer high-compression archives plus `sha256sum` verification when bandwidth is the bottleneck.
   - If the source changed after the archive was created, follow with a source-only delta sync before handoff.
   - Fix ownership after transfer.

7. Verify the target before declaring success.
   - Confirm `ssh <target>` works with keys.
   - Confirm `sudo -n` works if passwordless sudo was requested.
   - Confirm `node`, `pnpm`, `gh`, requested agent CLIs, and any shell aliases resolve to the intended versions.
   - Confirm managed skills are installed in both Claude and Codex targets and can sync from GitHub.
   - Confirm MCP servers resolve their configured commands.
   - Compare directory sizes or sample contents for migrated trees like `~/open`.

## Guardrails

- Use exact hostnames, ports, usernames, and dates when the user has corrected earlier assumptions.
- Do not assume the source host can open connections to the target host.
- Do not sync proxy settings onto hosts that should not use a proxy.
- Do not leave secrets in shell history, repository files, or copied dotfiles unless the migration explicitly requires that behavior.
- Do not store secrets in the skills repository. Copy auth state only when the migration explicitly requires it and the transport is trusted.
- Do not depend on shell aliases for automation; aliases are for interactive sessions only.
- When disk is split between `/` and `/home`, keep migrated agent state and projects under `/home/<user>`.

## Deliverables

Finish with evidence, not guesses:

- the target login method
- the target user and sudo state
- the installed Node LTS, `pnpm`, `gh`, and requested agent CLI versions
- the skills source-of-truth path and installed skill set
- the synced shell files, agent directories, MCP assets, and project trees
- the patched host-specific paths and any intentionally excluded items
