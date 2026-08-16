Here's the dependency audit for `acme-storefront`:

---

## Dependency Audit — acme-storefront@3.2.0

### 1. Security — `lodash@4.17.15` (HIGH)

**CVE-2020-8203** — Prototype Pollution via `merge`, `mergeWith`, `defaultsDeep`.

`src/utils/format.ts` calls `lodash/merge` directly, which is one of the affected APIs. Malicious input in `b` could pollute `Object.prototype`.

**Fix:** Upgrade to `4.17.21` (latest patch, fixes this and all intermediate issues).

```
npm install lodash@4.17.21
```

---

### 2. License Risk — `pdf-stamp@2.1.0` (AGPL-3.0)

AGPL-3.0 is a strong copyleft license. Using an AGPL library in a commercial product typically requires either releasing your entire application's source under AGPL or obtaining a commercial license from the upstream author. For a storefront, this is likely unacceptable.

`src/invoices/export.ts` is the only consumer.

**Action:** Audit whether a commercial license is available from the `pdf-stamp` maintainer, or replace it with a permissively licensed alternative (MIT/Apache-2.0). If no acceptable option exists, the stamping logic may need to be implemented in-house.

---

### 3. Unused Dependency — `moment@2.24.0`

No file in the repo imports `moment`. It is dead weight in the bundle and `2.24.0` is a very old release that predates several security fixes (ReDoS, path traversal) patched in later versions.

**Fix:** Remove it.

```
npm uninstall moment
```

---

### 4. Miscategorized Dependency — `tailwindcss@3.4.1`

`tailwindcss` is listed under `dependencies` (runtime) but it is a build-time tool only, referenced exclusively in `postcss.config.js`. Shipping it as a production dependency bloats deployment artifacts and may trigger unnecessary security scans on servers.

**Fix:** Move it to `devDependencies`.

```
npm install --save-dev tailwindcss@3.4.1
npm uninstall tailwindcss   # removes from dependencies
```

---

### 5. No Issues — `jest@29.7.0`

No known vulnerabilities, correctly placed in `devDependencies`.

---

### Summary

| Package             | Severity     | Issue                             | Action                               |
| ------------------- | ------------ | --------------------------------- | ------------------------------------ |
| `lodash@4.17.15`    | High         | CVE-2020-8203 prototype pollution | Upgrade to `4.17.21`                 |
| `pdf-stamp@2.1.0`   | High (legal) | AGPL-3.0 copyleft risk            | Replace or obtain commercial license |
| `moment@2.24.0`     | Medium       | Unused + outdated                 | Remove                               |
| `tailwindcss@3.4.1` | Low          | Wrong dependency category         | Move to `devDependencies`            |
| `jest@29.7.0`       | None         | —                                 | No action needed                     |
