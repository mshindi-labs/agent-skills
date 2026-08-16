Two high-severity issues in this diff — reviewing them now.

---

1. **[high] Null dereference crash for users with no reports — `src/routes/reports.ts`**

   The comment directly above the changed code states:

   > `externalReportsClient.fetchForUser` resolves to `null` when the user has no reports on record

   The removed guard was the only thing preventing `null.map(...)`. With it gone, any user who has no reports causes an unhandled `TypeError` and a 500. The client contract hasn't changed — `null` is still a valid return value. This will crash in production for a predictable subset of real users.

   **Triggering scenario:** `fetchForUser` returns `null` → `reports.map(...)` throws → request fails with a 500.

2. **[high] Auth bypass for all GET requests — `src/middleware/authGuard.ts`**

   The new condition `&& req.method !== 'GET'` means unauthenticated GET requests are let through without a 401. Every route using `requireAuth` that responds to GET now serves data to anonymous callers. This isn't a narrow opt-out — it silently disables auth for the entire GET surface that `requireAuth` covers.

   **Triggering scenario:** Any unauthenticated client issues a GET request to a protected endpoint → `next()` is called → protected data is returned without identity verification.

   This change needs a dedicated auth review (`review-auth`) before it ships. The concrete risk is full read-access bypass on every protected GET route.

---

**Open questions:**

- Was the null guard removed because the API contract changed (i.e., the client now always returns an array)? If so, the comment and tests need updating. If not, this is a straight regression.
- What's the intended motivation for exempting GET from auth? If it's for health checks or public endpoints, those should be carved out individually rather than removing auth globally for the HTTP method.
