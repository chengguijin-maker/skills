# Operating Model

This skill manages installation and synchronization of skills from the private repository into agent-specific directories.

## Source Of Truth

The private GitHub repository is the source of truth.

Do not treat `~/.codex/skills` or `~/.claude/skills` as the long-term authoritative store. Those directories are deployment targets.

## Install Model

Install flow:

1. Clone the private repository to a temporary directory
2. Read `catalog/skills.json`
3. Copy the requested skill directory into the target agent directory
4. Update the local install manifest

## Sync Model

Sync flow:

1. Clone the private repository at the configured ref
2. Read `catalog/skills.json`
3. Compare remote `content_hash` with the local install manifest
4. Backup and replace any changed managed skills

## Manifest Model

Each target root stores:

```text
<agent-root>/.skills-manager/installed.json
```

Each manifest entry records:

- skill name
- repo URL
- ref
- repo path
- content hash
- source type
- installed timestamp

## Private Repository Access

The manager supports private repositories through normal git authentication.

Preferred methods:

- existing git credential manager
- SSH remotes
- `GITHUB_TOKEN` or `GH_TOKEN`

If a token is available and the repo URL is HTTPS, the runtime script can inject the token into the clone URL.

## Managing First-Party Vs Mirrored Skills

First-party skills:

- edit the skill directly in this repository
- keep `source.type` as `first_party`

Mirrored skills:

- copy the upstream skill into `skills/<name>/`
- record upstream provenance in `catalog/sources.lock.json`
- treat local edits as intentional divergence
- document any divergence in commit history or repository docs
