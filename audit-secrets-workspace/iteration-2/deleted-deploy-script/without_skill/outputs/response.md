**Yes, there's a leaked credential — do not push yet.**

The token `ghp_1A2B3C4D5E6F7G8H9I0JklMnOpQrStUvWxYz12` is a GitHub personal access token that was hardcoded into `scripts/deploy.sh` in commit `111aaa22`. The file was deleted in the next commit, but **deletion does not remove it from git history** — it will be fully visible to anyone with repo access via `git log -p`.

The current `scripts/README.md` is fine; it only contains the placeholder `your-token-here`.

**What to do:**

1. **Revoke the token immediately** in GitHub Settings → Developer settings → Personal access tokens, regardless of whether you think it's still active. Assume it's compromised.

2. **Rewrite history** to remove the secret before pushing. The standard tool is [`git-filter-repo`](https://github.com/newren/git-filter-repo):

   ```sh
   git filter-repo --path scripts/deploy.sh --invert-paths
   ```

   Or to scrub just the string while keeping file history:

   ```sh
   git filter-repo --replace-text <(echo 'ghp_1A2B3C4D5E6F7G8H9I0JklMnOpQrStUvWxYz12==>REDACTED')
   ```

3. After rewriting, you'll need to force-push (`git push --force`), which rewrites the remote history — coordinate with any collaborators first.

If this repo has _already_ been pushed anywhere (even briefly), treat the token as fully exposed and rotate it regardless of the history rewrite.
