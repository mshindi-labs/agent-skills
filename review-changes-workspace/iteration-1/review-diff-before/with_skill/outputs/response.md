These files aren't in this repo, so I'm reviewing the diff as given — it's the complete context.

1. **[high] Auth bypass for unauthenticated GET requests** — `src/middleware/authGuard.ts`
   The guard now skips the 401 check entirely when `req.method === 'GET'`, regardless of whether an `authorization` header is present. Any route mounted behind `requireAuth` that responds to GET is now reachable with zero credentials. If this guards anything beyond `reports.ts` (profile data, admin views, internal APIs), all of it is now open to unauthenticated read access. This reads like an attempt to allow public GET access to a specific route, but it's applied globally in shared middleware — every caller is affected, not just the intended one.

2. **[high] Null-report crash reintroduced** — `src/routes/reports.ts`
   The guard was removed but the comment directly above the function (`fetchForUser resolves to 'null' when the user has no reports on record`) still documents that `null` is a valid return value — and the comment wasn't updated either. Any user with zero reports now hits `reports.map` on `null` and throws a `TypeError`, turning what should be an empty list into a 500. This is a very common case (any new user), not an edge case.

Both changes look like they came from the same intent — "GET requests for users with no data shouldn't require auth / shouldn't 404" — but each was implemented by deleting a guard rather than narrowing it, which breaks the general case instead of fixing the specific one.

## Open questions

- Is the GET-bypass intentional for a specific public endpoint? If so it belongs on that route, not in shared `requireAuth`.
- What's actually supposed to happen when a user has no reports — was `[]` the wrong behavior, or was this guard removed by accident (e.g. bad rebase)?

## Testing

No test changes accompany either fix. Given both are behavior-inverting changes (auth bypass, null-handling removal), I'd want at minimum: a test hitting `requireAuth` with a GET + no auth header (expect 401), and a test for `getReportSummaries` when `fetchForUser` resolves `null` (expect `[]`, not a throw).
