# Sync Scope

Classify every path before copying it. The migration should preserve useful agent behavior without hauling across stale machine state.

## Sync Directly

- Large project trees such as `~/open`, but only through filtered archives that exclude transient build output and caches.
- Stable agent assets such as `~/.claude/plugins`, `~/.claude/hud`, user-authored prompts, slash commands, and other reusable local extensions.
- Agent homes such as `~/.gemini`, `~/.copilot`, and `~/.lingma` when they primarily hold user settings, trusted project lists, or reusable state.
- User-scoped helper binaries and wrappers that agents or MCP servers actually call, usually under `~/.local/bin` or the `PNPM_HOME` global bin directory.

## Sync Selectively

- `~/.codex`: keep `config.toml`, prompts, trusted project state, MCP definitions, and user-authored helpers. Skip caches, logs, temp data, and bulky history unless the user explicitly wants a full carryover.
- `~/.claude`: keep `settings.json`, skills, plugins, HUD assets, and stable configuration. Skip caches, logs, crash dumps, temp downloads, and bulky history unless requested.
- Shell files such as `~/.bashrc`, `~/.profile`, `~/.bash_aliases`, `~/.bash_profile`, `~/.zshrc`, `~/.gitconfig`, and `~/.tmux.conf`: merge only the intentional user customizations such as PATH, `nvm`, `pnpm`, aliases, tmux helpers, editor settings, and Git identity.
- Project-local MCP config such as `.mcp.json` or repo-scoped wrapper scripts: copy only for projects that are also being migrated.
- Auth or session files such as `.env`, tokens, or login caches: copy only when the user wants a seamless carryover. Never commit them to the skills repository.

## Patch After Sync

- Absolute home paths such as `/home/<old-user>` inside configs, scripts, or MCP commands.
- Node-version-specific executable paths under `~/.nvm/versions/node/.../bin/...`.
- Hostnames, IPs, ports, mount points, browser profile paths, and any server-local socket paths.
- `gh` or helper-binary paths if the install method changed between hosts.
- Trusted project paths when repository locations moved on the target host.

## Never Sync Blindly

- Proxy settings such as `HTTP_PROXY`, `HTTPS_PROXY`, `ALL_PROXY`, `NO_PROXY`, lowercase variants, and tool-specific proxy stanzas when the target host should run without a proxy.
- Caches, logs, compiled output, and generated dependency trees such as `node_modules`, `.venv`, `dist`, `build`, `.next`, `.cache`, `coverage`, `__pycache__`, `.pytest_cache`, `.mypy_cache`, and browser caches.
- SSH host keys, machine SSH private keys, and system service credentials unless the user explicitly approves the transfer.
- System package-manager state, binaries under `/usr` or `/opt`, and other host-specific OS files that should be recreated rather than copied.

## `gh` Placement

- Prefer the OS package manager when the target host supports it cleanly.
- For user-scoped installs, use a standard bin directory on PATH such as `~/.local/bin`, not an ad hoc tool-specific location.
- Ensure the chosen bin directory is exported in both login and interactive shells so agent child processes and MCP servers can resolve `gh`.
