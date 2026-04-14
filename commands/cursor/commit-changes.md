---
name: commit-changes
description: >
  Create clean, intentional git commits with proper conventional commit messages
  and explicit file staging. Use when committing staged changes, writing commit
  messages, or preparing code for a pull request.
---

# commit-changes

You are a commit assistant. Follow these steps **in order** every time. The goal is to create a clean, intentional commit that is ready to support a pull request later.

If a repository-specific convention conflicts with this file, prefer the repository convention.

---

## Step 1 — Inspect the repository before changing anything

Run all of these before staging or committing:

```bash
git status --short
git diff
git diff --staged
git log -5 --oneline
```

Read the output carefully. You must understand:

- Which files are modified, untracked, deleted, renamed, or already staged
- Whether staged and unstaged changes belong to the same logical unit
- What the code changes actually do, not just which files changed
- What recent commit message style the repository already uses

If there are **no changes to commit**, stop and tell the user. Do not create an empty commit.

---

## Step 2 — Look for a pull request template

Before drafting the commit message, check whether the repository provides a PR template in `.github/`.

Look for these common locations:

```text
.github/pull_request_template.md
.github/PULL_REQUEST_TEMPLATE.md
.github/PULL_REQUEST_TEMPLATE/*.md
```

If a PR template exists:

- Read it before writing the commit message
- Treat it as the source of truth for the kind of context reviewers expect
- Reuse its categories when deciding what details belong in the commit body or your final summary

At minimum, extract and keep track of any sections about:

- Summary
- Type of change
- Related issues or tickets
- Testing
- Database or migration changes
- Deployment notes
- Breaking changes

Do **not** paste the whole PR template into the commit message. Instead, use it to shape the message and the final report back to the user.

---

## Step 3 — Identify what belongs in this commit

Before staging anything, review the working tree for risky or accidental files. **Ask the user before including** anything that looks suspicious or unrelated.

Always flag:

- `.env`, `.env.*`, credential files, tokens, private keys, or anything that looks secret
- Large binaries or generated artifacts such as `dist/`, `coverage/`, `build/`, `*.map`
- Lockfile-only changes with no corresponding dependency manifest change
- Formatting-only noise mixed into a logic change
- Unrelated files that do not belong to the same logical commit
- Deletions or renames that were likely accidental

Notes:

- `.env.example` may be safe to commit if it is clearly intended and contains no secrets
- Do not automatically unstage or revert user work you did not create
- If the intent is ambiguous, ask instead of guessing

---

## Step 4 — Stage files explicitly

**Never run `git add -A` or `git add .`** because they can include unintended files.

Stage only the files that belong in this commit:

```bash
git add <file1> <file2> ...
```

Examples:

```bash
git add src/users/user.service.ts src/users/dto/create-user.dto.ts
git add prisma/schema.prisma prisma/migrations/20260407_add_user_flags/
```

If some files are already staged but do **not** belong in the commit, unstage only those files carefully before continuing.

After staging, re-run:

```bash
git diff --staged
```

Do not commit until the staged diff matches one clear, reviewable change.

---

## Step 5 — Draft the commit message

Use Conventional Commits unless the repository clearly uses a different enforced style.

### Format

```text
<type>(<scope>): <short description>

[optional body]

[optional footer]
```

### Rules

**Type** — pick the best fit:

| Type       | Use when …                                      |
| ---------- | ----------------------------------------------- |
| `feat`     | adding a new feature                            |
| `fix`      | fixing a bug                                    |
| `refactor` | restructuring code without changing behaviour   |
| `perf`     | improving performance                           |
| `revert`   | reverting a previous commit                     |
| `docs`     | documentation only                              |
| `test`     | adding or updating tests                        |
| `chore`    | maintenance, config, tooling                    |
| `ci`       | CI/CD configuration                             |
| `build`    | build system or dependency pipeline changes     |
| `style`    | formatting or whitespace with zero logic change |

**Map PR template language to commit types when helpful:**

- Bug fix -> `fix`
- New feature -> `feat`
- Breaking change -> usually `feat!` or `fix!`
- Documentation update -> `docs`
- Refactoring -> `refactor`
- Performance improvement -> `perf`
- Test updates -> `test`

**Scope**:

- Optional but recommended
- Must be **kebab-case**
- Keep it specific: `auth`, `expenses`, `sentry-config`, `prisma`

**Subject**:

- Must not be empty
- Start lowercase
- Use an imperative, concise description
- Keep the first line at **100 characters or less**
- Do not end with a period

**Body**:

- Explain **why** or **impact**, not a file-by-file changelog
- Wrap lines at about 72 characters
- Include relevant reviewer context from the PR template when useful
- Mention testing when it materially helps future reviewers
- Mention database or migration implications if they exist

**Footer**:

- Use for issue references, tickets, or breaking changes when applicable
- Example: `Closes #123`
- Example: `Refs: TICKET-E883`
- Example: `BREAKING CHANGE: refresh tokens now require device binding`

### Examples

```text
feat(course-reviews): add average rating to course response
```

```text
fix(auth): prevent token refresh after account deletion

Reject refresh requests for deleted accounts so tokens cannot be
minted after an account is disabled.
```

```text
feat(payments)!: switch webhook verification to Stripe

Align payment processing with the new provider rollout and remove
legacy verification assumptions.

BREAKING CHANGE: legacy Flutterwave webhook signatures are no longer accepted
```

---

## Step 6 — Validate the message against the staged change

Before committing, sanity-check the message:

- Does the type match the actual change?
- Is the scope accurate?
- Does the body capture the important reviewer context?
- If a PR template exists, does the message/body reflect the relevant sections?
- If the change affects DB, tests, or deployment, is that clear somewhere?

If the staged diff contains multiple unrelated changes, stop and split the commit instead of forcing one message to cover everything.

---

## Step 7 — Commit safely

Prefer a HEREDOC so multi-line messages are preserved exactly:

```bash
git commit -m "$(cat <<'EOF'
<type>(<scope>): <subject>

<optional body>

<optional footer>
EOF
)"
```

Rules:

- Never append `Co-authored-by:`, AI attribution, or `Made-with: Cursor`
- Do not use `--no-verify` unless the user explicitly asks for it
- If hooks fail, inspect the failure, fix the issue, and retry with a new commit attempt

---

## Step 8 — Verify after commit

Run:

```bash
git status --short
```

If commitlint is available or the repository uses it, also run:

```bash
echo "<your message>" | npx commitlint
```

Confirm:

- The commit succeeded
- The working tree is in the expected state
- No unintended files were included

---

## Step 9 — Report back to the user

After the commit, give a concise summary that includes:

- The final commit message
- The commit hash
- Whether hooks or tests ran successfully
- Any important follow-up risks or manual steps

If a PR template was found, structure your summary using the most relevant template sections, such as:

- Summary
- Type of change
- Testing
- Database changes
- Deployment notes
- Related issues or tickets
