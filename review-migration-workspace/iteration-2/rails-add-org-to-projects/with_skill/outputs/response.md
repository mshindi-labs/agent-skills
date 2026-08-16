No schema files found — reviewing from the migration alone, with the user's note that `projects` has millions of rows.

---

**Migration: `AddOrgToProjects`**

---

## Data-loss risks

**1. [high] `rename_column :projects, :owner, :legacy_owner`**

`RENAME COLUMN` takes an `ACCESS EXCLUSIVE` lock — it blocks all reads and writes on `projects` for its duration. More critically, any application code still referencing the column as `owner` will break the moment this runs. With millions of rows, even a short lock can queue up hundreds of waiting connections, leading to cascading timeouts across the app. This is a breaking change that must be coordinated with a deploy: the app must either use the new name before the migration runs (expand/contract pattern) or the column must be aliased during transition.

---

## Lock risks

**1. [high] `add_foreign_key :projects, :organizations` — `projects` table**

`ADD CONSTRAINT` (non-`NOT VALID`) takes an `ACCESS EXCLUSIVE` lock on `projects` and scans every existing row to verify referential integrity. On a multi-million-row table this scan can take minutes, blocking all reads and writes for the entire duration. Safe alternative:

```ruby
add_foreign_key :projects, :organizations, column: :organization_id, validate: false
# Then in a separate migration:
validate_foreign_key :projects, :organizations
```

`ADD CONSTRAINT ... NOT VALID` acquires only a brief `ACCESS EXCLUSIVE` lock to add the constraint record; `VALIDATE CONSTRAINT` later takes only `SHARE UPDATE EXCLUSIVE` (reads and writes keep working).

**2. [high] `rename_column :projects, :owner, :legacy_owner` — `projects` table**

`ACCESS EXCLUSIVE` lock (see Data-loss risks above). There is no non-locking alternative to `RENAME COLUMN` in Postgres — the only safe path is the expand/contract pattern: add the new column, dual-write, backfill, then drop the old column in a later deploy.

**3. [medium] `add_index :projects, :status, algorithm: :concurrently`**

`CREATE INDEX CONCURRENTLY` is the right choice and takes only `SHARE UPDATE EXCLUSIVE` (reads and writes keep working). However, `CONCURRENTLY` **cannot run inside a transaction block**. Rails wraps migrations in a transaction by default. This will raise a `PG::ActiveSqlTransaction` error at runtime unless the migration opts out:

```ruby
class AddOrgToProjects < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!
  # ...
end
```

Without `disable_ddl_transaction!`, the `algorithm: :concurrently` flag is silently ignored in some Rails versions and falls back to a blocking `SHARE` lock — or the migration aborts entirely. Verify which behavior your Rails/PG version exhibits.

**4. [low] `add_column :projects, :organization_id, :bigint`**

Nullable column with no default — low risk, no table rewrite. No lock concern.

---

## Reversibility gaps

**1. [high] `down` does not reverse `rename_column` or `add_foreign_key`**

The `down` method only removes `organization_id`. It does not:

- Rename `legacy_owner` back to `owner` (`rename_column :projects, :legacy_owner, :owner`)
- Remove the foreign key before dropping the column (required, or Postgres will refuse the `DROP COLUMN`)
- Remove the index on `status`

A rollback will either fail (if the FK constraint prevents column removal) or leave the table in a partially-reversed state with `legacy_owner` still renamed. Fix:

```ruby
def down
  remove_index :projects, :status, algorithm: :concurrently
  remove_foreign_key :projects, column: :organization_id
  remove_column :projects, :organization_id
  rename_column :projects, :legacy_owner, :owner
end
```

---

## Missing backfills

**1. [medium] `add_foreign_key` without verifying existing data — `projects`**

There is no guarantee that existing `organization_id` values (all `NULL` after `add_column`) are valid — but since the column is nullable and no `NOT NULL` constraint is added, this is not an immediate failure. It becomes a risk if a `NOT NULL` constraint or backfill is added in a follow-up migration without first validating all rows. Track this for the next migration in the sequence.

---

## Missing indexes

**1. [low] `organization_id` foreign key column has no index — `projects`**

`add_foreign_key` does not automatically create an index on the referencing column. Without one, any join or lookup by `organization_id` will do a full sequential scan of the millions-of-rows `projects` table. Add:

```ruby
add_index :projects, :organization_id, algorithm: :concurrently
```

This should be added before the foreign key if possible, or in a separate migration with `disable_ddl_transaction!`.

---

## Summary

**Blocks deployment as written.** Four issues require fixes before this runs in production:

| #   | Severity   | Issue                                                                                                             |
| --- | ---------- | ----------------------------------------------------------------------------------------------------------------- |
| 1   | **High**   | `add_foreign_key` without `validate: false` will hold `ACCESS EXCLUSIVE` for minutes on a multi-million-row table |
| 2   | **High**   | `rename_column` is a breaking change; must be coordinated with app deploy using expand/contract                   |
| 3   | **High**   | `down` is incomplete — rollback will fail or leave the schema in a broken state                                   |
| 4   | **Medium** | `add_index ... algorithm: :concurrently` will fail or degrade silently without `disable_ddl_transaction!`         |
| 5   | **Low**    | Missing index on `organization_id` FK column                                                                      |
