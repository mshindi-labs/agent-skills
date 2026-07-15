# create-pr

**Usage**: `/create-pr <target-branch>` — for example `/create-pr dev`, `/create-pr staging`, `/create-pr main`

If the user did not specify a target branch, **ask before continuing**:

> "Which branch should this PR target? (for example `dev`, `staging`, or `main`)"

Treat the branch name provided by the user as `TARGET_BRANCH`.

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

## Step 1 — Preflight checks

Inspect the repository before staging, committing, pushing, or creating a PR:

```bash
git branch --show-current
git status --short
git diff
git diff --staged
git status -sb
git fetch origin
git log --oneline --decorate -5
```

Record:

- `CURRENT_BRANCH`
- whether there are staged changes, unstaged changes, or untracked files
- whether `CURRENT_BRANCH` already tracks a remote branch
- whether the branch is ahead, behind, or diverged from its upstream

Stop and ask the user if:

- `CURRENT_BRANCH` is empty, detached, or equals `TARGET_BRANCH`
- the working tree contains suspicious unrelated changes
- the branch is behind its upstream and a rebase/merge decision is needed

If there are no changes to commit **and** no commits on `CURRENT_BRANCH` that are not already in `TARGET_BRANCH`, stop and tell the user there is nothing to open a PR for.

---

## Step 2 — Validate the target branch and PR state

Before creating the PR, confirm the target branch exists on the remote and that a PR is not already open for the same branch pair.

Run checks equivalent to:

```bash
git ls-remote --heads origin <TARGET_BRANCH>
git log origin/<TARGET_BRANCH>..HEAD --oneline
git diff --stat origin/<TARGET_BRANCH>...HEAD
gh pr list --head <CURRENT_BRANCH> --base <TARGET_BRANCH> --state open
```

Rules:

- If `origin/<TARGET_BRANCH>` does not exist, stop and report it
- If there are zero commits between `origin/<TARGET_BRANCH>` and `HEAD`, stop and tell the user there is nothing new to propose
- If an open PR already exists for `CURRENT_BRANCH` -> `TARGET_BRANCH`, do **not** create a duplicate; return that PR instead

---

## Step 3 — Look for a repository PR template

Before writing the PR body, check for a repository template in `.github/`, including:

```text
.github/pull_request_template.md
.github/PULL_REQUEST_TEMPLATE.md
.github/PULL_REQUEST_TEMPLATE/*.md
```

If a template exists:

- Read it and use it as the default structure
- Preserve its section headings unless the repository clearly prefers a different format
- Fill in only the sections supported by the actual diff and evidence available
- Leave placeholders or unchecked items only when the information is genuinely unavailable

For this repository, prefer the detected template over any generic fallback.

---

## Step 4 — Review the full change set

Build a complete understanding of what the PR will contain:

```bash
git diff origin/<TARGET_BRANCH>...HEAD
git diff --name-status origin/<TARGET_BRANCH>...HEAD
git diff --stat origin/<TARGET_BRANCH>...HEAD
git log origin/<TARGET_BRANCH>..HEAD --oneline
```

Understand:

- the full file-level diff
- all commits included in the PR, not just the latest one
- whether the branch mixes unrelated work that should be split first
- whether there are migrations, config changes, docs changes, or breaking changes

If the branch contains multiple unrelated concerns, stop and ask the user before creating a broad PR.

---

## Step 5 — Handle local changes before PR creation

If there are uncommitted local changes, decide whether a commit is needed first.

Rules:

- Never stage secrets, `.env`, `.env.*`, private keys, or similar sensitive files
- Never use `git add -A` or `git add .` unless the user explicitly confirms every changed file belongs
- Prefer explicit staging paths
- If the current work is intentionally incomplete and the user only wants a PR for already committed work, do not auto-commit local changes
- If the PR requires the local changes, create a commit first using the repository commit rules

When committing:

- Use a proper conventional commit message if the repo enforces it
- Prefer a HEREDOC for multi-line commit messages
- Do not add AI attribution or `Co-authored-by`
- If hooks fail, inspect the failure, fix what is reasonable, and retry safely

If there is nothing new to commit, skip this step.

---

## Step 6 — Push safely

Push `CURRENT_BRANCH` only after confirming the branch state.

Preferred commands:

```bash
git push -u origin <CURRENT_BRANCH>
```

If the upstream already exists and is healthy:

```bash
git push origin <CURRENT_BRANCH>
```

Rules:

- Never force push unless the user explicitly asks for it
- If the push is rejected because the remote moved, stop and report the reason
- If authentication or permission fails, report it clearly

---

## Step 7 — Draft the PR title and body

### PR title

Use the best summary of the branch:

- If the PR contains one main commit, the title can closely follow that commit subject
- If the PR contains multiple commits, summarize the overall change rather than copying only the latest commit
- Keep the title concise and reviewer-friendly

### PR body

If a repository PR template exists, use it.

For this repository, populate these sections when applicable:

```markdown
## Summary

<brief description of the change set>

## Changes Made

- <main change>
- <main change>

## Related Issue(s)

- <Fixes/Closes/Relates to ... if known>

## Type of Change

- [x] <relevant type>

## Testing

- [x] <only if actually verified>

<describe the tests that were run>

## Database Changes

- [x] <relevant option>

<describe migration/schema impact if any>

## Deployment Notes

<special deployment considerations if any>

## Checklist

- [x] <only for items you can support with evidence>

## JIRA Ticket(s)

<ticket if known>

## Screenshots (if applicable)

<only when relevant>

## Additional Notes

<reviewer context, risks, or follow-up>
```

Rules:

- Do not claim tests passed unless you ran them or the user explicitly confirmed them
- Do not invent issue numbers, tickets, screenshots, migrations, or deployment steps
- Mention risks, missing verification, or follow-up work explicitly

---

## Step 8 — Create the PR safely

Use `gh pr create` with a HEREDOC body so formatting is preserved:

```bash
gh pr create \
  --base <TARGET_BRANCH> \
  --head <CURRENT_BRANCH> \
  --title "<title>" \
  --body "$(cat <<'EOF'
<body>
EOF
)"
```

Before running it:

- Ensure there is no existing open PR for the same `head` and `base`
- Ensure the branch has been pushed successfully
- Ensure the body reflects the repository template if one exists

After running it, capture the PR URL.

---

## Step 9 — Report back

Show the user:

- the PR URL
- the base branch and head branch
- whether a new commit was created, and the commit message if so
- a concise diff summary from `git diff --stat origin/<TARGET_BRANCH>...HEAD`
- major risks, missing tests, migration notes, or deployment concerns

If anything blocks completion, stop and explain the exact failure:

- invalid target branch
- push rejected
- hook failure
- existing PR already open
- no diff against target branch
