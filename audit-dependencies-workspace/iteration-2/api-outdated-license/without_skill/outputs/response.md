Here's the full audit across four dimensions: version drift, placement, license, and production hygiene.

---

## 1. acme-http-client — Outdated, upgrade risk HIGH

| Field         | Value |
| ------------- | ----- |
| Installed     | 2.1.0 |
| Latest        | 5.0.0 |
| Majors behind | 3     |

Two confirmed breaking-change boundaries between current and latest:

- **v3**: auth rewrite — `HttpClient` instantiation/config API likely changed.
- **v5**: callback API dropped — any callback-style usage will break silently at compile time or loudly at runtime.

`src/index.ts` imports `HttpClient` directly, so this upgrade requires a migration, not just a version bump. Recommended path: upgrade to v3 first, fix auth, then upgrade to v5, remove callbacks. Do not jump directly to v5 without intermediate testing.

---

## 2. supertest — Wrong dependency group

`supertest` is listed under `dependencies` but is only imported in `tests/api.test.ts`. It has no import in any source file.

**Move it to `devDependencies`.** Leaving test-only packages in `dependencies` inflates production installs and increases attack surface unnecessarily.

```json
"devDependencies": {
  "jest": "29.7.0",
  "supertest": "6.3.3"
}
```

---

## 3. ts-node — Production hygiene concern

`ts-node` is in `dependencies` and is invoked by the `start` script (`ts-node src/index.ts`). It is never imported as a module.

Running TypeScript source directly via ts-node in production is inadvisable:

- Compiles on every startup (slower boot, higher memory).
- Ships TypeScript source and the full ts-node/TypeScript toolchain to production.

**Recommendation:** Add a build step (`tsc`), output to `dist/`, and change the start script to `node dist/index.js`. Then move `ts-node` to `devDependencies`. If you cannot add a build step right now, at minimum document the intent — but this is a production hygiene debt item.

---

## 4. geo-lookup — License flag

`geo-lookup@1.8.0` is licensed under **LGPL-2.1**.

LGPL-2.1 permits use in proprietary software but requires that the LGPL-covered library remain replaceable by the user. For a server-side API that is never distributed as a binary, this is typically not a problem in practice — but it should be reviewed by legal/compliance before it's considered cleared, especially if:

- The service is ever packaged and sold/distributed (e.g., on-prem deployment).
- Company policy requires permissive-only licenses (MIT/Apache-2.0).

No action is technically required for a typical SaaS deployment, but the license should be recorded in your dependency inventory.

---

## Summary table

| Package          | Issue                                    | Severity           | Action                                          |
| ---------------- | ---------------------------------------- | ------------------ | ----------------------------------------------- |
| acme-http-client | 3 majors behind, two breaking boundaries | High               | Phased upgrade: v2→v3→v5                        |
| supertest        | In `dependencies`, only used in tests    | Medium             | Move to `devDependencies`                       |
| ts-node          | Running TS source in production          | Medium             | Add build step; move to `devDependencies`       |
| geo-lookup       | LGPL-2.1 license                         | Low (legal review) | Record in license inventory; confirm with legal |
| jest             | Correctly placed, not outdated           | —                  | No action                                       |
