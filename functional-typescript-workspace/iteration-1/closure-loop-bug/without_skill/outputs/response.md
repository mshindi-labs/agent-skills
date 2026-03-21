# Closure Loop Bug: Why All Handlers Log "Button 5"

## What's Happening

This is a classic JavaScript/TypeScript closure-over-loop-variable bug.

When you use `var` in a `for` loop, the variable `i` is **function-scoped** (or globally scoped), not block-scoped. There is only **one** `i` variable shared across all iterations of the loop.

Each handler function closes over the same `i` variable — not over the _value_ of `i` at the time the function was created. By the time any handler is called, the loop has already finished running, and `i` has been incremented to `5` (the value that caused the loop condition `i < 5` to fail). So every handler reads that final value of `5`.

```typescript
const handlers = [];
for (var i = 0; i < 5; i++) {
  handlers.push(function () {
    console.log("Button", i); // closes over the single shared `i`
  });
}
// At this point, i === 5
// All handlers log "Button 5"
```

## Fixes

### Fix 1: Use `let` instead of `var` (recommended)

`let` is block-scoped. Each iteration of the loop creates a **new binding** for `i`, so each closure captures its own independent copy.

```typescript
const handlers = [];
for (let i = 0; i < 5; i++) {
  handlers.push(function () {
    console.log("Button", i); // each closure captures its own `i`
  });
}
// handlers[0]() → "Button 0"
// handlers[1]() → "Button 1"
// ...
// handlers[4]() → "Button 4"
```

This is the simplest and most idiomatic modern TypeScript/JavaScript fix.

### Fix 2: Use an IIFE (Immediately Invoked Function Expression)

Before `let` was available (ES5 and earlier), the standard pattern was to use an IIFE to create a new scope and capture the current value of `i`:

```typescript
const handlers = [];
for (var i = 0; i < 5; i++) {
  handlers.push(
    (function (index) {
      return function () {
        console.log("Button", index);
      };
    })(i),
  );
}
```

The IIFE is called immediately with the current value of `i`, binding it to the local parameter `index`. Each closure then captures a different `index`.

### Fix 3: Use `Array.from` or `.map` with a functional style

```typescript
const handlers = Array.from(
  { length: 5 },
  (_, i) =>
    function () {
      console.log("Button", i);
    },
);
```

Or using an explicit array:

```typescript
const handlers = [0, 1, 2, 3, 4].map(
  (i) =>
    function () {
      console.log("Button", i);
    },
);
```

Each callback in `.map` receives `i` as a parameter, so each closure captures its own value.

## Summary

| Approach              | Mechanism                                | Recommended?           |
| --------------------- | ---------------------------------------- | ---------------------- |
| `let` in `for` loop   | Block-scoped binding per iteration       | Yes — simplest         |
| IIFE                  | Creates a new scope to capture the value | Legacy/ES5 code only   |
| `Array.from` / `.map` | Parameter binding in callback            | Yes — functional style |

The root cause is `var`'s function scope. The fix is to ensure each closure captures its own independent value, either by using `let` (block scope) or by passing the value as a function argument.
