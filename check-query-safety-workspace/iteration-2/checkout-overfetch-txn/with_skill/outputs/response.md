Following the skill's review steps on the provided code.

```
Query safety review: checkout module
──────────────────────────────────────────────────

ORM detected: Prisma

SQL injection risks (0)
  None. All queries use Prisma's parameterized API.

N+1 patterns (0)
  None. No loops containing queries.

Unbounded queries (0)
  None. No findMany calls without filters.

Over-fetching (1)
1. [low] Unused relations loaded — getAuthorName, lines 4–8
   include: { author: true, comments: true, tags: true }
   Only post?.author.name is returned. The full comments and tags
   collections are fetched and discarded entirely. The full author
   record is also loaded when only the name field is needed.
   Fix:
     select: {
       author: { select: { name: true } }
     }

Missing transactions (1)
2. [high] Multi-table write without transaction — placeOrder, lines 11–18
   prisma.order.create + prisma.inventory.update run as two separate
   statements. If the inventory update fails (e.g. network error, constraint
   violation), the order row exists but inventory is never decremented —
   leaving stock counts permanently incorrect.
   Fix:
     return await prisma.$transaction(async (tx) => {
       const order = await tx.order.create({ data: orderData });
       await tx.inventory.update({
         where: { id: orderData.inventoryId },
         data: { quantity: { decrement: 1 } },
       });
       return order;
     });

Summary
  2 issues. The missing transaction in placeOrder is the critical one —
  it can corrupt inventory counts on any transient failure and requires
  immediate attention. The over-fetching in getAuthorName is a minor
  efficiency issue with no correctness impact.
```
