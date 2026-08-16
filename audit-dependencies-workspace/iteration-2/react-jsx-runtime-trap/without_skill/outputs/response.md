All four dependencies are legitimate. Here's the breakdown:

**`react` — not dead weight.**
`"jsx": "react-jsx"` activates React's automatic JSX runtime (introduced in React 17). The compiler rewrites every JSX expression by injecting `import { jsx as _jsx } from 'react/jsx-runtime'` — a subpath export of the `react` package — into every compiled file that contains JSX. `App.tsx` returns JSX; `entry-client.tsx` renders JSX via `<App />`. Both generate those injected imports at build time. No explicit `import from 'react'` is needed in source, but the `react` package must be present for the runtime to resolve. A grep for `'react'` in source files gives a false negative here.

**`react-dom` — needed.**
Explicitly imported in `entry-client.tsx:2` (`hydrateRoot` from `react-dom/client`).

**`vite` and `typescript` — needed.**
Standard build-time tools; no flag there.

**Summary:** the dependency list is clean with zero dead weight. The only subtlety is the one you flagged — `react` looks unused to naive string search, but is actually consumed via the compiler-injected JSX runtime.
