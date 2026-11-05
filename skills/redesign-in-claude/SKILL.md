---
name: redesign-in-claude
description: >
  End-to-end page redesign straight into Claude Design. Runs the
  draft-ui-redesign skill to audit a page and produce its self-contained
  generation prompt, then uses that prompt to build the redesign as a Claude
  Design artifact (the Artifact tool's Design type) — no copy-pasting between
  tools. Use when the user says "redesign this page in Claude Design", "take
  this screen through Claude Design", "draft and design the redesign", or runs
  /redesign-in-claude with a route or file. Claude-only: it targets Claude
  Design exclusively, never Stitch, v0, Lovable, or Figma Make.
license: MIT
compatibility: >
  Claude only (Claude Code or claude.ai). Requires the Artifact tool with the
  Design type, and the draft-ui-redesign skill installed alongside it.
metadata:
  author: mshindi-labs
  version: "1.0.0"
---

# Redesign in Claude Design

Two stages, run in order without stopping in between unless something blocks:

1. **Draft** — `draft-ui-redesign` writes the redesign document and its prompt.
2. **Design** — that prompt becomes a live Claude Design artifact.

This skill adds no design rules of its own. The contract (nothing removed, no
logic changes, additive-only APIs, graceful degradation) and all the audit
rules belong to `draft-ui-redesign` — do not restate or loosen them here.

## Stage 1 — Draft the prompt

Invoke the skill with the Skill tool:

- `skill: "draft-ui-redesign"`
- `args`: the user's route or file, plus: `Target tool: Claude Design only.`

Follow it completely (locate → audit → benchmarks → gaps → write the doc). It
writes `docs/redesign/<page>-redesign.md`.

**Stop here and ask the user** if `draft-ui-redesign` could not find the real
response shape. A design built on guessed fields is worthless, and Stage 2
would only make it look polished.

## Stage 2 — Extract the prompt

Read the generated document and take the content of the fenced `text` block
under `## 3. Generation Prompt`, verbatim. That block is the only thing that
goes to Claude Design.

Before using it, check it is self-contained: no file paths, no "see the table
above", no raw field names without a description of what they hold. If it
fails the check, fix it in the document first so the doc and the design match.

## Stage 3 — Build it in Claude Design

1. Call `Artifact` with `action: "quickstart"`, `intent: "design"`. Always do
   this fresh; never hardcode the Design type's `type_url`.
2. Publish with the returned `type_url`, `title: "<Page Name> redesign"`, no
   files, and `auto_open: "after_first_write"`.
3. Follow the instructions in the create result to fill the artifact. The
   extracted prompt is the brief. Design every state it lists (loading, empty,
   error, dense/overflowing) and every responsive breakpoint as its own
   artboard, not just the happy path.
4. If the user names a design system, use it. Otherwise carry on without one,
   as the quickstart result says.

Do not use `DesignSync` here. It syncs design-system component libraries and
cannot create designs.

## Stage 4 — Hand back

Link the design doc and add the artifact's URL to its top, as
`Claude Design: <url>`, so the two stay connected. Then report briefly:

- Design artifact link
- Document path: `docs/redesign/<page>-redesign.md`
- API additions proposed (from section 4), or "none needed"
- Anything you had to guess or that the user should review

## If something fails

- **Artifact publish refused or the Design type is unavailable:** stop, say so
  plainly, and point the user at the prompt block in the doc so they can paste
  it into claude.ai/design by hand. Do not switch to another design tool.
- **The user wants changes to the design:** edit the same artifact by its
  `url`. If the change affects content (adds or removes a data point), update
  the doc's prompt and inventory first. The doc stays the source of truth.
