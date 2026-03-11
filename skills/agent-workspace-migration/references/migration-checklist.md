# Migration Checklist

Use this checklist to migrate a Claude, Codex, Gemini, or similar agent workspace from one Linux host to another. Pair it with `sync-scope.md` before copying anything.

## 1. Inventory The Source Host

Record the current state before copying anything:

```bash
ssh <source> 'hostnamectl | sed -n "1,12p"; id; df -h / /home'
ssh <source> 'for d in ~/.codex ~/.claude ~/.gemini ~/.copilot ~/.lingma ~/.nvm ~/.local/bin ~/open; do [ -e "$d" ] && du -sh "$d"; done'
ssh <source> 'find ~/.codex/skills ~/.claude/skills -maxdepth 2 -name SKILL.md 2>/dev/null | sort'
ssh <source> 'command -v node; node -v 2>/dev/null; command -v pnpm; pnpm -v 2>/dev/null; command -v gh; gh --version 2>/dev/null | head -n 1; command -v codex; codex --version 2>/dev/null; command -v claude; claude --version 2>/dev/null'
ssh <source> 'for f in ~/.bashrc ~/.profile ~/.bash_aliases ~/.bash_profile ~/.gitconfig ~/.tmux.conf; do [ -f "$f" ] && printf "\n### %s\n" "$f" && grep -nE "proxy|nvm|pnpm|PATH|alias npm|tmux|gh|codex|claude|gemini" "$f" || true; done'
ssh <source> 'for f in ~/.codex/config.toml ~/.claude/settings.json; do [ -f "$f" ] && printf "\n### %s\n" "$f" && grep -nE "mcp|chrome-devtools|hud|plugin|trusted|command" "$f" || true; done'
ssh <source> 'find ~/.claude/plugins ~/.claude/hud -maxdepth 2 -type f 2>/dev/null | sort'
```

If `~/open` is large, list its top-level directories before transfer:

```bash
ssh <source> 'du -sh ~/open/* 2>/dev/null | sort -h'
```

If MCP config may also live inside repositories, inspect the migrated project roots:

```bash
ssh <source> 'find ~/open -maxdepth 4 \( -name ".mcp.json" -o -path "*/.cursor/mcp.json" -o -name "mcp*.json" \) 2>/dev/null | sort'
```

## 2. Bootstrap The Target User

Create the target user from an admin-capable account:

```bash
sudo useradd -m -s /bin/bash <user>
sudo usermod -aG sudo <user>
sudo install -d -m 700 -o <user> -g <user> /home/<user>/.ssh
sudo touch /home/<user>/.ssh/authorized_keys
sudo chmod 600 /home/<user>/.ssh/authorized_keys
sudo chown <user>:<user> /home/<user>/.ssh/authorized_keys
```

Append the operator public key and verify key login:

```bash
cat ~/.ssh/id_rsa.pub | ssh <admin>@<target> 'sudo tee -a /home/<user>/.ssh/authorized_keys >/dev/null'
ssh <user>@<target> id
```

If passwordless sudo is required:

```bash
echo '<user> ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/<user> >/dev/null
ssh <user>@<target> 'sudo -n id'
```

## 3. Install nvm, Node LTS, And pnpm

Install `nvm`, then install the current LTS release:

```bash
curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
export NVM_DIR="$HOME/.nvm"
. "$NVM_DIR/nvm.sh"
nvm install --lts
nvm alias default 'lts/*'
nvm use default
corepack enable
corepack prepare pnpm@latest --activate
mkdir -p "$HOME/.local/share/pnpm" "$HOME/.local/bin"
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in *":$PNPM_HOME:"*) ;; *) export PATH="$PNPM_HOME:$PATH" ;; esac
pnpm config set global-bin-dir "$PNPM_HOME"
pnpm config set global-dir "$HOME/.local/share/pnpm/global"
```

Make the default version load in login and interactive shells:

```bash
grep -qxF 'export NVM_DIR="$HOME/.nvm"' ~/.bashrc || printf '\nexport NVM_DIR="$HOME/.nvm"\n[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"\nnvm use --silent default >/dev/null 2>&1 || true\n' >> ~/.bashrc
grep -qxF 'export PNPM_HOME="$HOME/.local/share/pnpm"' ~/.bashrc || printf '\nexport PNPM_HOME="$HOME/.local/share/pnpm"\ncase ":$PATH:" in *":$PNPM_HOME:"*) ;; *) export PATH="$PNPM_HOME:$PATH" ;; esac\n' >> ~/.bashrc
grep -qxF 'export PATH="$HOME/.local/bin:$PATH"' ~/.profile || printf '\nexport PATH="$HOME/.local/bin:$PATH"\n' >> ~/.profile
grep -qxF "alias npm='pnpm'" ~/.bash_aliases 2>/dev/null || printf "alias npm='pnpm'\n" >> ~/.bash_aliases
```

Install requested agent CLIs with `pnpm`. Common example:

```bash
pnpm add -g @openai/codex @anthropic-ai/claude-code @google/gemini-cli
```

Install GitHub CLI in a standard location. On Debian or Ubuntu, the OS package manager example is:

```bash
sudo apt-get update
sudo apt-get install -y gh
```

On other distributions, use the native package manager or place the official `gh` binary in `~/.local/bin` and keep that directory on PATH for login and interactive shells.

Validate with an interactive shell:

```bash
ssh -tt <user>@<target> "bash -i -c 'type npm; type gh; type codex; type claude; node -v; pnpm -v; gh --version | head -n 1; nvm current'"
```

## 4. Restore GitHub-Backed Skills

Prefer a checked-out private skills repository or a deploy key over local one-off scripts.

If the repository is already available locally on the target:

```bash
python ~/skills/skills/skills-manager/scripts/skills_manager.py --repo-url ~/skills install --skill skills-manager --agent both
python ~/skills/skills/skills-manager/scripts/skills_manager.py --repo-url ~/skills install --skill '*' --agent both
python ~/skills/skills/skills-manager/scripts/skills_manager.py --repo-url ~/skills status --agent both
```

If the repository must be cloned first:

```bash
git clone git@github.com:<owner>/skills.git ~/skills
```

## 5. Sync Shell Configuration Deliberately

Do not copy shell files wholesale. Merge only the settings that should survive on the target:

- keep: `NVM_DIR`, `PNPM_HOME`, PATH additions, `alias npm='pnpm'`, tmux helpers, editor preferences, and Git identity
- drop: proxy exports, host-specific bind addresses, stale absolute paths, and machine-only secrets

Re-check the merged files before transfer or before first login:

```bash
grep -nE 'proxy|nvm|pnpm|PATH|alias npm|tmux|gh' ~/.bashrc ~/.profile ~/.bash_aliases 2>/dev/null
```

## 6. Transfer Agent State And Projects

Build high-compression archives with explicit excludes and checksum verification instead of mutating the source tree.

Prefer a local relay if the source host cannot reach the target host directly:

```bash
ssh <source> 'tar -C ~ -cf - \
  --exclude=".codex/cache" \
  --exclude=".codex/logs" \
  --exclude=".codex/tmp" \
  --exclude=".claude/cache" \
  --exclude=".claude/logs" \
  --exclude=".claude/tmp" \
  .codex .claude .gemini .copilot .lingma | xz -T0 -9e -c' > agent-state.tar.xz
sha256sum agent-state.tar.xz > agent-state.tar.xz.sha256
scp agent-state.tar.xz agent-state.tar.xz.sha256 <user>@<target>:~/
ssh <user>@<target> 'cd ~ && sha256sum -c agent-state.tar.xz.sha256 && tar -xJf agent-state.tar.xz'
```

For project trees such as `~/open`, exclude transient directories instead of cleaning the source host:

```bash
ssh <source> 'tar -C ~ -cf - \
  --exclude="open/**/node_modules" \
  --exclude="open/**/.venv" \
  --exclude="open/**/__pycache__" \
  --exclude="open/**/.pytest_cache" \
  --exclude="open/**/.mypy_cache" \
  --exclude="open/**/.cache" \
  --exclude="open/**/.next" \
  --exclude="open/**/dist" \
  --exclude="open/**/build" \
  --exclude="open/**/coverage" \
  --exclude="open/**/.git" \
  open | xz -T0 -9e -c' > open-src.tar.xz
sha256sum open-src.tar.xz > open-src.tar.xz.sha256
scp open-src.tar.xz open-src.tar.xz.sha256 <user>@<target>:~/
ssh <user>@<target> 'cd ~ && sha256sum -c open-src.tar.xz.sha256 && tar -xJf open-src.tar.xz'
```

Fix ownership after transfer:

```bash
ssh <user>@<target> 'sudo chown -R <user>:<user> /home/<user>/open /home/<user>/.codex /home/<user>/.claude /home/<user>/.gemini /home/<user>/.copilot /home/<user>/.lingma'
```

If the source changed after the archive was created, finish with a source-only delta sync or targeted file copy for the changed project files before handoff.

## 7. Patch Host-Specific Paths

Review the restored configs and patch user, home, host, and runtime paths before first run:

```bash
grep -nE '/home/|chrome-devtools|hud|gh|pnpm|mcp' ~/.codex/config.toml ~/.claude/settings.json 2>/dev/null
command -v chrome-devtools-mcp 2>/dev/null
```

Typical patch cases:

- `/home/<old-user>` changed to `/home/<new-user>`
- `node /home/<old-user>/...` wrappers inside Claude HUD or plugin config
- Node-version-specific MCP commands under `~/.nvm/versions/node/.../bin/...`
- trusted project paths that moved on the target host

## 8. Final Verification

Check that the target host matches the intended state:

```bash
ssh <user>@<target> 'for d in ~/.codex ~/.claude ~/.gemini ~/.copilot ~/.lingma ~/open; do [ -e "$d" ] && du -sh "$d"; done'
ssh <user>@<target> 'find ~/.codex/skills ~/.claude/skills -maxdepth 2 -name SKILL.md 2>/dev/null | sort'
ssh -tt <user>@<target> "bash -i -c 'node -v; pnpm -v; type npm; type gh; type codex; type claude'"
ssh <user>@<target> 'sudo -n true'
ssh <user>@<target> 'python ~/skills/skills/skills-manager/scripts/skills_manager.py --repo-url ~/skills status --agent both'
ssh <user>@<target> 'command -v chrome-devtools-mcp 2>/dev/null; find ~/.claude/plugins ~/.claude/hud -maxdepth 2 -type f 2>/dev/null | sort | sed -n "1,20p"'
ssh <user>@<target> 'for f in ~/.bashrc ~/.profile ~/.bash_aliases ~/.codex/config.toml ~/.claude/settings.json; do [ -f "$f" ] && printf "\n### %s\n" "$f" && grep -nE "proxy|/home/|chrome-devtools|hud|gh|pnpm" "$f" || true; done'
```

Capture any intentionally skipped directories, credentials, or caches in the final handoff.
