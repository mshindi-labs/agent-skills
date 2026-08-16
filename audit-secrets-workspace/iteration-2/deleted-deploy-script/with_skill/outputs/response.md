## Secrets Audit Report

**Scope:** `scripts/deploy.sh` (git history) + `scripts/README.md` (current working tree)

---

### Finding 1 — HIGH severity

| Field                        | Detail                                                               |
| ---------------------------- | -------------------------------------------------------------------- |
| **Pattern category**         | GitHub personal access token (`ghp_` prefix)                         |
| **Masked value**             | `ghp_****Yz12`                                                       |
| **Location**                 | `scripts/deploy.sh` (deleted file, **still present in git history**) |
| **Introduced**               | Commit `111aaa22` by Tom Okafor, 2026-01-12                          |
| **Removed**                  | Commit `222bbb33` (file deleted), 2026-02-05                         |
| **In current working tree?** | No — file deleted                                                    |
| **In git history?**          | **Yes** — both commits contain the value                             |

Deleting the file does not purge the secret from git history. Anyone who clones this repo — or has already cloned it — can recover the token with `git log -p`.

---

### `scripts/README.md` — Clean

Contains only the placeholder string `GITHUB_TOKEN=your-token-here`. This is not a credential.

---

### Remediation (required before pushing)

**Do this now — assume the token is already compromised:**

1. **Rotate immediately:** Go to GitHub → Settings → Developer settings → Personal access tokens and revoke the exposed token. Issue a new one and store it in a secrets manager or CI environment variable, never in source.

2. **Purge from history:**

   ```sh
   git filter-repo --path scripts/deploy.sh --invert-paths
   ```

   This rewrites history to remove the file entirely from all commits.

3. **Force-push all remotes** after purging (coordinate with the team — this is a destructive rewrite):

   ```sh
   git push --force --all
   git push --force --tags
   ```

4. **Ask collaborators** to re-clone or rebase onto the rewritten history. Any existing clone still contains the secret.

> Do not use `git rebase -i` or `git commit --amend` — they leave reflog traces and do not fully purge the secret.

**Do not push this repo in its current state.**
