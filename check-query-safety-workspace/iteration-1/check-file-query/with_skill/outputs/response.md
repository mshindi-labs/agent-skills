```text
Query safety review: pasted snippet (getUserOrders / listEvents / getUserById)
──────────────────────────────────────────────────

SQL injection risks (1)
1. [high] String interpolation in raw query — line 5
   db.query(`SELECT * FROM orders WHERE user_id = ${req.params.id}`)
   Input source: req.params.id (route parameter, user-controlled)
   Fix: db.query('SELECT * FROM orders WHERE user_id = $1', [req.params.id])
   Note: this query's result (`rows`) is never used — the very next line re-fetches the
   same data safely via prisma.order.findMany. Simplest fix is to delete line 5 outright.

N+1 patterns (1)
1. [medium] Query inside loop — lines 9-11
   prisma.orderItem.findMany() called once per order (N queries for N orders)
   Fix: fetch items in the initial query —
     prisma.order.findMany({ where: { userId: req.params.id }, include: { items: true } })
   or batch after the fact: prisma.orderItem.findMany({ where: { orderId: { in: orders.map(o => o.id) } } })

Unbounded queries (1)
1. [medium] findMany without take/limit — line 18 (listEvents)
   prisma.event.findMany() — event tables grow indefinitely, no where/take
   Fix: add take: 100 (or appropriate page size) with cursor/offset pagination

Over-fetching (0)
  Can't assess getUserById (line 22) — return value goes straight to the caller, no
  downstream field usage visible in this snippet.

Missing transactions (0)
  No multi-table writes in this file — all three functions are reads.

Summary: issues requiring immediate attention before shipping. The raw-SQL injection on
line 5 is the blocker (delete it or parameterize); the N+1 in getUserOrders and the
unbounded listEvents should also be fixed before this goes to production.
```

Also worth noting: `getUserById` (line 22) already uses the correct parameterized pattern — use it as the template when fixing line 5.
