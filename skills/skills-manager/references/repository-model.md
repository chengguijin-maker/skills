# Repository Model

This repository uses one physical layout and one logical catalog.

## Physical Layout

```text
skills/
  <skill-name>/
templates/
  <template-name>/
catalog/
  sources.lock.json
  skills.json
docs/
```

## Why Skills Stay Flat

Keep installable skills directly under `skills/` instead of nesting by category.

Reason:

- Codex and Claude installs are simpler when each skill has a stable direct path
- GitHub tree URLs stay predictable
- Mirror and first-party skills can use the same install flow

## Classification

Use `catalog/sources.lock.json` for logical classification.

Recommended categories:

- `management`
- `discovery`
- `documentation`
- `testing`
- `frontend`
- `backend`
- `devops`
- `productivity`
- `integration`
- `data`

Add free-form tags when category alone is too coarse.

## Provenance

Each entry in `catalog/sources.lock.json` should declare one source type:

- `first_party`: created and maintained in this repository
- `mirrored`: copied from an upstream public or private repository

Mirrored skills should also record:

- `upstream_repo`
- `upstream_path`
- `ref`

## Generated Catalog

`catalog/skills.json` is a generated file.

It should contain:

- skill name
- description
- repo path
- category
- tags
- install URL
- source type
- content hash

The content hash is the update key used by `skills-manager` for install status and sync decisions.

At runtime, `skills-manager` also hashes the actual installed skill directory so it can detect local drift, partial installs, or manual edits under `~/.codex/skills` and `~/.claude/skills`.
