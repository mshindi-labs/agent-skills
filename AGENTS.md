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
name: my-skill-name # kebab-case, max 64 chars, must match directory name
description: > # max 1024 chars, no angle brackets
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

## Running Skill Evals

Eval suites live at `skills/{skill-name}/evals/evals.json`. Each eval is run twice —
once with the skill (`with_skill`) and once without it (`without_skill`) — and the
delta between the two arms is the whole point of the measurement.

### Run every arm in a sandbox under `/tmp`, never inside this repo

`scripts/link-skills.sh` symlinks every skill in `skills/` into `.claude/skills/`,
`.agents/skills/`, `.agent/skills/`, and `.windsurf/skills/`. Any agent whose working
directory sits inside this repository — or any subdirectory of it — can discover and
load those skills. A `without_skill` arm run in here is not a baseline: it can load
the very skill it is supposed to be blind to, and the delta collapses.

```bash
SANDBOX=$(mktemp -d)                       # /tmp/tmp.XXXXXXXX — outside the repo
# ...run the arm with SANDBOX as its working directory...
```

Fixture-backed evals build their input inside the sandbox too. Each fixture's
`setup.sh` takes the target directory as its first argument and writes only there:

```bash
skills/audit-secrets/evals/fixtures/leaked-aws-and-rsa-key/setup.sh "$SANDBOX/repo"
```

Results are a different thing from sandboxes and do belong in the repo: write them to
`{skill-name}-workspace/iteration-N/{eval-name}/{with_skill,without_skill}/`.

### Writing assertions that measure the skill

An assertion both arms pass measures the model, not the skill. Detection assertions
("flags the obvious SQL injection") are usually this — a competent model finds the
obvious bug with or without the skill. Assert instead on what the skill instructs:

- **report structure** — the skill's named sections, in its order
- **severity discipline** — the skill's own severity mapping applied consistently
- **fix shape** — the concrete rewrite the skill prescribes, not generic advice
- **delegation** — handing the deep pass to the sibling skill that owns it
- **restraint** — leaving the deliberately-safe decoy in the fixture unflagged

`skills/review-auth/evals/evals.json` is the reference suite. Keep enough detection
assertions to catch a regression that stops finding the bug at all — two or three per
eval — and spend the rest on the axes above.

## Naming Conventions

- Skill directory: `kebab-case` (e.g., `functional-typescript`, `react-patterns`)
- `SKILL.md`: always uppercase, always this exact name
- Reference files: `kebab-case.md`
- Scripts: `kebab-case.sh`
