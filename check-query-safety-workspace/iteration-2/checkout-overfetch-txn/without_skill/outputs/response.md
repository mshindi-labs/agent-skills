Three issues:

**1. Over-fetching in `getAuthorName` (line 5–8)**

`comments` and `tags` are fetched but never used. Only `author.name` is returned. Replace `include` with a targeted `select`:

```typescript
const post = await prisma.post.findUnique({
  where: { id: postId },
  select: { author: { select: { name: true } } },
});
```

**2. Non-atomic writes in `placeOrder` (lines 12–18)**

`order.create` and `inventory.update` are two separate operations. If the second fails, the order exists but inventory is never decremented — a silent inconsistency. Wrap both in a transaction:

```typescript
const [order] = await prisma.$transaction([
  prisma.order.create({ data: orderData }),
  prisma.inventory.update({
    where: { id: orderData.inventoryId },
    data: { quantity: { decrement: 1 } },
  }),
]);
return order;
```

**3. No inventory availability guard in `placeOrder`**

The decrement has no floor check — `quantity` can go negative if concurrent orders race or stock is already zero. Add a `where` guard to make the update conditional:

```typescript
prisma.inventory.update({
  where: { id: orderData.inventoryId, quantity: { gt: 0 } },
  data: { quantity: { decrement: 1 } },
}),
```

If the update matches zero rows, Prisma throws, which also rolls back the transaction. You'd then catch that to return a proper "out of stock" error.

`getOrderTotal` is fine — it already uses `select` correctly.
