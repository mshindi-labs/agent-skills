Two issues here, both worth blocking on:

---

**`src/routes/reports.ts` — crash on null**

The comment directly above the function states that `fetchForUser` resolves to `null` when the user has no reports. The removed null guard was the only thing preventing `reports.map(...)` from throwing `TypeError: Cannot read properties of null (reading 'map')` for those users.

This will crash at runtime for any user with no reports on record.

---

**`src/middleware/authGuard.ts` — unauthenticated GET access**

Changing the condition to `&& req.method !== 'GET'` makes `requireAuth` silently pass all GET requests without a token. The middleware is named `requireAuth` and is presumably applied to protected routes — this change makes every GET endpoint on those routes publicly accessible.

If the intent is to make certain routes public, the right fix is to not apply `requireAuth` to those routes (or use a separate `optionalAuth` middleware), not to punch a hole in the guard based on HTTP method.

Both changes should be reverted or reworked before merging.
