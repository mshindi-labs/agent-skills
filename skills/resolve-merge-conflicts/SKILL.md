---
name: resolve-merge-conflicts
description: Resolve git conflict markers correctly by understanding both sides' intent, never silently discarding work, and verifying the result compiles and tests pass before continuing the merge or rebase.
---

# resolve-merge-conflicts

You are a merge conflict resolution assistant. Your job is to resolve conflict markers correctly, preserving the intent of both sides, and verify the result compiles and tests pass. Be methodical. Do not discard work without understanding both sides.

Use this after a `git merge`, `git rebase`, or `git pull` has left conflict markers in files.

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

## Step 1 — Assess the conflict scope

Before resolving anything, understand the full picture:

```bash
git status --short
git diff --name-only --diff-filter=U
git log --oneline --left-right --merge
```

Record:

- which files have conflicts
- how many conflict markers per file
- the branches involved and a summary of what each introduced

If the conflict is extensive (many files or many markers per file), list them all and ask the user if they want to resolve them in batches or all at once.

---

## Step 2 — Understand both sides before touching markers

For each conflicting file, read:

- the full conflict diff with markers
- the local (ours) intent: what the current branch was trying to do
- the incoming (theirs) intent: what the other branch was trying to do
- recent commits on each side that explain the changes

```bash
git log --oneline HEAD...MERGE_HEAD -- <file>
git diff MERGE_HEAD -- <file>
git diff HEAD -- <file>
```

Do not resolve a conflict by arbitrarily picking one side. Understand what both sides intended.

---

## Step 3 — Classify each conflict

For each set of markers, determine:

| Type                   | Description                                                       |
| ---------------------- | ----------------------------------------------------------------- |
| **Additive**           | Both sides added different things; both can coexist               |
| **Mutually exclusive** | Both sides changed the same logic differently; one must be chosen |
| **Superseded**         | One side's change makes the other side obsolete                   |
| **Ambiguous**          | Intent unclear; needs clarification before resolving              |

For mutually exclusive or ambiguous conflicts, do not guess. Ask the user to clarify the intended behavior.

---

## Step 4 — Resolve conflicts file by file

For each conflict:

1. read the full context around the markers
2. determine the correct merged result based on both sides' intent
3. edit to remove the markers and produce the correct combined result
4. verify the surrounding code is logically consistent after the merge

Common patterns:

- **both added an import**: keep both, order appropriately
- **both modified a function body**: apply both changes if they affect different lines; choose one if they affect the same line based on which intent is correct
- **both added a test or migration**: keep both
- **one side deleted, one side modified**: decide based on which change is correct; never silently drop a deletion or modification

Rules:

- never leave `<<<<<<<`, `=======`, or `>>>>>>>` markers in the file
- never silently discard code from either side without a reason
- if a file has too many conflicts to resolve confidently, stop and ask

---

## Step 5 — Verify the resolved files compile

After resolving each file or all files, check that the project is in a buildable state:

```bash
# typecheck
npm run typecheck
npx tsc --noEmit

# build
npm run build
```

Fix any compilation errors introduced by the conflict resolution before proceeding.

---

## Step 6 — Run the affected tests

After compilation passes, run the tests most relevant to the resolved files:

```bash
npx jest --testPathPattern=<related-path>
pytest <related-path>
go test ./...
```

If any tests fail:

- determine whether the failure is caused by a wrong resolution decision
- if so, revisit the conflict markers and review both sides' intent again

---

## Step 7 — Stage the resolved files and continue

Once all conflicts are resolved and checks pass:

```bash
git add <resolved-file1> <resolved-file2>
```

Then continue the merge or rebase:

```bash
# if in a merge
git commit

# if in a rebase
git rebase --continue
```

If additional conflict sets appear during `--continue`, repeat Steps 2–6 for each batch.

---

## Step 8 — Verify the final state

After the merge or rebase completes:

```bash
git status --short
git log --oneline -5
npm test
```

Confirm:

- no conflict markers remain in any file
- the working tree is clean
- the test suite passes
- the git log shows the expected history shape

---

## Step 9 — Report

```text
Conflict resolution summary

Files resolved    <N>
Total markers     <N>

Resolution decisions
- <file>:<line range> — <brief description of what each side wanted and how it was resolved>
- ...

Ambiguous items deferred
- <file> — reason

Verification
Compilation   PASS | FAIL
Tests         PASS | FAIL
Working tree  clean | dirty

Next step
<ready to push | needs manual review | rebasing in progress>
```

If any conflict was resolved by choosing one side and discarding the other, explain why in the report.
