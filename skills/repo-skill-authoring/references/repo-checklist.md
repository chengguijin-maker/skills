# Repository Checklist

Use this checklist before committing or publishing a skill from this repository.

## Naming

- Folder name is lowercase hyphen-case
- Frontmatter `name` matches the folder name
- The skill name is short and task-oriented

## Frontmatter

- `name` is present
- `description` is present
- `description` says when the skill should be used

## Content

- `SKILL.md` is concise
- The main workflow is obvious
- Long details were moved into `references/`
- Deterministic helpers were moved into `scripts/`
- Output resources live in `assets/`

## Portability

- Shared instructions are not tied to one product unless necessary
- Agent-specific metadata lives under `agents/`
- External dependencies are documented

## Repository Placement

- Real skills are under `skills/`
- Templates are under `templates/`
- Repository-wide notes are under `docs/`
