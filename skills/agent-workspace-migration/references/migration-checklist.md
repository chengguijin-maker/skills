# Migration Checklist

Use this checklist to migrate a Claude or Codex workspace from one Linux host to another.

## 1. Inventory The Source Host

Record the current state before copying anything:

```bash
ssh <source> 'hostnamectl | sed -n "1,12p"; id; df -h / /home'
ssh <source> 'du -sh ~/.codex ~/.claude ~/open 2>/dev/null'
ssh <source> 'du -sh ~/.nvm ~/.local/bin 2>/dev/null'
ssh <source> 'find ~/.codex/skills ~/.claude/skills -maxdepth 2 -name SKILL.md 2>/dev/null | sort'
ssh <source> 'command -v node; node -v 2>/dev/null; command -v npm; npm -v 2>/dev/null; command -v pnpm; pnpm -v 2>/dev/null; command -v gh'
```

If `~/open` is large, list its top-level directories before transfer:

```bash
ssh <source> 'du -sh ~/open/* 2>/dev/null | sort -h'
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
npm install -g pnpm@latest
```

Make the default version load in interactive shells:

```bash
printf '\nnvm use --silent default >/dev/null 2>&1 || true\n' >> ~/.bashrc
printf "alias npm='pnpm'\n" > ~/.bash_aliases
```

Validate with an interactive shell:

```bash
ssh -tt <user>@<target> "bash -i -c 'type npm; node -v; pnpm -v; nvm current'"
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

## 5. Transfer Data

Prefer a local relay if the source host cannot reach the target host directly:

```bash
ssh <source> 'tar -C ~ -cf - open' | ssh <user>@<target> 'tar -C ~ -xf -'
ssh <source> 'tar -C ~ -cf - .codex .claude' | ssh <user>@<target> 'tar -C ~ -xf -'
```

Or use `rsync` when it is available and connectivity permits it:

```bash
rsync -a --info=progress2 <source>:~/open/ <user>@<target>:~/open/
```

Fix ownership after transfer:

```bash
ssh <user>@<target> 'sudo chown -R <user>:<user> /home/<user>/open /home/<user>/.codex /home/<user>/.claude'
```

## 6. Final Verification

Check that the target host matches the intended state:

```bash
ssh <user>@<target> 'du -sh ~/.codex ~/.claude ~/open 2>/dev/null'
ssh <user>@<target> 'find ~/.codex/skills ~/.claude/skills -maxdepth 2 -name SKILL.md 2>/dev/null | sort'
ssh -tt <user>@<target> "bash -i -c 'node -v; pnpm -v; type npm'"
ssh <user>@<target> 'sudo -n true'
```

Capture any intentionally skipped directories, credentials, or caches in the final handoff.
