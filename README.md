# Personal Skills Repository

This repository is a dedicated home for reusable agent skills under the `chengguijin-maker` account.

It is designed to stay compatible with:

- The Agent Skills open standard: https://agentskills.io/home
- OpenAI Codex skills conventions: https://github.com/openai/skills
- Anthropic skills repository patterns: https://github.com/anthropics/skills

## Repository Layout

```text
skills/
  repo-skill-authoring/
templates/
  skill-template/
docs/
  skills-spec-summary.md
```

- `skills/`: real skills that can be published or installed.
- `templates/`: starter material that should be copied before use.
- `docs/`: repository-level notes and standards summaries.

## Core Conventions

- Each skill lives in its own folder.
- Every skill must contain `SKILL.md`.
- `SKILL.md` must include YAML frontmatter with `name` and `description`.
- Keep `SKILL.md` concise and task-focused.
- Put deep documentation in `references/`, executable helpers in `scripts/`, and output resources in `assets/`.
- Keep agent-specific metadata in `agents/` instead of mixing it into the shared skill instructions.

## Adding a New Skill

1. Copy `templates/skill-template/` into `skills/<skill-name>/`.
2. Replace placeholder metadata and instructions in `SKILL.md`.
3. Add `agents/openai.yaml` only when Codex UI metadata is useful.
4. Add `scripts/`, `references/`, and `assets/` only when they materially help.
5. Review `docs/skills-spec-summary.md` before publishing.

## Publishing

After this repo is on GitHub, a Codex skill can be installed from a GitHub tree URL that points at a folder under `skills/`.

Example:

```text
https://github.com/chengguijin-maker/skills/tree/main/skills/repo-skill-authoring
```
