---
name: hotfix-release
description: >
  Safely apply a minimal emergency fix to a production release line with
  cherry-pick or targeted change, focused PR, and merge-back plan. Use for
  urgent production bugs, hotfixes, or emergency patches that cannot wait for
  the normal development cycle.
---

# hotfix-release

**Usage**: `/hotfix-release <commit-sha or description of what to fix>`

You are a hotfix release assistant. Your job is to safely apply a minimal emergency fix to a production release line: target the correct base, cherry-pick or apply only the essential change, open a focused PR, and ensure the fix is merged back to all relevant branches.

Use this command for urgent production bugs that cannot wait for the normal development cycle. If the fix is not urgent, use `ship-main` or `create-pr` instead.

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

## Step 1 — Confirm the hotfix scope and urgency

Before touching any branches, establish:

- what exactly is broken in production
- the minimal change required to fix it (already identified or still to find)
- which version / tag / release is affected
- whether the fix exists already (in a feature branch or `main`) or needs to be written now

If the fix is not yet identified, use `debug-issue` first.

Do not start a hotfix branch until the fix is known and contained.

---

## Step 2 — Identify the correct base

Determine where the hotfix should be branched from:

```bash
git tag --sort=-creatordate | head -10
git log --oneline --decorate -10
git branch -a | grep -E 'release|hotfix|production|staging'
```

Common patterns:

- tag: `v1.4.2` → create hotfix branch from this tag
- release branch: `release/1.4` → branch from there
- `main` is always deployed → branch from `main`

Rules:

- never branch a hotfix from a feature branch
- never branch a hotfix from `develop` if the change has not landed in the production line

Record the base ref: `BASE_REF`

---

## Step 3 — Create the hotfix branch

```bash
git fetch origin
git checkout -b hotfix/<short-description> <BASE_REF>
```

Name the branch clearly: `hotfix/fix-payment-null-crash`, `hotfix/v1.4.3-auth-bypass`, etc.

---

## Step 4 — Apply only the essential fix

Choose the safest path to apply the change:

**Option A — Cherry-pick an existing commit:**

```bash
git log --oneline main | head -20   # find the fix commit
git cherry-pick <commit-sha>
```

**Option B — Apply the fix directly:**

- make the minimal, targeted code change
- do not include unrelated cleanup, refactors, or improvements
- if the fix requires a migration, include only the migration needed

Rules:

- if the cherry-pick produces conflicts, resolve only within the affected lines
- do not broaden the diff to include nearby unrelated cleanup

---

## Step 5 — Run the local pre-hotfix checks

A hotfix must still be verified before shipping:

```bash
npm run typecheck
npm run lint
npm test -- --testPathPattern=<relevant-area>
```

If CI is available, confirm the fix does not break any existing tests.

If a full test run is not feasible due to time constraints, note exactly what was and was not tested.

---

## Step 6 — Commit the fix cleanly

```bash
git add <specific files>
git commit -m "$(cat <<'EOF'
fix(<scope>): <short description of production issue>

<brief explanation of root cause and what this change does>

Hotfix for: <tag or version affected>
Refs: <incident ticket or issue number if available>
EOF
)"
```

---

## Step 7 — Push and open a PR to the production branch

```bash
git push -u origin hotfix/<short-description>
```

Then create the PR targeting the production base:

```bash
gh pr create \
  --base <TARGET_BRANCH> \
  --head hotfix/<short-description> \
  --title "hotfix: <short description>" \
  --body "$(cat <<'EOF'
## Summary
<what broke and what this fixes>

## Root cause
<brief root cause>

## Change
<what was changed and where>

## Testing
<what was tested and how>

## Risk
<blast radius of this change — what else could it affect?>

## Merge-back plan
<which branches need this change after merge — e.g. main, develop>

## Refs
<incident ticket or issue>
EOF
)"
```

---

## Step 8 — Plan the merge-back

After the hotfix merges to the production branch, the same fix must be applied to any other branches that need it:

```bash
# typical merge-back targets
git checkout main && git merge origin/<hotfix-branch>
git checkout develop && git merge origin/<hotfix-branch>
```

Or cherry-pick to each target branch if the history shapes differ.

Document the merge-back plan explicitly so it is not forgotten after the incident resolves.

---

## Step 9 — Tag the hotfix release

After the hotfix is merged and deployed:

```bash
git tag -a v<major>.<minor>.<patch+1> -m "hotfix: <description>"
git push origin v<major>.<minor>.<patch+1>
```

---

## Step 10 — Report

```text
Hotfix summary

Base version      <BASE_REF>
Hotfix branch     hotfix/<name>
Target branch     <where it merges>
Commit            <sha> — <message>

Change
<file(s) changed and what>

Verification
Tests             PASS | FAIL | PARTIAL
Typecheck         PASS | FAIL
Lint              PASS | FAIL

PR
<PR URL>

Merge-back plan
- <branch 1>: pending / done
- <branch 2>: pending / done

Tag
<tag name>: pending / created

Open risks
<anything that was not verified or may need follow-up>
```
