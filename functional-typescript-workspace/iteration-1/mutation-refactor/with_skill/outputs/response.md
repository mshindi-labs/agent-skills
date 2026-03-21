# Cart Mutation Bug: Diagnosis and Refactor

## What Is Going Wrong

All three functions share the same root cause: **they mutate their input arguments**. In a React app where multiple components hold references to the same cart or order object, any one of them calling these functions corrupts the shared data for everyone else — silently, with no error thrown.

Here is each function broken down:

---

### `addItem` — mutates the array in place

```typescript
function addItem(cart: CartItem[], item: CartItem): CartItem[] {
  cart.push(item); // mutates the caller's array directly
  return cart; // returns the same reference
}
```

`Array.push` modifies the original array. Every component holding a reference to `cart` now sees the new item, even components that never called `addItem`. In React, because the reference did not change, state updates that depend on reference equality (e.g. `useMemo`, `React.memo`, `useEffect` deps) will **not** re-run, causing stale renders or missed updates.

**Rule violated:** `immut-avoid-mutation`, `immut-spread-over-push`

---

### `applyDiscount` — mutates the object in place

```typescript
function applyDiscount(order: Order, percent: number): Order {
  order.total = order.total * (1 - percent / 100); // mutates input object
  return order;
}
```

Directly assigning to `order.total` modifies the original object. Any component reading `order.total` before and after this call will see different values from the same object reference — a classic shared-state bug. Calling this function twice on the same order compounds the discount rather than applying it once from the original total.

**Rule violated:** `immut-avoid-mutation`

---

### `sortByPrice` — `Array.sort` mutates in place

```typescript
function sortByPrice(items: CartItem[]): CartItem[] {
  return items.sort((a, b) => a.price - b.price); // sort mutates the original array
}
```

`Array.prototype.sort` sorts the array **in place** and returns the same reference. Every caller that holds a reference to `items` now has their array silently reordered. This is especially dangerous because the function signature looks like it returns a new array (it returns `CartItem[]`), but it does not.

**Rule violated:** `immut-avoid-mutation`, `immut-spread-over-push`, `immut-readonly-types`

---

## The Fix: Immutable Versions

The pattern is consistent across all three:

1. Annotate parameters as `readonly` / `Readonly<T>` — this makes TypeScript refuse to compile any mutation attempt.
2. Return a **new** data structure instead of modifying the input.

```typescript
// immut-spread-over-push: spread instead of push
// immut-avoid-mutation: never modify the argument
// immut-readonly-types: readonly parameter prevents accidental mutation
function addItem(cart: readonly CartItem[], item: CartItem): CartItem[] {
  return [...cart, item];
}

// immut-avoid-mutation: spread the object to create a new one
// immut-readonly-types: Readonly<Order> makes direct assignment a compile error
function applyDiscount(order: Readonly<Order>, percent: number): Order {
  return { ...order, total: order.total * (1 - percent / 100) };
}

// immut-spread-over-push: copy first, then sort (or use ES2023 toSorted)
// immut-readonly-types: readonly parameter signals no mutation will occur
function sortByPrice(items: readonly CartItem[]): CartItem[] {
  return [...items].sort((a, b) => a.price - b.price);
  // ES2023 alternative (preferred if available):
  // return items.toSorted((a, b) => a.price - b.price)
}
```

---

## Why `readonly` Parameters Matter

Adding `Readonly<T>` and `readonly T[]` to parameters turns mutation from a **silent runtime bug** into a **compile-time error**:

```typescript
function addItem(cart: readonly CartItem[], item: CartItem): CartItem[] {
  cart.push(item); // TS Error: Property 'push' does not exist on type 'readonly CartItem[]'
}
```

The TypeScript compiler now enforces the pure-function contract automatically. You get the bug caught at compile time, before it ever reaches a browser.

---

## Key Rules Applied

| Rule                     | Impact   | What It Prevents                                                        |
| ------------------------ | -------- | ----------------------------------------------------------------------- |
| `immut-avoid-mutation`   | CRITICAL | Shared-state corruption across components                               |
| `immut-readonly-types`   | CRITICAL | Accidental mutation caught at compile time                              |
| `immut-spread-over-push` | CRITICAL | In-place array methods (`push`, `sort`) silently rewriting shared state |

---

## Summary

The bugs you are seeing are caused by **reference mutation**: these functions modify the arrays and objects passed to them, so all callers sharing those references observe the changes. In React, this also bypasses change detection because the object reference never changes.

The fix is to:

- Use `[...array, item]` instead of `array.push(item)`
- Use `{ ...object, field: newValue }` instead of `object.field = newValue`
- Use `[...array].sort(...)` or `array.toSorted(...)` instead of `array.sort(...)`
- Type all input parameters as `readonly T[]` / `Readonly<T>` so TypeScript enforces immutability at compile time
