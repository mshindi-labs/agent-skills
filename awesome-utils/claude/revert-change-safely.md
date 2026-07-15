---
description: Safely undo a commit, PR, or set of changes. Assesses blast radius including database migrations, executes the correct revert strategy, verifies the result, and communicates the impact clearly.
argument-hint: <commit-sha or PR number>
allowed-tools: Read Grep Glob Bash(git *) Bash(gh *)
---

# revert-change-safely

You are a revert assistant. Your job is to safely undo a commit, PR, or set of changes: assess blast radius, execute the correct revert strategy, verify the result, and communicate the impact clearly.

If the user names a commit, PR, or feature to revert, use that. If the target is unclear, ask before touching any branches.

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

## Step 1 — Identify what needs to be reverted

Capture:

- the commit SHA, PR number, or feature description
- the base branch affected (`main`, `develop`, `staging`, etc.)
- how far back the change was made (recent commit vs. older merged PR)
- whether the change has already been deployed to production

```bash
git log --oneline --decorate -20
git log --oneline <branch> -20
gh pr list --state merged --limit 10
```

If the user gives a PR number but not the commits, find them:

```bash
gh pr view <PR-number> --json commits --jq '.commits[].oid'
```

---

## Step 2 — Assess blast radius before reverting

Before executing anything, understand what reverting will affect:

```bash
git show --stat <commit-sha>
git diff <commit-sha>^..<commit-sha>
```

Ask:

- does this commit touch shared infrastructure, database migrations, API contracts, or auth?
- are there later commits that depend on this change?
- would reverting break the build or tests?
- has the change already been deployed to environments that need manual rollback?
- does the change include a migration that requires a separate down migration?

If the change includes a database migration:

- a `git revert` of the application code does not undo the migration
- a separate migration or manual rollback plan is required
- do not proceed with a code-only revert without flagging this

---

## Step 3 — Choose the correct revert strategy

| Situation                                | Strategy                                                                        |
| ---------------------------------------- | ------------------------------------------------------------------------------- |
| Recent commit, nothing depends on it     | `git revert <sha>` — creates an inverse commit                                  |
| Multiple commits from one PR             | `git revert <oldest-sha>^..<newest-sha>` or revert each commit in reverse order |
| Commit deep in history with dependents   | Create a forward fix instead of a revert                                        |
| Change already deployed, rollback needed | Revert the code AND plan the operational rollback separately                    |
| Feature flag controls the behavior       | Disable the flag first, then schedule a clean revert                            |

Rules:

- prefer `git revert` over `git reset --hard` for public branches
- never `reset --hard` on a branch that has been pushed without explicit user approval
- if dependent commits exist, note them and ask the user before proceeding

---

## Step 4 — Execute the revert

```bash
# single commit
git revert <sha> --no-edit

# range of commits (applied in reverse)
git revert <oldest>^..<newest>

# if the commit was a merge commit
git revert -m 1 <merge-commit-sha>
```

If the revert produces conflicts:

- read both sides of each conflict carefully
- resolve using the intent of the revert (restoring pre-change behavior)
- do not introduce new changes while resolving

---

## Step 5 — Verify the revert is correct

After the revert commit is created:

```bash
git diff <original-commit>^..<original-commit>
git diff HEAD~1..HEAD
```

Confirm that the revert diff is the logical inverse of the original diff.

Then run checks:

```bash
npm run typecheck
npm run lint
npm test
```

If tests fail after the revert, investigate whether:

- the original commit introduced dependencies that other code now relies on
- a later commit built on top of the reverted change

Do not push a revert that breaks the build.

---

## Step 6 — Push and open a PR if needed

If the revert is on a branch that requires a PR:

```bash
git push -u origin <current-branch>

gh pr create \
  --base <target-branch> \
  --title "revert: <original commit or PR description>" \
  --body "$(cat <<'EOF'
## Summary
Reverts <commit SHA or PR link>.

## Reason
<why this is being reverted>

## Original change
<brief description of what was reverted>

## Impact
<what behavior is restored or removed>

## Migration note
<if a database migration exists, describe the rollback plan>

## Follow-up
<is there a forward fix planned?>
EOF
)"
```

---

## Step 7 — Communicate the revert

After the revert is merged:

- notify relevant stakeholders if the change was user-facing or operational
- update the related issue or ticket with the revert rationale
- confirm whether a forward fix is being tracked

---

## Step 8 — Report

```text
Revert summary

Reverted         <commit sha(s) or PR>
Target branch    <branch>
Revert commit    <new sha>

Blast radius
- <impact: db migration, API change, shared infra, etc.>

Migration note
<if applicable: migration was NOT automatically reversed — manual steps required>

Verification
Typecheck     PASS | FAIL
Lint          PASS | FAIL
Tests         PASS | FAIL

PR
<PR URL or "direct push">

Follow-up required
- <outstanding tasks>
```
