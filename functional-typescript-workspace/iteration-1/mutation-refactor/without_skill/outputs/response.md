# Bug Analysis: Mutation in Cart Functions

## What's Wrong

All three functions share the same root cause: **they mutate their input arguments directly** instead of returning new values. In JavaScript/TypeScript, arrays and objects are passed by reference. When you call `cart.push(item)`, `order.total = ...`, or `items.sort(...)`, you are modifying the original data structure that was passed in — not a copy.

### Function-by-function breakdown

**`addItem`**

```typescript
function addItem(cart: CartItem[], item: CartItem): CartItem[] {
  cart.push(item); // mutates the original array
  return cart; // returns the same reference
}
```

Any component holding a reference to the original `cart` array will see it silently change. React's reconciliation relies on reference equality (`===`) to detect changes, so mutating state in place often means React never re-renders, or causes inconsistent renders across components that share the same reference.

**`applyDiscount`**

```typescript
function applyDiscount(order: Order, percent: number): Order {
  order.total = order.total * (1 - percent / 100); // mutates the original object
  return order;
}
```

Calling this from multiple components or in multiple places will cumulatively corrupt `order.total`. A 10% discount applied twice results in a 19% discount — not what was intended.

**`sortByPrice`**

```typescript
function sortByPrice(items: CartItem[]): CartItem[] {
  return items.sort(...)  // Array.prototype.sort sorts IN PLACE
}
```

`Array.prototype.sort` mutates the original array. Any component referencing the unsorted list will suddenly see it sorted, without being notified of the change.

---

## Refactored Safe Versions

The fix for all three is the same pattern: **create a new value rather than modifying the input**.

```typescript
// Return a new array with the item appended — original is never touched
function addItem(cart: CartItem[], item: CartItem): CartItem[] {
  return [...cart, item];
}

// Return a new object with the updated total — original is never touched
function applyDiscount(order: Order, percent: number): Order {
  return {
    ...order,
    total: order.total * (1 - percent / 100),
  };
}

// Slice creates a shallow copy before sorting — original is never touched
function sortByPrice(items: CartItem[]): CartItem[] {
  return [...items].sort((a, b) => a.price - b.price);
}
```

---

## Why This Fixes the Bugs

| Principle                         | Effect                                                                                                            |
| --------------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| Inputs are never modified         | A component's local reference to `cart` or `order` stays stable until it explicitly receives a new value          |
| Each call returns a new reference | React can correctly detect the change via reference inequality and re-render only what needs to re-render         |
| Functions are pure                | Given the same inputs they always produce the same output, making them easy to test and reason about in isolation |

---

## General Rule

Whenever you write a function that accepts an array or object in TypeScript/JavaScript, ask: "Am I modifying the argument, or am I returning a new value?" For shared state in a React app, always return a new value. Use spread syntax (`[...arr]`, `{ ...obj }`), `Array.prototype.slice()`, `Object.assign({}, obj)`, or `structuredClone()` for deep copies when needed.
