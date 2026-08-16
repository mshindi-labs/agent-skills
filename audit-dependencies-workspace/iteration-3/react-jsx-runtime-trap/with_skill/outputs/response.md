**Direct answer to your specific concern: `react` is not dead weight** — it is actively required, just invisibly.

`tsconfig.json` sets `"jsx": "react-jsx"`, which is the automatic JSX transform. TypeScript emits calls to `react/jsx-runtime` (not `React.createElement`) for every JSX expression — `<App />`, `<main>`, `<h1>` — without any literal `import ... from 'react'` in the source. A grep for the string `'react'` will only find `'react-dom'` imports and falsely conclude `react` is unused. It isn't.

---

```
Dependency audit report — acme-dashboard
──────────────────────────────────────────────────

Security vulnerabilities
  Scan did not run — no lockfile was provided and npm audit could not be
  executed against this project. No vulnerability claims can be made.
  Action: run `npm audit` before shipping.

Significantly outdated (2)
  Note: versions below reflect my August 2025 knowledge cutoff. Current date
  is August 2026 — run `npm outdated` to see actual latest versions.

  1. react: installed 18.2.0 → latest 19.x (as of Aug 2025; may be 20+ now)
     Upgrade effort: moderate to significant (React 19 has breaking changes
     in refs, actions, and server component APIs)
     Action: review the React 19 upgrade guide before bumping

  2. react-dom: installed 18.2.0 → same trajectory as react (must move in lockstep)
     Action: upgrade together with react

  3. vite: installed 5.1.4 → latest 6.x (as of Aug 2025; may be 7+ now)
     Upgrade effort: moderate (Vite 6 dropped Node 18 support and changed
     some plugin API defaults)
     Action: check vite 6 migration guide; upgrade is low-risk for a simple
     SSR entry like this one

  typescript 5.4.2 — same major series as of Aug 2025; not significantly stale

License risks (0)
  react, react-dom — MIT
  vite — MIT
  typescript — Apache-2.0
  No restrictive licenses found.

Unused production dependencies (0)
  react — used implicitly: "jsx": "react-jsx" causes the compiler to emit
    react/jsx-runtime calls for every JSX expression in App.tsx and
    entry-client.tsx. No literal 'react' import is expected or needed.
  react-dom — explicitly imported in src/entry-client.tsx (hydrateRoot)

Summary
  Security: scan did not run — run npm audit before shipping
  Stale:    2 packages 1+ major versions behind (react, react-dom, vite)
  Licenses: 0 flagged
  Unused:   0

Recommended immediate actions
  1. Run `npm audit` — no security claims can be made without it
  2. Upgrade react + react-dom to 19.x together (check actual latest first
     with `npm outdated`, since this may now be 20.x)
  3. Upgrade vite to latest 6.x (or 7.x if released) — lowest-risk upgrade
     of the three
```
