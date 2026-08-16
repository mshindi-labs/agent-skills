Here is the migration review following the skill's framework.

---

```
Migration: (inline, no filename provided)

Data-loss risks
1. [high] ALTER TABLE payments ALTER COLUMN amount TYPE INTEGER — payments
   NUMERIC(10,2) stores cent-precision values (e.g., 9.99, 10.50). Postgres
   casts NUMERIC → INTEGER by rounding, so 9.99 → 10 and 10.50 → 11. The
   original cent values are permanently destroyed — there is no way to recover
   whether 10 came from 10.00, 9.99, or 10.49. The column comment confirms it
   previously held intentional sub-dollar precision, making this a financial
   data integrity issue. Do not run this statement without first verifying that
   every stored amount is already a whole number:

     SELECT COUNT(*) FROM payments WHERE amount != FLOOR(amount);

   If any rows exist, the type change must be preceded by an explicit,
   audited conversion step.

2. [high] DROP TABLE legacy_sessions — legacy_sessions
   Permanently deletes all rows and the table structure. There is no down
   migration, so this is irreversible without a database backup. Verify the
   table is genuinely unused (no application references, no FK dependencies)
   before proceeding.

Lock risks
1. [high] ALTER TABLE payments ALTER COLUMN amount TYPE INTEGER — payments
   Takes ACCESS EXCLUSIVE on the payments table for the full duration of a
   table rewrite — every row must be read and rewritten with the new type.
   This blocks all reads and writes to payments until the rewrite completes.
   On a large payments table this could run for minutes. There is no
   lock-safe alternative for a type change that requires a rewrite; this
   requires a maintenance window or a shadow-table approach.

2. [high] UPDATE users SET status = 'active' WHERE status IS NULL — users
   Takes ROW EXCLUSIVE (not ACCESS EXCLUSIVE), so concurrent readers and
   writers of unrelated rows are not blocked. The risk is different: on a
   40-million-row table, an unbatched UPDATE runs as a single transaction
   that holds row locks on every matched row until commit, generates massive
   WAL volume, causes replication lag, and leaves significant table bloat
   after the transaction completes. Batch this instead:

     UPDATE users SET status = 'active'
     WHERE id IN (
       SELECT id FROM users WHERE status IS NULL LIMIT 10000
     );
   -- repeat until 0 rows affected

Reversibility gaps
1. [high] DROP TABLE legacy_sessions — no down migration defined
   Without a rollback, any deployment incident that requires reverting this
   migration loses all legacy_sessions data permanently.

2. [high] ALTER TABLE payments ALTER COLUMN amount TYPE INTEGER — no down migration
   Reverting to NUMERIC(10,2) with ALTER COLUMN TYPE does not restore the
   rounded-away decimal values. The data loss is irreversible once this runs.

3. [high] UPDATE users SET status = 'active' WHERE status IS NULL — no down migration
   There is no record of which rows had NULL status before the backfill. A
   rollback cannot distinguish intentionally-NULL rows from newly-active ones.
   If NULL is a meaningful state (e.g., "unverified"), this update corrupts
   that signal permanently.

Missing backfills
1. [medium] ALTER TABLE payments ALTER COLUMN amount — payments
   No preceding UPDATE or SELECT check confirms all existing values are whole
   numbers. If any fractional amounts exist, they will be silently rounded on
   conversion. Run the verification query above before this statement.

Missing indexes
1. [low] actor_id — audit_logs
   actor_id is almost certainly used to look up audit entries by actor, but
   no index is defined. Omitting it means sequential scans as the table grows.
   Add:

     CREATE INDEX CONCURRENTLY ON audit_logs (actor_id);

Summary
BLOCKS DEPLOYMENT — needs changes before running.

Three independent high-severity issues:
- The payments type change will round and permanently destroy cent-precision
  financial data. Run the whole-number verification query first; if any rows
  fail it, this statement must not run.
- DROP TABLE legacy_sessions has no rollback and no down migration. Confirm
  the table is dead code and that a backup exists before executing.
- The users UPDATE is unbatched on 40 million rows. As written it will cause
  replication lag, WAL bloat, and potentially long-running lock contention on
  matched rows. Batch it.

Additionally, there is no down migration for any destructive statement in
this file, making the entire migration irreversible as written.
```
