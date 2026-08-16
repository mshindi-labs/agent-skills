**1. [high] Auth guard no longer protects GET requests — `src/middleware/authGuard.ts`**
`requireAuth` now skips the check entirely when `req.method === 'GET'`. Since this is a shared middleware, this doesn't just relax one endpoint — it silently removes authentication from every GET route that relies on `requireAuth`, wherever it's mounted. Any route serving user-specific or sensitive data via GET (profiles, reports, admin views, etc.) becomes publicly accessible without a token. If the intent was to make one specific read endpoint public, that should be an explicit allow-list on that route, not a blanket exemption in the shared guard.

**2. [high] Null reports response now crashes instead of returning empty — `src/routes/reports.ts`**
The comment directly above the function still says `externalReportsClient.fetchForUser` resolves to `null` when the user has no reports — but the `if (!reports) return []` guard that handled that case was deleted. Any user with no reports on record will now hit `reports.map(...)` on `null` and throw a `TypeError`, turning a normal "no reports yet" case into a 500. This is a regression against the function's own documented contract, not a cleanup.

Open questions / residual risk:

- No tests were touched in this diff — neither change has a regression test, so both would ship silently.
- Worth double-checking: was the GET exemption meant to apply narrowly (e.g. one public route) rather than in the shared `requireAuth` middleware?
