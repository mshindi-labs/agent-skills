**No, this repo is not safe to make public.** The current file is clean, but the git history permanently records the raw credentials. Anyone who clones the repo gets the full history.

---

## Audit Report — `config/settings.py`

### Step 1 — Scope

Scan covers the current working tree (as provided) and the full `git log -p` for `config/settings.py`. No `.gitignore` or `.env.example` provided.

---

### Step 2 — Working Tree

**Clean.** Both values are now read from `os.environ`. No hardcoded secrets in the current working tree.

---

### Step 3 — Git History

Two high-severity secrets found in history:

| #   | Severity | Pattern Category                                               | Masked Value   | Commit                 | Still in working tree?    |
| --- | -------- | -------------------------------------------------------------- | -------------- | ---------------------- | ------------------------- |
| 1   | **High** | Stripe live secret key (`sk_live_`)                            | `sk_l****NOPQ` | `abc1234` — Jan 7 2026 | No (removed in `def5678`) |
| 2   | **High** | Database connection string with password (`://user:pass@host`) | `post****prod` | `abc1234` — Jan 7 2026 | No (removed in `def5678`) |

Both were introduced in `abc1234` ("settings: add Stripe and database config") and removed in `def5678` ("settings: read Stripe key and DB url from environment"). **Removal does not erase history** — the credentials are permanently encoded in the `abc1234` diff and will be visible to anyone who clones the repo.

---

### Step 4 — .gitignore

Not applicable — the file in question (`config/settings.py`) is a source file that should be tracked. The risk is the historical content, not whether it's gitignored.

---

### Step 6 — Required Remediation

**Both credentials must be treated as compromised immediately.**

**1. Rotate right now (before anything else):**

- **Stripe key** (`sk_l****NOPQ`): Go to the Stripe dashboard → Developers → API keys → roll the key. The old key is live and usable by anyone with repo access until rotated.
- **Database password** (`post****prod`): Change the password for the `admin` user on `db.internal.acme.dev`. The hostname, port, database name, and username are also now public.

**2. Purge from git history:**

```bash
git filter-repo --path config/settings.py --invert-paths
```

Or, to rewrite only the affected file while keeping it tracked:

```bash
git filter-repo --path config/settings.py --force \
  --commit-callback 'if b"sk_live_" in commit.file_changes[0].blob_id: ...'
```

The safer approach is to use `git filter-repo` with `--replace-text` to scrub the literal values from all blob content, then force-push every branch and tag.

**3. Force-push and coordinate with the team:**

- Notify all collaborators to `git fetch --all` and reset their local branches — any local clone still has the old history.
- Invalidate any forks or mirrors that may have already pulled.

**Do not use `git rebase -i` or `git commit --amend`** — they leave reflog traces and do not rewrite history across all branches.

---

**Bottom line:** Making this repo public right now would expose a live Stripe secret key and a production database password. Rotate both credentials first, then purge history with `git filter-repo`, then verify the rewrite is complete before publishing.
