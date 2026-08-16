I'll review this code for query safety issues now.

Here are the issues I found, ranked by severity:

---

**1. SQL Injection — Critical (line 5)**

```typescript
const rows = await db.query(
  `SELECT * FROM orders WHERE user_id = ${req.params.id}`,
);
```

`req.params.id` is interpolated directly into a template literal SQL string. An attacker can pass `1 OR 1=1` or `1; DROP TABLE orders;--` and it will execute. Use a parameterized query:

```typescript
const rows = await db.query("SELECT * FROM orders WHERE user_id = $1", [
  req.params.id,
]);
```

Also note: `rows` is never used — this query runs, causes a vulnerability, and its result is silently discarded. It should be removed entirely since Prisma does the same fetch on line 7.

---

**2. N+1 Query Problem — High (lines 9–12)**

```typescript
for (const order of orders) {
  const items = await db.orderItem.findMany({ where: { orderId: order.id } });
  order.items = items;
}
```

This fires one query per order. With 100 orders, that's 101 DB round trips. Use Prisma's `include` instead:

```typescript
const orders = await prisma.order.findMany({
  where: { userId: req.params.id },
  include: { items: true },
});
```

---

**3. Unbounded Query — Medium (line 16)**

```typescript
return prisma.event.findMany();
```

No `take`, no pagination. If the `event` table grows large, this returns everything in one shot — memory pressure and slow responses. Add a limit and/or cursor-based pagination.

---

**Safe — `getUserById` (line 20)**

```typescript
return db.query("SELECT * FROM users WHERE id = $1", [userId]);
```

This is fine — it uses a parameterized query correctly.

---

**Summary of changes needed:**

| Line | Issue                              | Fix                                     |
| ---- | ---------------------------------- | --------------------------------------- |
| 5    | SQL injection via template literal | Remove the raw query; Prisma covers it  |
| 9–12 | N+1 loop                           | Replace with `include: { items: true }` |
| 16   | Unbounded `findMany`               | Add `take` / pagination                 |
