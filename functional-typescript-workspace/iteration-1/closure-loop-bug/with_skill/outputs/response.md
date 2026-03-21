# The Loop-Closure Bug: Why All Handlers Log "Button 5"

## What Is Happening

The bug is caused by using `var` in the loop. `var` does not create a new binding per iteration — it creates a single variable `i` scoped to the enclosing function (or global scope). Every closure pushed into `handlers` captures a reference to that same single `i`, not a snapshot of its value at the time the closure was created.

By the time any handler is actually invoked (after the loop completes), `i` has already been incremented to `5` (the value that caused the loop condition `i < 5` to become false). So every handler reads `i` and sees `5`.

```typescript
const handlers = [];
for (var i = 0; i < 5; i++) {
  handlers.push(function () {
    console.log("Button", i); // closes over the one shared `i`
  });
}
// After the loop, i === 5
// Every handler logs "Button 5"
```

## Fix 1: Replace `var` with `let` (Minimal Change)

`let` creates a fresh binding for each loop iteration. Each closure captures its own independent `i`.

```typescript
const handlers: Array<() => void> = [];

for (let i = 0; i < 5; i++) {
  handlers.push(function () {
    console.log("Button", i); // each closure has its own i: 0, 1, 2, 3, 4
  });
}

// handlers[0]() → "Button 0"
// handlers[1]() → "Button 1"
// handlers[4]() → "Button 4"
```

This is the direct fix described in rule `closure-loop-pitfall`: never use `var`; use `let` when reassignment is required.

## Fix 2: Use Array Methods (Preferred Functional Style)

The rule goes further and recommends eliminating the loop index variable entirely by using array methods. This is the preferred functional approach because there is no shared mutable variable at all.

```typescript
const handlers: Array<() => void> = Array.from(
  { length: 5 },
  (_, i) =>
    function () {
      console.log("Button", i);
    },
);

// Or with forEach if building from an existing array:
const buttons = Array.from({ length: 5 }, (_, i) => i);

buttons.forEach((i) => {
  handlers.push(() => console.log("Button", i));
});
```

For event listeners on DOM buttons (the real-world pattern):

```typescript
// Best: no loop variable to close over at all
Array.from(document.querySelectorAll("button")).forEach((btn, i) => {
  btn.addEventListener("click", () => console.log(`Button ${i} clicked`));
});
```

## Summary

| Approach                                       | Problem                                                  | Recommendation             |
| ---------------------------------------------- | -------------------------------------------------------- | -------------------------- |
| `var i` in loop                                | Single shared binding; all closures see final value      | Never use `var`            |
| `let i` in loop                                | Per-iteration binding; each closure captures its own `i` | Correct and acceptable     |
| Array methods (`forEach`, `map`, `Array.from`) | No loop variable at all; index arrives as a parameter    | Preferred functional style |

**Root rule:** `var` is function-scoped; `let` is block-scoped with per-iteration rebinding in `for` loops. All closures created inside a `var` loop share the same variable. Prefer `const` by default, `let` only when reassignment is needed, and `var` never.

Reference: [_You Don't Know JS Yet_](https://github.com/getify/you-dont-know-js) by Kyle Simpson — Scope & Closures, Chapter 5 (rule: `closure-loop-pitfall`)
