#!/bin/sh
# Builds a tiny git repo for the audit-secrets eval "leaked-aws-and-rsa-key".
#
# Scenario: a config file is committed once containing BOTH an AWS access
# key and a fake RSA private key block. A later commit removes the private
# key but leaves the AWS key in place. Padding commits sit either side so
# the sensitive commits are "several commits back", not HEAD~1.
#
# Result:
#   - AWS key:  present in the CURRENT working tree AND in git history
#   - RSA key:  present ONLY in git history (removed from the working tree)
#
# All secret values are well-known non-functional dummies:
#   - AKIAIOSFODNN7EXAMPLE is the canonical AWS documentation example key
#   - the RSA private key body is placeholder text, not real key material
#
# Usage: ./setup.sh [target-dir]
# Prints the path to the built repo on stdout. Only ever writes inside
# that target directory (created fresh if it doesn't exist).
set -eu

TARGET_DIR="${1:-$(mktemp -d)}"
mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR"

git init -q
git config user.name "Fixture Bot"
git config user.email "fixture-bot@example.com"

# --- commit 1: init ---
cat > README.md <<'EOF'
# acme-scratch

Internal scratch project used for local testing.
EOF
git add README.md
git commit -q -m "initial commit"

# --- commit 2: add credentials file containing BOTH secret types ---
mkdir -p config
cat > config/credentials.txt <<'EOF'
# Local dev credentials -- DO NOT COMMIT (oops)
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY

-----BEGIN RSA PRIVATE KEY-----
MIIFAKEKEYDATAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
-----END RSA PRIVATE KEY-----
EOF
git add config/credentials.txt
git commit -q -m "add local dev credentials"

# --- commit 3: unrelated padding commit ---
mkdir -p docs
cat > docs/notes.md <<'EOF'
# Notes

TODO: write onboarding doc.
EOF
git add docs/notes.md
git commit -q -m "add onboarding notes stub"

# --- commit 4: unrelated padding commit ---
cat >> README.md <<'EOF'

## Setup

Run `npm install`.
EOF
git add README.md
git commit -q -m "document setup step"

# --- commit 5: remove the private key, but leave the AWS key in place ---
cat > config/credentials.txt <<'EOF'
# Local dev credentials -- DO NOT COMMIT (oops)
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY

# private key moved to the team vault, no longer stored in this repo
EOF
git add config/credentials.txt
git commit -q -m "move private key out of repo (vault is now source of truth)"

# --- commit 6: final padding commit ---
cat > .gitignore <<'EOF'
node_modules/
EOF
git add .gitignore
git commit -q -m "add .gitignore"

echo "$TARGET_DIR"
