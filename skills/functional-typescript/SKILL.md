---
name: functional-typescript
description: >
  Helps write idiomatic functional TypeScript and JavaScript. Use this skill
  when the user needs help with functional programming patterns: closures,
  partial application, currying, pure functions, immutability, higher-order
  functions, function composition, or the module pattern. Also use for
  TypeScript types that support FP: Readonly, ReadonlyArray, function generics,
  and discriminated unions. Draws on You Don't Know JS Yet foundations. Trigger
  for questions like "how do I avoid mutation", "how do I curry this function",
  "how should I structure this module", or "how do I type a higher-order
  function in TypeScript".
---

# Functional TypeScript

You are an expert in writing functional JavaScript and TypeScript. When
invoked, guide the user toward idiomatic FP patterns — closures, pure
functions, immutability, composition, and modules — grounded in how JS
actually works. Reference `references/` files for deeper examples.

---

## First-Class Functions

In JS, functions are values. You can assign them, pass them, and return them.
This is the foundation of every FP pattern.

```ts
// Functions as values
const double = (n: number) => n * 2;
const apply = (fn: (x: number) => number, x: number) => fn(x);
apply(double, 5); // 10

// Returning functions (factory)
const multiplier = (factor: number) => (n: number) => n * factor;
const triple = multiplier(3);
triple(7); // 21
```

Prefer named function expressions over anonymous ones — they produce better
stack traces and communicate intent:

```ts
// Prefer
const greet = function greet(name: string) { return `Hello, ${name}`; };

// Over
const greet = (name: string) => `Hello, ${name}`;
// (arrow is fine for short transforms; use named for complex logic)
```

---

## Closures

A closure is a function that remembers the variables from the scope where it
was defined, even after that scope has finished executing.

```ts
function lookupStudent(studentID: number) {
  const students = [
    { id: 14, name: "Kyle" },
    { id: 73, name: "Suzy" },
  ];

  return function greetStudent(greeting: string) {
    const student = students.find(s => s.id === studentID);
    return `${greeting}, ${student?.name}!`;
  };
}

const greetSuzy = lookupStudent(73);
greetSuzy("Hello"); // "Hello, Suzy!"
```

`greetStudent` closes over `students` and `studentID`. Both variables stay
alive in memory as long as `greetStudent` exists, even though
`lookupStudent` has returned.

**When to use closures:**
- Encapsulate private state without a class
- Memoize expensive computations
- Create specialized versions of a function (partial application)

See `references/closures-and-partial-application.md` for more.

---

## Pure Functions

A pure function has two properties:
1. Same inputs always produce the same output
2. No side effects (no mutation of external state, no I/O)

```ts
// Pure
const add = (a: number, b: number): number => a + b;
const toUpper = (s: string): string => s.toUpperCase();

// Impure — reads external state
let tax = 0.1;
const price = (base: number) => base * (1 + tax); // depends on mutable `tax`

// Impure — mutates input
const appendImpure = (arr: number[], val: number) => {
  arr.push(val); // side effect!
  return arr;
};

// Pure equivalent — returns new array
const append = (arr: readonly number[], val: number): number[] =>
  [...arr, val];
```

**Rule:** Push side effects (logging, network, DOM) to the edges of your
program. Keep the core logic pure.

---

## Immutability

Primitives in JS are inherently immutable. Enforce immutability for objects
and arrays via `const`, `Object.freeze`, and TypeScript's `Readonly` types.

```ts
// TypeScript immutable types
type Config = Readonly<{
  host: string;
  port: number;
}>;

const config: Config = { host: "localhost", port: 3000 };
// config.port = 4000; // TS error

// Immutable arrays
const nums: ReadonlyArray<number> = [1, 2, 3];
// nums.push(4); // TS error

// Transform without mutation
const doubled = nums.map(n => n * 2); // new array, original untouched
```

`const` makes the binding immutable, not the value. Use `Readonly<T>` and
`ReadonlyArray<T>` to make the shape immutable at the type level.

For deep immutability, use `as const` on literals:

```ts
const ROLES = ["admin", "viewer", "editor"] as const;
type Role = typeof ROLES[number]; // "admin" | "viewer" | "editor"
```

---

## Partial Application & Currying

See `references/closures-and-partial-application.md` for full examples.
Quick reference:

```ts
// Partial application — fix some args now, supply rest later
function defineHandler(requestURL: string, requestData: unknown) {
  return function makeRequest(_evt: Event) {
    fetch(requestURL, { body: JSON.stringify(requestData) });
  };
}

const handler = defineHandler("/api/users", { page: 1 });
button.addEventListener("click", handler);

// Currying — one argument at a time
const curry =
  <A, B, C>(fn: (a: A, b: B) => C) =>
  (a: A) =>
  (b: B): C =>
    fn(a, b);

const add = (a: number, b: number) => a + b;
const add10 = curry(add)(10);
add10(5);  // 15
add10(32); // 42
```

Both techniques rely on closure to remember the initial inputs.

---

## Higher-Order Functions

A higher-order function (HOF) takes a function as an argument or returns one.

```ts
// Built-in HOFs — use these instead of imperative loops
const evens = [1, 2, 3, 4, 5].filter(n => n % 2 === 0);   // [2, 4]
const squares = [1, 2, 3].map(n => n ** 2);                // [1, 4, 9]
const sum = [1, 2, 3, 4].reduce((acc, n) => acc + n, 0);  // 10

// Typing generic HOFs
function map<A, B>(arr: readonly A[], fn: (a: A) => B): B[] {
  return arr.map(fn);
}

function pipe<T>(...fns: Array<(x: T) => T>): (x: T) => T {
  return (x: T) => fns.reduce((v, fn) => fn(v), x);
}
```

---

## Function Composition

Compose small, single-purpose functions instead of writing complex ones.

```ts
const trim = (s: string) => s.trim();
const lower = (s: string) => s.toLowerCase();
const slug = (s: string) => s.replace(/\s+/g, "-");

// Manual composition (right-to-left)
const toSlug = (s: string) => slug(lower(trim(s)));
toSlug("  Hello World  "); // "hello-world"

// With a pipe utility (left-to-right — easier to read)
const toSlug2 = pipe(trim, lower, slug);
toSlug2("  Hello World  "); // "hello-world"
```

Each function in the pipeline does one thing. The composed result is still
a pure function if every component is pure.

---

## The Module Pattern

Use modules to encapsulate private state and expose a clean public API.
A module is not just a namespace — it must have hidden state accessed only
through privileged functions (via closure).

```ts
// Classic module (IIFE singleton)
const StudentModule = (() => {
  // private
  const records = [
    { id: 14, name: "Kyle" },
    { id: 73, name: "Suzy" },
  ];

  // public API
  return {
    getName(id: number): string | undefined {
      return records.find(s => s.id === id)?.name;
    },
  };
})();

StudentModule.getName(73); // "Suzy"
// StudentModule.records  // undefined — private

// Module factory (multiple instances)
function makeCounter(start = 0) {
  let count = start; // private state

  return {
    increment() { count++; },
    decrement() { count--; },
    value() { return count; },
  };
}

const a = makeCounter(0);
const b = makeCounter(10);
a.increment();
a.value(); // 1
b.value(); // 10 — independent state
```

See `references/module-pattern.md` for ESM and CommonJS equivalents.

---

## TypeScript Types for FP

See `references/fp-typescript-types.md` for the full reference. Key patterns:

```ts
// Function type aliases
type Predicate<T> = (value: T) => boolean;
type Transform<A, B> = (input: A) => B;
type Reducer<S, A> = (state: S, action: A) => S;

// Generic HOF typing
function filter<T>(arr: readonly T[], pred: Predicate<T>): T[] {
  return arr.filter(pred);
}

// Discriminated union instead of class hierarchy
type Result<T> =
  | { ok: true; value: T }
  | { ok: false; error: string };

function divide(a: number, b: number): Result<number> {
  if (b === 0) return { ok: false, error: "Division by zero" };
  return { ok: true, value: a / b };
}

const result = divide(10, 2);
if (result.ok) {
  console.log(result.value); // TS knows this is number
}
```
