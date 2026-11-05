# redesign-in-claude

An agent skill that takes a page from working code to a live Claude Design
mockup in one run — no copying prompts between tools.

## What it does

It chains two steps:

1. **Draft** — runs [`draft-ui-redesign`](../draft-ui-redesign/) on the page,
   which audits every data point and interaction and writes
   `docs/redesign/<page>-redesign.md` with a self-contained generation prompt.
2. **Design** — takes that prompt and builds the redesign as a Claude Design
   artifact, with artboards for every state (loading, empty, error, dense) and
   breakpoint the prompt lists.

The design link is written back into the redesign document, so the doc and the
design stay connected. The doc remains the source of truth for content.

It adds no design rules of its own — the presentation-only contract from
`draft-ui-redesign` applies unchanged.

## Requirements

- **Claude only.** It uses the Artifact tool's Design type, which only Claude
  (Claude Code or claude.ai) has. Other agents should use `draft-ui-redesign`
  and paste the prompt into their design tool by hand.
- `draft-ui-redesign` installed alongside it.
- **Optional:** Anthropic's official `frontend-design` plugin (from the
  `claude-plugins-official` marketplace: `/plugin install frontend-design`).
  When it's installed, the design step follows its plan → review → build →
  critique process. The redesign brief still overrides it: no hero sections,
  no renamed labels, no invented content. Without it, the skill builds the
  design straight from the prompt.

## Usage

```
/redesign-in-claude /settings/billing
```

## Contents

```
redesign-in-claude/
├── SKILL.md      ← the four-stage chain: draft → extract → design → hand back
└── README.md
```

## Installation

### Via skills.sh

```bash
npx skills add https://github.com/mshindi-labs/agent-skills --skill draft-ui-redesign
npx skills add https://github.com/mshindi-labs/agent-skills --skill redesign-in-claude
```

### Manual

Copy both directories into `.claude/skills/`.

## License

MIT
