Here is the full audit result.

---

## Secrets Audit — `fixture-repo`

### Finding 1 — AWS credentials in current HEAD files (LIVE EXPOSURE)

**File:** `config/credentials.txt` (lines 2–3, currently on disk)

```
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

These were introduced in commit `8111aa3` ("add local dev credentials") and were **never removed** — they exist in the current working tree. Making the repo public exposes them immediately.

---

### Finding 2 — RSA private key in git history (HISTORICAL EXPOSURE)

**Commit:** `8111aa3` — diff of `config/credentials.txt`

```
-----BEGIN RSA PRIVATE KEY-----
MIIFAKEKEYDATAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
...
-----END RSA PRIVATE KEY-----
```

Commit `e2ce11b` ("move private key out of repo") deleted it from the working tree, but **the key is permanently stored in the git object database**. Any clone gets it via `git log -p`. The commit message "vault is now source of truth" suggests someone believed removing it from files was sufficient — it is not.

---

### Finding 3 — AWS credentials also in git history (HISTORICAL EXPOSURE)

The same AWS key pair from Finding 1 appears in commit `8111aa3`'s diff and in every subsequent commit's tree, because they were never removed from `config/credentials.txt`. The history exposure is redundant with Finding 1 here, but would persist even if the file were cleaned up without a history rewrite.

---

### Finding 4 — `config/credentials.txt` not in `.gitignore`

**File:** `.gitignore` only contains `node_modules/`. The credentials file was committed because nothing blocked it. Even after remediation, this remains a footgun.

---

## Required actions before going public

**1. Rotate credentials now.**
Treat `AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE` and the private key as compromised. Even if they are example/placeholder values here, real keys in a real repo must be rotated before anything else — history rewriting doesn't help if the key is already being used by an attacker.

**2. Rewrite git history to purge secrets from all objects.**
Use `git filter-repo` (preferred) or BFG Repo Cleaner:

```bash
# Install: pip install git-filter-repo
git filter-repo --path config/credentials.txt --invert-paths
# OR to keep the file but strip only the secret lines:
git filter-repo --replace-text <(printf 'AKIAIOSFODNN7EXAMPLE==>REDACTED\nwJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY==>REDACTED\n')
```

After this, the git object database is rewritten. Any existing clones or forks still hold the old history — coordinate to destroy them.

**3. Clean the working tree.**
Either delete `config/credentials.txt` entirely or replace the values with references to environment variables / vault paths.

**4. Add `config/credentials.txt` to `.gitignore`.**

```
node_modules/
config/credentials.txt
```

**5. Verify no other branches or tags carry the old objects.**

```bash
git for-each-ref --format='%(refname)' refs/
```

After `filter-repo`, all refs are rewritten, but double-check there are no stray tags or remote-tracking refs pointing into the old history.

---

### Summary table

| #   | Secret type                      | Where                                            | Status                       |
| --- | -------------------------------- | ------------------------------------------------ | ---------------------------- |
| 1   | AWS access key + secret          | `config/credentials.txt` HEAD                    | **Exposed in current files** |
| 2   | RSA private key                  | commit `8111aa3` diff                            | **Exposed in git history**   |
| 3   | AWS access key + secret          | commit `8111aa3` diff (and all subsequent trees) | **Exposed in git history**   |
| 4   | `credentials.txt` not gitignored | `.gitignore`                                     | **Structural gap**           |

**Do not make this repo public until steps 1–4 above are complete.** History rewriting is the critical blocker — removing files from HEAD without rewriting history leaves all secrets fully recoverable by anyone who clones.
