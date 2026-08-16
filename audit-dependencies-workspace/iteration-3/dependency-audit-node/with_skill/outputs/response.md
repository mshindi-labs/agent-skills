```text
Dependency audit report
──────────────────────────────────────────────────

Security vulnerabilities (1)
1. [high] lodash@4.17.15 — CVE-2020-8203
   Prototype Pollution via lodash/merge, allowing attackers to modify
   Object.prototype through crafted input.
   Fix: upgrade to >=4.17.19 — run: npm install lodash@4.17.21
   Scope: production dependency

Note: the audit output provided is an excerpt. No advisory data is available
for pdf-stamp, tailwindcss, moment, or jest from the supplied output — this
does not mean those packages are clean. Run `npm audit --json` in full to
confirm coverage.

Significantly outdated (1)
1. moment@2.24.0 → latest 2.30.x (same major, but Moment.js is officially
   in maintenance-only / legacy mode — the maintainers recommend migrating
   to date-fns or Luxon; no new features will be added and security fixes
   are no longer guaranteed)
   Upgrade effort: significant (migration to a replacement library, not a
   version bump)
   Note: moment is also unused (see below), so removal is the right action.

License risks (1)
1. pdf-stamp@2.1.0 — AGPL-3.0 (direct production dependency)
   Risk: AGPL-3.0 requires releasing your application's source code if the
   software is distributed or accessed over a network — SaaS use counts.
   This is the most commonly flagged license in commercial software audits.
   Action: get legal review immediately; if AGPL is not acceptable, replace
   pdf-stamp with a permissively-licensed alternative (e.g. pdf-lib, pdfkit)
   or implement stamping in-house.

Unused production dependencies (1)
1. moment@2.24.0 — no imports found in any source file across the repo
   Action: remove from dependencies — run: npm uninstall moment

──────────────────────────────────────────────────
Summary
  Security: 0 critical, 1 high, 0 moderate (from provided excerpt only)
  Stale:    1 package flagged (moment — deprecated/legacy)
  Licenses: 1 flagged for review (pdf-stamp AGPL-3.0)
  Unused:   1 candidate for removal (moment)

Recommended immediate actions
  1. Legal review on pdf-stamp — the AGPL-3.0 exposure is the highest
     business risk in this manifest; block on a legal decision before the
     next release.
  2. Upgrade lodash to patch the known CVE:
       npm install lodash@4.17.21
  3. Remove the unused, deprecated moment package:
       npm uninstall moment
  4. Run a complete audit to cover the full dependency tree:
       npm audit --json
```
