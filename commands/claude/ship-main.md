---
description: Prepare and open a pull request from the current branch to main. Validates branch state, commits pending work safely, pushes, and creates the PR using gh pr create.
allowed-tools: Bash(git *) Bash(gh *) Glob Read
disable-model-invocation: true
---

# ship-main

You are a ship assistant. Follow these steps **in order** without skipping. The goal is to safely prepare and open a PR from the current branch to `main`.

---

## Step 1 — Preflight and branch validation

Inspect the repository before making any changes:

```bash
git branch --show-current
git status --short
git diff
git diff --staged
git status -sb
git fetch origin
git log --oneline --decorate -5
git log origin/main..HEAD --oneline
git diff --stat origin/main...HEAD
```

Record:

- `CURRENT_BRANCH`
- whether there are uncommitted local changes
- whether the branch tracks an upstream
- whether the branch is ahead, behind, or diverged from its upstream
- whether there are commits on `HEAD` that are not in `origin/main`

Stop and ask the user if:

- `CURRENT_BRANCH` is `main`
- the worktree includes suspicious unrelated changes
- the branch is behind its upstream and needs a pull/rebase decision
- there are no commits or diff versus `origin/main`

---

## Step 2 — Check for shipping blockers

Before committing or opening a PR, look for blockers:

```bash
git ls-remote --heads origin main
git merge-base HEAD origin/main
git merge-tree $(git merge-base HEAD origin/main) origin/main HEAD
gh pr list --head <CURRENT_BRANCH> --base main --state open
```

Rules:

- If `origin/main` cannot be resolved, stop and report it
- If the merge simulation shows conflicts, stop and report that the branch is not merge-ready
- If an open PR from `CURRENT_BRANCH` to `main` already exists, do not create a duplicate; return that PR instead

---

## Step 3 — Review and isolate the intended changes

Read the actual changes, not just filenames.

Pay special attention to:

- secrets such as `.env`, `.env.*`, keys, credentials, or tokens
- generated artifacts such as `dist/`, `coverage/`, `build/`, `*.map`
- lockfile-only churn without a matching dependency manifest change
- migrations, config changes, workflow changes, or deployment-sensitive files
- unrelated edits that should not ship together

If anything looks accidental or ambiguous, stop and ask before staging.

---

## Step 4 — Stage changes explicitly

Never use `git add .` or `git add -A` by default.

Stage only the files that belong in this ship:

```bash
git add <file1> <file2> ...
git diff --staged
```

If some files are already staged and do not belong, unstage only those files carefully.

Do not proceed until the staged diff represents one coherent change set.

---

## Step 5 — Commit safely if needed

If there are local changes that belong in the PR, create a commit using the repository commit rules.

Use Conventional Commits unless the repository clearly uses another enforced format.

Preferred commit command:

```bash
git commit -m "$(cat <<'EOF'
<type>(<scope>): <subject>

<optional body>

<optional footer>
EOF
)"
```

Rules:

- keep the first line within 100 characters
- explain why in the body when useful
- use `BREAKING CHANGE:` in the footer when applicable
- never append AI attribution, `Co-authored-by`, or `Made-with: Cursor`
- do not use `--no-verify` unless the user explicitly asks for it

If hooks auto-fix files:

- inspect what changed
- re-stage only the intended files
- retry safely

If there is nothing to commit, skip this step.

---

## Step 6 — Push safely

Push the branch only after confirming the desired branch and remote state.

Preferred:

```bash
git push -u origin <CURRENT_BRANCH>
```

If the upstream already exists and is current:

```bash
git push origin <CURRENT_BRANCH>
```

Rules:

- never force push unless the user explicitly asks
- if push is rejected, stop and explain why
- if auth or permissions fail, report that clearly

---

## Step 7 — Use the repository PR template

Before writing the PR, check `.github/` for a PR template and use it if present.

Common locations:

```text
.github/pull_request_template.md
.github/PULL_REQUEST_TEMPLATE.md
.github/PULL_REQUEST_TEMPLATE/*.md
```

If a template exists:

- preserve its sections
- fill only what can be supported by the diff, commit history, and test evidence
- do not invent issue numbers, test results, screenshots, or deployment steps

For this repository, prefer the detected template with sections like:

- `Summary`
- `Changes Made`
- `Related Issue(s)`
- `Type of Change`
- `Testing`
- `Database Changes`
- `Deployment Notes`
- `Checklist`
- `JIRA Ticket(s)`
- `Additional Notes`

---

## Step 8 — Draft and create the PR

Use `gh` to create a PR from `CURRENT_BRANCH` to `main`.

Title rules:

- use the strongest summary of the whole branch
- if there is one main commit, the title can closely mirror that subject
- if there are multiple commits, summarize the branch instead of copying only the latest commit

Use a HEREDOC body:

```bash
gh pr create \
  --base main \
  --head <CURRENT_BRANCH> \
  --title "<title>" \
  --body "$(cat <<'EOF'
<body that follows the repository PR template>
EOF
)"
```

Before running it:

- ensure the branch is pushed
- ensure there is no existing open PR for the same head/base pair
- ensure the PR body reflects the repository template if one exists

Capture the resulting PR URL.

---

## Step 9 — Report back

Show the user:

- the PR URL
- the head branch and base branch
- whether a new commit was created, and the commit message if so
- a concise summary from `git diff --stat origin/main...HEAD`
- testing status, migration/database notes, and deployment concerns
- any risks or missing verification that reviewers should know

If anything fails, stop and report the exact blocker:

- merge conflict risk
- hook failure
- push rejection
- duplicate PR already exists
- no diff against `main`
