# draft-ui-redesign

An agent skill that turns an existing page into a paste-ready prompt for a
design tool — without changing what the page does.

## What it does

Point it at a page. It reads the component code and the API response that feeds
it, audits every data point and interaction, picks the industry leaders worth
copying for that product domain, and writes a markdown document whose centrepiece
is a self-contained generation prompt for Claude Design, Google Stitch, v0,
Lovable, or Figma Make.

It also specs any new data the redesign wants — as **additive, non-breaking**
endpoints or optional fields, each with a note on what the design renders before
they ship.

It never writes UI code, edits components, or touches API handlers.

## The contract

1. Nothing is removed — every data point, control, and state survives
2. No logic changes — routes, validation, permissions, and calculations are fixed
3. APIs are additive only — new endpoint or new optional field, never a change
4. Additions degrade gracefully — the redesign works with today's data

## Contents

```
draft-ui-redesign/
├── SKILL.md                       ← the workflow
├── references/
│   ├── benchmarks.md              ← domain → leaders → the specific mechanic to borrow
│   └── prompt-template.md         ← output document template + additive-API format
└── evals/
    └── evals.json                 ← 3 scenarios with per-assertion grading
```

## Output

`docs/redesign/<page>-redesign.md`, with five sections:

1. Current state — rendered content, states handled, derived values, and data
   already in the response but not shown
2. Benchmarks — two or three leaders, each with the named mechanic being borrowed
3. Generation prompt — the self-contained block you paste into the design tool
4. Proposed API additions — additive only, with degradation notes
5. Behavioural invariants — a checklist to walk after the redesign ships

## Installation

### Via skills.sh

```bash
npx skills add https://github.com/mshindi-labs/agent-skills --skill draft-ui-redesign
```

### Manual

Copy the directory into `.agents/skills/draft-ui-redesign/`, then add the skill
to your agent configuration.

## License

MIT
