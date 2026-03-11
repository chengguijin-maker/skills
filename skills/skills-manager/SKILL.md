---
name: skills-manager
description: Use when installing, listing, checking, or syncing skills from the private GitHub repository into Codex or Claude. Also use when maintaining the private skills catalog, updating source locks, or managing first-party versus mirrored skills.
---

# Skills Manager

This skill treats the private GitHub repository as the single source of truth for reusable skills and deploys them into agent-specific skill directories.

Read `references/repository-model.md` before editing repository structure and `references/operating-model.md` before changing install or sync behavior.

## When To Use

Use this skill when the task involves:

- installing a skill from the private repository into Codex or Claude
- listing available skills from the private repository
- checking whether installed managed skills are out of date
- syncing installed skills after the private repository changes
- rebuilding the repository catalog after adding or removing skills
- managing first-party skills and mirrored third-party skills in one repository

## Commands

Use `scripts/skills_manager.py` for runtime operations:

```bash
python scripts/skills_manager.py list
python scripts/skills_manager.py status --agent codex
python scripts/skills_manager.py install --skill skills-manager --agent codex
python scripts/skills_manager.py sync --agent both
```

## Install This Skill

Codex can install this skill from the GitHub tree URL:

```text
https://github.com/chengguijin-maker/skills/tree/main/skills/skills-manager
```

Claude can install it by copying or cloning this skill directory into:

- `~/.claude/skills/skills-manager`

Use `scripts/build_catalog.py` inside a checked-out repository to rebuild `catalog/skills.json` after editing `catalog/sources.lock.json` or changing skill contents:

```bash
python skills/skills-manager/scripts/build_catalog.py --repo-root .
```

## Workflow

1. Keep installable skills flat under `skills/<skill-name>/`.
2. Record every published skill in `catalog/sources.lock.json`.
3. Rebuild `catalog/skills.json` after any skill add, remove, rename, or content change.
4. Install and sync skills through this manager so manifests stay consistent.
5. For third-party mirrored skills, record the upstream repository and path in `catalog/sources.lock.json`.

## Repository Model

- `skills/` holds installable skills.
- `templates/` holds templates and must not be treated as install targets.
- `catalog/sources.lock.json` is the provenance and classification source of truth.
- `catalog/skills.json` is the generated index consumed by this manager.

## Classification Rules

- Classify skills logically, not by nesting directories.
- Keep folder layout flat for install compatibility.
- Put categories and tags in `catalog/sources.lock.json`.
- Use `source.type = first_party` for your own skills.
- Use `source.type = mirrored` for copied third-party skills and include upstream metadata.

## Install Targets

- Codex global skills: `~/.codex/skills`
- Claude global skills: `~/.claude/skills`

The manager writes an install manifest under each target root so later syncs know what was installed and from which repository state.
