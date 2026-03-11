---
name: skill-template
description: Template only. Copy this folder to skills/<skill-name>/ and replace all placeholders before publishing or installing.
---

# Skill Template

## Overview

Replace this file with a concise, reusable skill for one repeatable task.

## Required Pieces

- Frontmatter with `name` and `description`
- A short explanation of when to use the skill
- A task workflow or decision tree
- Optional `scripts/`, `references/`, `assets/`, and `agents/`

## Authoring Checklist

- Replace `skill-template` with the real skill name
- Replace the placeholder description with a trigger-oriented description
- Keep the main file concise
- Put deep documentation in `references/`
- Put deterministic helpers in `scripts/`
- Put output-only resources in `assets/`
- Keep agent-specific metadata in `agents/`

## Minimal Shape

```md
---
name: your-skill-name
description: Use when ...
---

# Your Skill Name

## When To Use

Describe the trigger conditions.

## Workflow

List the repeatable steps.
```
