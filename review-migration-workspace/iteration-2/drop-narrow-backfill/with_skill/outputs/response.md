Now I'll analyze the migration following the skill's steps.

---

**Migration: (inline SQL — no filename)**

---

**Data-loss risks**

**1. [high] `ALTER TABLE payments ALTER COLUMN amount TYPE INTEGER` — `payments`**

The column comment makes the intent explicit: `amount` was `NUMERIC(10,2)` specifically to preserve cents-level precision. Casting to `INTEGER` silently truncates the fractional part on every existing row — `99.99` becomes `99`, `0.50` becomes `0`. This is permanent monetary data destruction. Postgres will attempt an implicit cast and succeed without error, so there is no safety net. Do not merge this until the desired representation is agreed upon: if the goal is integer cents, the correct type is `BIGINT` (storing 9999 to represent $99.99) and a data migration must multiply existing values by 100 before the type change, not truncate them.

**2. [high] `DROP TABLE legacy_sessions` — `legacy_sessions`**

All rows in `legacy_sessions` are permanently deleted with no rollback path. If active sessions are stored here, this could log out all users on deploy. Verify the table is truly unused (no app code references it, no foreign keys point to it) before running.

---

**Lock risks**

**1. [high] `ALTER TABLE payments ALTER COLUMN amount TYPE INTEGER` — `payments`**

Takes `ACCESS EXCLUSIVE` on `payments` and rewrites the entire table to convert every value. Duration is proportional to table size; on a large payments table this could mean minutes of full read+write downtime. There is no `CONCURRENTLY` equivalent for type changes. The only safe path is: add a new `amount_int BIGINT` column, backfill it in batches, swap the application to write to both columns, then drop the old column in a later migration — never in one step.

**2. [high] `DROP TABLE legacy_sessions` — `legacy_sessions`**

Takes `ACCESS EXCLUSIVE` on `legacy_sessions` for the duration of the drop. If the table is large, this can be slow and blocks any concurrent read or write hitting that table.

**3. [high] `UPDATE users SET status = 'active' WHERE status IS NULL` — `users`**

Takes `ROW EXCLUSIVE` (not `ACCESS EXCLUSIVE`), so it does not block unrelated reads. The real risk is that 40 million rows in a single transaction means: one very long-running transaction holding row locks on every matched row until commit, potentially gigabytes of WAL, severe table bloat, and replication lag that could delay replicas by many minutes. This must be batched — for example, updating 25,000–50,000 rows at a time in a loop outside a single transaction.

---

**Reversibility gaps**

**1. [high] No down migration exists for any destructive operation.**

- `DROP TABLE legacy_sessions`: unrecoverable without a backup taken before the migration runs.
- `ALTER TABLE payments ALTER COLUMN amount TYPE INTEGER`: even if you run `ALTER COLUMN amount TYPE NUMERIC(10,2)`, the truncated fractional data is gone — the reverse migration cannot restore it.
- `UPDATE users SET status = 'active' WHERE status IS NULL`: cannot be reversed without knowing which rows were `NULL` before the update. A `status IS NULL` predicate on rollback would set already-active users to `NULL`.

---

**Missing backfills**

No `ADD COLUMN NOT NULL` or new constraint without a preceding backfill — this category is clean.

---

**Missing indexes**

**1. [low] `actor_id` — `audit_logs`**

`actor_id` is not a declared foreign key and has no index. Any query filtering or joining on `actor_id` (e.g., "show all actions by user X") will do a full table scan as the audit log grows. Add:

```sql
CREATE INDEX CONCURRENTLY idx_audit_logs_actor_id ON audit_logs (actor_id);
```

Note: `CREATE INDEX CONCURRENTLY` cannot run inside a transaction block — split it into its own migration if your framework auto-wraps statements.

---

**Summary**

**Blocks deployment — do not run as-is.**

Three independent blockers:

1. **The `ALTER COLUMN amount TYPE INTEGER` silently destroys monetary precision data and must not be merged without a reviewed backfill-and-swap strategy.**
2. **The bulk `UPDATE users` on 40M rows must be batched** — running it as a single transaction risks replication lag, WAL bloat, and extended row-lock contention.
3. **No rollback path exists** for `DROP TABLE legacy_sessions` or the payments type change; at minimum, confirm a pre-migration backup exists and document that these steps are one-way.
