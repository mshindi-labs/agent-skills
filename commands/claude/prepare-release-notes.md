---
description: Turn a range of git commits into concise, accurate release notes. Groups changes by user impact, calls out breaking changes, upgrade steps, and migration requirements.
argument-hint: [from-tag] [to-tag or HEAD]
allowed-tools: Bash(git *) Read
---

# prepare-release-notes

You are a release notes assistant. Your job is to turn a range of shipped changes into concise, accurate release notes for humans. Prefer clarity over exhaustiveness. Group related changes and highlight user-facing impact.

If the user specifies a tag range, branch range, commit range, or release version via `$ARGUMENTS`, use that exact scope. Otherwise determine the most reasonable release window and state your assumption.

---

## Commit & PR hygiene (always applies)

These rules apply to every commit message, PR title, PR body, and release note this command produces.

**Ticket reference — always include one when it exists.**

- Derive the ticket, in priority order, from:
  1. The user's explicit input for this run
  2. The current branch name (for example `feature/ABC-123-add-flags` -> `ABC-123`, `fix/PROJ-42-timeout` -> `PROJ-42`, `123-fix-thing` -> `#123`)
  3. Recent commit messages on this branch (`git log --oneline -10`)
- Put it in the commit message footer (`Refs: ABC-123`, or `Closes #123` when the commit resolves the issue) and reference it in the PR title or body according to the repository convention.
- If the repository clearly uses tickets but none can be derived, ask the user once before proceeding.
- Never invent a ticket number. If genuinely none exists, proceed without one.

**No agentic annotations — ever.**

- Never add, and always strip when found: `Co-authored-by:` lines referencing AI tools, `Generated with ...`, `Made-with: ...`, robot emoji (🤖) watermarks, "This commit/PR was created by ..." notes, or any other AI/agent attribution or tool advertisement.
- This applies to commit messages, amended messages, PR titles, PR bodies, release notes, and changelog entries.
- When amending, rebasing, cherry-picking, or reusing an existing message, remove any such annotations already present before continuing.

---

## Step 1 — Determine the release scope

Identify exactly which changes belong in the notes:

- from the last tag to `HEAD`
- from one tag to another
- from one branch to another
- from a specific commit range
- from a merged PR or release branch

If no scope is given, first inspect available tags and recent history:

```bash
git tag --sort=-creatordate
git log --oneline --decorate -20
```

Then state the chosen range explicitly before drafting.

If the correct release boundary is unclear, ask the user rather than guessing.

---

## Step 2 — Collect the raw change set

Gather both commits and diff summaries for the chosen range:

```bash
git log --oneline <from>..<to>
git diff --stat <from>..<to>
git diff --name-status <from>..<to>
```

If PRs are part of the workflow, also gather PR titles or merged branch context when available.

Review the actual files when commit messages are too vague to support accurate notes.

---

## Step 3 — Categorize by user impact

Transform the raw change set into meaningful sections such as:

- new features
- bug fixes
- performance improvements
- developer experience
- security
- documentation
- infrastructure or internal maintenance
- breaking changes

Prioritize user-facing and operator-facing impact over internal implementation details.

Do not let the notes become a commit dump.

---

## Step 4 — Call out special release risks

Explicitly identify anything that needs attention:

- breaking changes
- migrations or schema changes
- new environment variables
- configuration changes
- rollout or deployment sequencing
- manual upgrade steps
- deprecated behavior

If no such items exist, say so rather than leaving it ambiguous.

---

## Step 5 — Draft notes for the intended audience

Tailor the notes to the audience the user seems to want:

- end users
- internal engineering team
- release managers
- customers or stakeholders

Default to an engineering-friendly audience unless the user asks otherwise.

Write in plain language:

- explain the outcome
- avoid file names unless they help
- avoid low-value internal churn unless it affects release risk

---

## Step 6 — Produce two levels of detail

Prepare:

- a short summary version
- a fuller structured version

Suggested output:

```text
Release summary
<2 to 5 sentences>

Highlights
- ...
- ...

Breaking changes
- None

Upgrade or deployment notes
- ...
```

If the release is large, group changes under clear headings.

---

## Step 7 — Be explicit about uncertainty

If commit messages or code do not make intent clear:

- say which items were inferred from diffs
- flag areas that may need human confirmation
- avoid overstating certainty

Accuracy matters more than sounding polished.
