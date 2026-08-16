## Dependency Audit — acme-storefront @ 3.2.0

### 1. `pdf-stamp@2.1.0` — AGPL-3.0 license (HIGH, legal risk)

Used in `src/invoices/export.ts` (`exportInvoice`), a real production code path, not a dev tool. AGPL-3.0 is strong copyleft with a network-use clause — if acme-storefront (a storefront, i.e. a network service) links this in, it can obligate you to release the full application source under AGPL. This is very likely incompatible with a proprietary commercial product and is the kind of thing that gets caught in a legal review, not `npm audit`.
**Action:** flag to legal/eng leadership before next release. The call site is narrow (one function), so swapping to an MIT-licensed alternative (`pdf-lib`, `pdfkit`) is a contained change.

### 2. `lodash@4.17.15` — CVE-2020-8203 Prototype Pollution (HIGH, security)

Patched in `>=4.17.19`, you're on 4.17.15. Not just a paper CVE here: `src/utils/format.ts` calls `lodash/merge` directly (`mergeDefaults`), and `merge` is one of the functions in lodash's prototype-pollution class. If `mergeDefaults` is ever called with attacker-influenced input (e.g. request-derived config), this is exploitable — worth checking callers.
**Action:** bump to `^4.17.21` (picks up this fix plus later ones, e.g. CVE-2020-28500). No API change for `merge`.

### 3. `moment@2.24.0` — unused (MEDIUM, hygiene)

No file in the repo references it. Moment is also in upstream maintenance mode (team steers new code to `day.js`/`date-fns`/`Temporal`), and 2.24.0 predates the ReDoS fix in 2.29.4 (CVE-2022-31129) — moot while unused, but it's dead weight either way.
**Action:** remove from `package.json`.

### 4. `tailwindcss@3.4.1` (LOW, hygiene)

Actively used, no known CVE. It's a build-time-only tool but lives in `dependencies` instead of `devDependencies` — doesn't hurt runtime security, just bloats prod installs slightly. Not urgent.

### `jest@29.7.0`

Current, devDependency, no action needed.

---

**Priority order:** pdf-stamp license review, lodash bump, drop moment, (optional) move tailwindcss to devDependencies.

Skipped: pdf-stamp's own CVE history — the npm audit excerpt didn't cover it; say the word if you want that pulled too.
