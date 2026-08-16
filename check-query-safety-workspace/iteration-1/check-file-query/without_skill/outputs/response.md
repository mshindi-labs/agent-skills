The skill didn't load in this sandbox, so here's the review done directly.

**Critical — SQL injection (line 5)**

```ts
const rows = await db.query(
  `SELECT * FROM orders WHERE user_id = ${req.params.id}`,
);
```

Raw string interpolation of user input into SQL. `req.params.id` is attacker-controlled — classic injection. Its result (`rows`) is never even used; the very next line re-fetches the same data via Prisma. Delete this line entirely.

**Blocker — `db` is undefined**
`db` is never imported or instantiated anywhere in the file (only `prisma` is). Lines 5, 10, and 22 (`db.query(...)`, `db.orderItem.findMany(...)`, `db.query(...)`) will all throw at runtime. This can't ship as-is regardless of the query issues below.

**N+1 query (lines 9-12)**

```ts
for (const order of orders) {
  const items = await db.orderItem.findMany({ where: { orderId: order.id } });
```

One round-trip per order. Use Prisma's relation include instead:

```ts
const orders = await prisma.order.findMany({
  where: { userId: req.params.id },
  include: { items: true },
});
```

**Unbounded scan / over-fetch — `listEvents()` (line 18)**
`prisma.event.findMany()` with no `take`/cursor pulls the whole table on every call. Add pagination and a `select` for only needed columns.

**Minor — `getUserById` (line 22)**
Parameterized (`$1`) so no injection risk — fine once `db` actually exists. `SELECT *` is over-fetching but low-risk for a single-row lookup.

Not flagged: `prisma.order.findMany({ where: { userId: ... } })` — Prisma parameterizes automatically, safe.

Fix priority: drop line 5, wire up `db` (or drop it in favor of `prisma` everywhere), fold the N+1 loop into `include`, paginate `listEvents`.
