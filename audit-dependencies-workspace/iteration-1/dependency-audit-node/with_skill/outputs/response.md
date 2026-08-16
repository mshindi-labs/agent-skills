Ran the audit using the data you provided (registry lookups weren't available in this sandbox, so the tailwindcss/moment staleness read is from known public release history, not a live `npm outdated` — worth confirming with a real run).

```
Dependency audit report
──────────────────────────────────────────────────

Security vulnerabilities (1)
1. [high] lodash@4.17.15 — CVE-2020-8203
   Prototype pollution via zipObjectDeep/merge-family functions lets attacker-controlled
   input taint Object.prototype.
   Fix: upgrade to >=4.17.19 (latest 4.x is 4.17.21) — run: npm install lodash@4.17.21
   Production dependency, used at src/utils/format.ts:1 (lodash/merge).

Significantly outdated (1)
1. tailwindcss: installed 3.4.1 → latest major v4
   Upgrade effort: moderate (one major version, but v4 rewrote the engine and moved
   config from tailwind.config.js to CSS-first `@theme` — not a drop-in bump)
   Action: read the v3→v4 migration guide before touching postcss.config.js

License risks (1)
1. pdf-stamp@2.1.0 — AGPL-3.0 (direct production dependency)
   Risk: strong copyleft + network-use clause — running this in a SaaS storefront can
   trigger an obligation to release acme-storefront's own source.
   Action: get legal review before next release. Usage is isolated to one call site
   (src/invoices/export.ts:1, stampPdf), so swapping to an MIT/Apache alternative
   (e.g. pdf-lib) is a small, contained change if legal says no.

Unused production dependencies (1)
1. moment@2.24.0 — no imports found anywhere in the repo (checked all given files;
   zero matches)
   Action: npm uninstall moment. This also makes the tailwindcss-style "should we
   upgrade this" question moot for moment — moment has been in maintenance-only mode
   since 2020 with no v3 planned, so deleting it beats upgrading it.

Summary
  Security: 0 critical, 1 high, 0 moderate
  Stale:    1 package significantly behind (tailwindcss)
  Licenses: 1 flagged (pdf-stamp, AGPL-3.0)
  Unused:   1 candidate for removal (moment)

Recommended immediate actions
  1. npm install lodash@4.17.21 — closes CVE-2020-8203 (high), trivial patch bump
  2. npm uninstall moment — dead weight, zero call sites
  3. Get legal sign-off on pdf-stamp's AGPL-3.0 before next ship; have pdf-lib ready as fallback
  4. Schedule the tailwindcss v3→v4 migration separately — not urgent, but budget time for config rewrite
```

lodash and tailwindcss are both genuinely used (verified via the grep results, not just substring match) → not flagged as unused. jest wasn't assessed for staleness — no reliable version data for it here, and it's dev-only, low priority.
