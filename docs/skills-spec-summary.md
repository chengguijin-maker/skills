# Skills Specification Summary

This summary is based on:

- Agent Skills open standard: https://agentskills.io/home
- OpenAI skills repository: https://github.com/openai/skills
- Anthropic skills repository: https://github.com/anthropics/skills

## 1. Common Core

Across the standard and both repositories, a skill is a self-contained folder of reusable instructions and optional resources.

The shared minimum is:

- One folder per skill
- A required `SKILL.md`
- Machine-readable metadata in `SKILL.md` frontmatter
- Human-readable task instructions in the body

## 2. Required Metadata

From the Agent Skills specification, the required metadata fields are:

- `name`
- `description`

The standard also defines optional metadata such as:

- `tools`
- `resource_tiers`
- `input_schema`

## 3. Common Directory Pattern

The open standard does not force a single repository layout, but in practice the OpenAI and Anthropic repositories converge on a simple pattern:

- `SKILL.md` for trigger metadata and core instructions
- `scripts/` for deterministic helpers
- `references/` for larger documentation that should be loaded only when needed
- `assets/` for files used in outputs
- `agents/` for agent-specific metadata

The last four items are an implementation pattern inferred from the two public repositories, not a strict requirement of the base standard.

## 4. Writing Guidance

The strongest cross-source guidance is:

- Keep the skill focused on a repeatable task
- Make the `description` explicit about when the skill should trigger
- Keep top-level instructions short and move detail into separate resources
- Prefer reusable helpers over repeating long procedures in every invocation

## 5. OpenAI-Specific Conventions

The OpenAI repository adds a distribution model:

- `skills/.system/` for preinstalled skills
- `skills/.curated/` for installable public skills
- `skills/.experimental/` for installable but less stable skills

OpenAI also uses `agents/openai.yaml` for Codex UI metadata such as:

- `display_name`
- `short_description`
- `default_prompt`

## 6. Anthropic Repository Pattern

The Anthropic repository presents skills as portable, composable task packages and emphasizes repository-based sharing and installation workflows.

In practice, that means:

- Keep each skill isolated
- Keep instructions reusable across sessions
- Prefer repository-level organization that makes skills easy to discover and sync

This is a practical interpretation of the repository structure and README, not a formal separate specification.

## 7. Repository Policy For This Repo

This repository follows the intersection of the three sources:

- Put real skills under `skills/`
- Keep every skill self-contained
- Require `SKILL.md` frontmatter with clear trigger language
- Use `agents/` only for agent-specific extensions
- Keep repository templates outside `skills/` so they are not mistaken for published skills
