---
name: repo-skill-authoring
description: Use when creating, updating, reviewing, or reorganizing skills in this repository. Applies this repo's layout, metadata rules, portability guidelines, and publication checklist.
---

# Repo Skill Authoring

This skill keeps contributions to this repository aligned with the Agent Skills standard and the repository conventions documented in `references/repo-checklist.md`.

## When To Use

Use this skill when the task involves:

- adding a new skill under `skills/`
- updating an existing skill's `SKILL.md`
- reviewing whether a skill is too verbose or too agent-specific
- deciding whether content belongs in `SKILL.md`, `references/`, `scripts/`, or `assets/`
- preparing a skill for publishing from this repository

## Workflow

1. Start from `templates/skill-template/` if the skill is new.
2. Name the folder in lowercase hyphen-case.
3. Make the `description` explicit about when the skill should trigger.
4. Keep `SKILL.md` focused on the reusable workflow, not on background essays.
5. Move large reference material into `references/`.
6. Keep agent-specific metadata in `agents/`.
7. Before finishing, review `references/repo-checklist.md`.

## Repository Rules

- Real skills live only under `skills/`.
- Templates stay under `templates/` and are not published as active skills.
- Avoid extra documentation files inside a skill unless they are direct working references.
- Prefer portable instructions that work across agents; isolate product-specific details under `agents/`.
- Add `scripts/` only when they improve determinism or remove repetitive code generation.

## Publishing Notes

- A published skill should be installable from a GitHub tree URL that points at `skills/<skill-name>/`.
- `agents/openai.yaml` is optional but useful for Codex UI metadata.
- If a skill depends on MCP or external services, document that dependency in the skill and in agent-specific metadata where appropriate.
