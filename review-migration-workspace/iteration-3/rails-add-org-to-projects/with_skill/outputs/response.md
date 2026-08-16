No schema files on disk — reviewing the inline migration only.

---

```
Migration: AddOrgToProjects

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CRITICAL — Runtime error (blocks the migration from completing)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. [critical] add_index algorithm: :concurrently inside a transaction — projects
   Rails wraps every migration in a transaction by default.
   CREATE INDEX CONCURRENTLY is forbidden inside a transaction block and will
   raise an error, aborting the entire migration before it finishes.

   Fix: add disable_ddl_transaction! at the top of the class, and move the
   concurrent index into its own migration so the other DDL (which needs a
   transaction) is not affected:

     class AddOrgToProjects < ActiveRecord::Migration[7.0]
       disable_ddl_transaction!
       ...
     end

   Better: split this into two migrations — one for the column/FK/rename inside
   a transaction, one for the index with disable_ddl_transaction!.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Data-loss / breaking-change risks
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. [high] rename_column :projects, :owner, :legacy_owner
   This is a hard cut-over rename. Any app instance still running the old code
   (rolling deploys, sidekiq workers, read replicas queried by old code) will
   immediately get "column owner does not exist" errors. There is no safe
   overlap window.

   Safe two-phase approach:
     Phase 1 (this deploy): add_column :projects, :legacy_owner, :string
                             keep a DB trigger or app-layer dual-write to sync both
     Phase 2 (next deploy): remove_column :projects, :owner

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Lock risks
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. [high] add_foreign_key :projects, :organizations — projects table
   Without validate: false, Rails emits ADD CONSTRAINT which takes ACCESS
   EXCLUSIVE on projects and holds it across a full table scan of all millions
   of rows to verify every row satisfies the constraint. Even though all
   existing rows have NULL organization_id (which is FK-valid), the scan still
   runs, and reads and writes are blocked for its entire duration.

   Safe alternative:
     add_foreign_key :projects, :organizations,
                     column: :organization_id, validate: false
   Then, in a separate migration or maintenance window:
     execute "ALTER TABLE projects VALIDATE CONSTRAINT fk_rails_..."
   VALIDATE CONSTRAINT takes SHARE UPDATE EXCLUSIVE — reads and writes both
   continue while the scan runs.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Reversibility gaps
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. [high] rename_column is not reversed in down
   down removes organization_id but never renames legacy_owner back to owner.
   Rolling back this migration leaves the column permanently renamed, breaking
   all app code that references owner.

   Fix:
     def down
       rename_column :projects, :legacy_owner, :owner
       remove_foreign_key :projects, :organizations
       remove_column :projects, :organization_id
       remove_index :projects, :status
     end

2. [medium] add_index :projects, :status is not removed in down
   Minor: a leftover index is not destructive, but the rollback is incomplete.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Missing indexes
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. [low] organization_id — projects table
   The new FK column has no supporting index. Joins from projects to
   organizations, and cascading updates/deletes on organizations, will do
   full sequential scans on a millions-row table.

   Add (in the same migration, after disable_ddl_transaction! is set):
     add_index :projects, :organization_id, algorithm: :concurrently

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BLOCKS DEPLOYMENT — do not run as-is.

Four issues must be resolved before production:

  1. The concurrent index will crash the migration at runtime due to the
     implicit transaction wrapper. Split it into its own migration.
  2. rename_column is a hard cutover that will break in-flight requests during
     any rolling deploy. Use a two-phase rename.
  3. add_foreign_key without validate: false will hold ACCESS EXCLUSIVE across
     a full scan of millions of rows, causing downtime.
  4. down does not reverse the rename — a rollback leaves the schema broken.
```
