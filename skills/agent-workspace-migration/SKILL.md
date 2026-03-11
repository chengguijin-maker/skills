---
name: agent-workspace-migration
description: Use when migrating a Claude, Codex, or similar agent workspace from one Linux server to another. Covers source and target host inventory, target user bootstrap, SSH key login, passwordless sudo, nvm with Node LTS and pnpm setup, GitHub-backed skill installation, copying working directories such as `open/`, and final verification.
---

# Agent Workspace Migration

## Overview

Standardize migration of a user-scoped agent environment between servers. Keep the private GitHub skills repository as the source of truth, move large working data under `/home/<user>`, and verify access, tooling, skills, and copied projects before closing the task.

Read `references/migration-checklist.md` before touching the target host. Use it as the command checklist and evidence log.

## Workflow

1. Inventory both hosts first.
   - Record OS, hostname, disk layout, free space, login path, and whether the source can reach the target directly.
   - Measure the source footprint for `~/.codex`, `~/.claude`, `~/open`, and other large user-level tool directories.
   - Enumerate installed skills and key runtimes such as `node`, `npm`, `pnpm`, `gh`, `codex`, and `claude` if present.

2. Bootstrap the target user and access path.
   - Start from an admin-capable account if the target user does not exist yet.
   - Create the target user with a real home directory and shell.
   - Install the operator's SSH public key into `~/.ssh/authorized_keys`.
   - Verify key login works before changing anything else.
   - Prefer `NOPASSWD sudo` when the stated goal is passwordless admin access.

3. Recreate the base runtime deliberately.
   - Default to `nvm` plus current Node LTS unless the user explicitly asks for latest.
   - Install `pnpm` under the `nvm` managed Node, not under the system Node.
   - If the user requests `npm` to map to `pnpm`, implement it as an interactive shell alias and call out that scripts and CI should still invoke `pnpm` directly.
   - Keep large installs and project data under `/home/<user>` when root space is tight.

4. Restore the skills operating model from GitHub.
   - Do not introduce ad hoc sync scripts when the repository is the intended source of truth.
   - Configure private repository access with `gh` auth or a deploy key.
   - Install `skills-manager` first, then use it to install or sync managed skills into `~/.codex/skills` and `~/.claude/skills`.
   - Treat first-party skills and mirrored third-party skills as repository content, not one-off local copies.

5. Copy user data and projects with an ownership plan.
   - Prefer `rsync` or streamed `tar` transfers.
   - If source-to-target connectivity is blocked, relay through the local machine instead of making risky temporary changes on either server.
   - Copy large project trees such as `~/open` into the target user's home.
   - Copy only the agent state that is actually needed from `~/.codex` and `~/.claude`; avoid dragging transient caches unless they matter.
   - Fix ownership after transfer.

6. Verify the target before declaring success.
   - Confirm `ssh <target>` works with keys.
   - Confirm `sudo -n` works if passwordless sudo was requested.
   - Confirm `node`, `pnpm`, and any shell aliases resolve to the intended versions.
   - Confirm skills are installed in both Claude and Codex targets and can sync from GitHub.
   - Compare directory sizes or sample contents for migrated trees like `~/open`.

## Guardrails

- Use exact hostnames, ports, usernames, and dates when the user has corrected earlier assumptions.
- Do not assume the source host can open connections to the target host.
- Do not leave secrets in shell history, repository files, or copied dotfiles unless the user explicitly wants that behavior.
- Do not depend on shell aliases for automation; aliases are for interactive sessions only.
- When disk is split between `/` and `/home`, keep migrated agent state and projects under `/home/<user>`.

## Deliverables

Finish with evidence, not guesses:

- the target login method
- the target user and sudo state
- the installed Node LTS and `pnpm` versions
- the skills source-of-truth path and installed skill set
- the copied directories and any intentionally skipped data
