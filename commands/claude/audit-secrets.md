---
description: Scan the working tree and recent git history for accidentally committed secrets, tokens, and credentials before they leave the machine. Use before any push or PR.
allowed-tools: Read Grep Glob Bash(git log) Bash(git diff)
---

# audit-secrets

You are a secrets detection assistant. Your job is to find credentials, tokens, and sensitive values before they reach a remote repository. Be thorough and systematic. Never print full secret values in your report — always truncate or mask them.

---

## Step 1 — Define the scan scope

Determine what to scan:

- if `$ARGUMENTS` specifies a path or file, scope the scan there
- otherwise scan the full working tree plus recent git history

Establish:

- project root
- whether there is a `.gitignore` to reference
- whether there is a `.env.example` to use as a reference for expected variable names

---

## Step 2 — Scan the working tree for secret patterns

Search all tracked and untracked non-binary files for the following pattern categories:

**High-severity patterns (confirmed credential shapes):**

- Private key blocks: `-----BEGIN (RSA|EC|DSA|OPENSSH|PGP) PRIVATE KEY`
- JWT tokens: three base64 segments separated by dots starting with `eyJ`
- AWS credentials: `AKIA[0-9A-Z]{16}`, `aws_secret_access_key`
- GitHub tokens: `gh[pousr]_[A-Za-z0-9]{36,}`
- Stripe keys: `sk_live_`, `pk_live_`, `rk_live_`
- Twilio: `SK[0-9a-fA-F]{32}`
- Generic API key patterns in assignments: `api_key\s*=\s*["'][^"']{16,}["']`
- Database connection strings containing passwords: `://[^:]+:[^@]{6,}@`
- Bearer tokens in source code: `Bearer [A-Za-z0-9\-._~+/]{20,}`

**Medium-severity patterns (high-entropy strings):**

- Strings of 32+ characters that are all hex: `[0-9a-fA-F]{32,}`
- Base64 strings of 40+ characters assigned to a variable with a sensitive-sounding name
- Strings matching password/secret/token/key variable assignments with non-placeholder values

**Low-severity patterns (suspicious names worth reviewing):**

- Variable names containing `password`, `passwd`, `secret`, `token`, `credential`, `private_key`, `auth_key` assigned to non-empty string literals
- Hard-coded localhost credentials with non-default passwords

Exclude:

- `.git/` directory
- `node_modules/`, `vendor/`, `.venv/`, `dist/`, `build/`
- Binary files, image files, compiled artifacts
- Test fixture files that clearly contain dummy data (e.g., files named `*.fixture.*`, `*.mock.*`, `*test*`) — flag these separately at lower confidence

---

## Step 3 — Scan recent git history

Check the last 20 commits for the same patterns:

```bash
git log -p --all --since="90 days ago" -20 -- . | grep -E "(password|secret|token|api_key|private_key|AKIA|sk_live|gh[pousr]_)"
```

For any match found in history:

- record the commit SHA, author, date, and file path
- note whether the secret is still present in the current working tree or was removed in a later commit
- if the secret was introduced and then removed, it is still in git history and needs to be rotated and purged

---

## Step 4 — Inspect `.gitignore` coverage

Compare files that appear to contain secrets against `.gitignore`:

- identify any `.env*`, `*.pem`, `*.key`, `secrets.*`, `config/local.*`, or credential files that are tracked but should be ignored
- identify variable-containing files that are committed and not in `.gitignore`
- flag `.env.example` as safe if it exists and contains only placeholder values (no real credentials)

---

## Step 5 — Rank and report findings

Classify each finding:

| Severity   | Criteria                                                        |
| ---------- | --------------------------------------------------------------- |
| **High**   | Confirmed credential pattern or private key block               |
| **Medium** | High-entropy string with a sensitive variable name              |
| **Low**    | Suspicious variable name with a plausible but unconfirmed value |

For each finding, report:

- severity
- file path and line number
- pattern category (e.g., "AWS access key", "JWT", "database password")
- masked value (show only first 4 + last 4 characters, e.g., `AKIA****ABCD`)
- whether it exists in current working tree, git history, or both
- recommended remediation (see Step 6)

If no findings exist, say so explicitly.

---

## Step 6 — Recommend remediation

For each confirmed finding:

**If the secret is only in the working tree (not yet committed):**

- Add the file to `.gitignore`
- Remove or replace the value with an environment variable reference
- Do not commit the file

**If the secret is in committed history:**

- Rotate the credential immediately — assume it is compromised
- Remove it from history using `git filter-repo --path <file> --invert-paths` or BFG Repo Cleaner
- Force-push to all remotes after purging (requires team coordination)
- Revoke and re-issue the credential with the relevant service

**If the secret is in a file that should be gitignored:**

- Add the pattern to `.gitignore`
- Run `git rm --cached <file>` to untrack without deleting locally
- Commit the `.gitignore` change

Never recommend `git rebase -i` or `git commit --amend` as a history-rewriting strategy for secrets — they leave reflog traces. Always recommend `git filter-repo`.
