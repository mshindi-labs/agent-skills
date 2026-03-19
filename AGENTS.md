# AGENTS.md

Guidance for AI coding agents working in this repository.

## Repository Overview

A monorepo of agent skills. Each skill is a self-contained directory under
`skills/` with a `SKILL.md` and optional `references/` or `scripts/`.

## Creating a New Skill

### Directory Structure

```
skills/
  {skill-name}/           # kebab-case directory name
    SKILL.md              # Required: frontmatter + instructions
    references/           # Optional: detailed reference docs
      {topic}.md
    scripts/              # Optional: executable scripts
      {script-name}.sh
```

### SKILL.md Frontmatter

```yaml
---
name: {skill-name}          # kebab-case, max 64 chars, must match directory name
description: >              # max 1024 chars, no angle brackets
  One or more sentences describing what the skill does and when to trigger it.
  Include example trigger phrases.
---
```

Allowed frontmatter keys: `name`, `description`, `license`, `allowed-tools`,
`metadata`, `compatibility`.

### Content Guidelines

- Keep `SKILL.md` under 500 lines — move deep reference material to `references/`
- Write specific, trigger-phrase-rich descriptions so the agent activates the
  skill at the right time
- Use progressive disclosure: `SKILL.md` gives the overview, `references/`
  files give the depth
- Include concrete code examples with before/after patterns where relevant

### Packaging

To produce a `.skill` file for upload to agentskills.io, run from the
`skill-creator` tool:

```bash
cd /path/to/skill-creator
python3 -m scripts.package_skill /path/to/agent-skills/skills/{skill-name} ./dist
```

### Validation

```bash
python3 -m scripts.quick_validate /path/to/agent-skills/skills/{skill-name}
```

## Naming Conventions

- Skill directory: `kebab-case` (e.g., `functional-typescript`, `react-patterns`)
- `SKILL.md`: always uppercase, always this exact name
- Reference files: `kebab-case.md`
- Scripts: `kebab-case.sh`
