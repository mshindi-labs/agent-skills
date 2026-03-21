# fp-ts Checkout Function: From async/await to TaskEither

## The Problem with async/await + try-catch

Your current approach likely looks something like this:

```typescript
// BEFORE — messy async/await with try-catch
async function checkout(userId: string): Promise<Receipt> {
  try {
    const user = await fetchUser(userId);
    if (!user) throw new Error("User not found");

    const cart = await fetchCart(user.cartId);
    if (!cart || cart.items.length === 0) throw new Error("Cart is empty");

    const payment = await chargePaymentMethod(user.savedPaymentId, cart.total);
    if (!payment.success) throw new Error("Payment failed");

    return buildReceipt(user, cart, payment);
  } catch (err) {
    // What type is err? string? Error? PaymentError? Nobody knows.
    throw err;
  }
}
```

Problems with this approach:

- The return type `Promise<Receipt>` lies — it can actually throw, but callers can't see that in the type
- Error types are erased at the `catch` boundary — you receive `unknown`
- Every caller must wrap in try-catch, and must guess what shape the error takes
- Logic is buried in imperative if-checks mixed with awaits

---

## The fp-ts Way: TaskEither + Do Notation

### Step 1: Define your error union

Model every expected failure as a discriminated union. This makes all error cases visible in the type system.

```typescript
// errors.ts
export type CheckoutError =
  | { code: "USER_NOT_FOUND"; message: string }
  | { code: "CART_NOT_FOUND"; message: string }
  | { code: "EMPTY_CART"; message: string }
  | { code: "PAYMENT_FAILED"; message: string; reason?: string }
  | { code: "NETWORK_ERROR"; message: string; status?: number };
```

### Step 2: Lift each service call into TaskEither

Wrap every async operation that can fail using `TE.tryCatch`. The second argument maps the thrown value into your typed error.

```typescript
import * as TE from "fp-ts/TaskEither";
import * as T from "fp-ts/Task";
import { pipe } from "fp-ts/function";
import type { CheckoutError } from "./errors";

// fetchUser — network call that may 404 or throw
const fetchUserTE = (userId: string): TE.TaskEither<CheckoutError, User> =>
  TE.tryCatch(
    async () => {
      const res = await fetch(`/api/users/${userId}`);
      if (res.status === 404) throw { code: "USER_NOT_FOUND", userId };
      if (!res.ok) throw { code: "NETWORK_ERROR", status: res.status };
      return res.json() as User;
    },
    (e): CheckoutError => {
      const err = e as any;
      if (err.code === "USER_NOT_FOUND")
        return { code: "USER_NOT_FOUND", message: `User ${userId} not found` };
      return {
        code: "NETWORK_ERROR",
        message: "Failed to fetch user",
        status: err.status,
      };
    },
  );

// fetchCart — similar pattern
const fetchCartTE = (cartId: string): TE.TaskEither<CheckoutError, Cart> =>
  TE.tryCatch(
    async () => {
      const res = await fetch(`/api/carts/${cartId}`);
      if (res.status === 404) throw { code: "CART_NOT_FOUND", cartId };
      if (!res.ok) throw { code: "NETWORK_ERROR", status: res.status };
      return res.json() as Cart;
    },
    (e): CheckoutError => {
      const err = e as any;
      if (err.code === "CART_NOT_FOUND")
        return { code: "CART_NOT_FOUND", message: `Cart ${cartId} not found` };
      return {
        code: "NETWORK_ERROR",
        message: "Failed to fetch cart",
        status: err.status,
      };
    },
  );

// chargePaymentMethod — most likely to fail; maps to PAYMENT_FAILED
const chargePaymentTE = (
  paymentMethodId: string,
  amount: number,
): TE.TaskEither<CheckoutError, PaymentResult> =>
  TE.tryCatch(
    () => stripeClient.charge(paymentMethodId, amount),
    (e): CheckoutError => ({
      code: "PAYMENT_FAILED",
      message: "Payment could not be processed",
      reason: e instanceof Error ? e.message : String(e),
    }),
  );
```

### Step 3: Compose the checkout workflow with Do notation

Use `TE.Do` + `TE.bind` to carry multiple named values forward through the pipeline. Use `TE.filterOrElse` for mid-pipeline validation that needs access to already-bound values.

```typescript
export type Receipt = {
  receiptId: string;
  userId: string;
  items: CartItem[];
  total: number;
  chargedAt: Date;
};

export const checkout = (
  userId: string,
): TE.TaskEither<CheckoutError, Receipt> =>
  pipe(
    TE.Do,

    // Step 1: Fetch the user
    TE.bind("user", () => fetchUserTE(userId)),

    // Step 2: Fetch their cart (depends on user.cartId)
    TE.bind("cart", ({ user }) => fetchCartTE(user.cartId)),

    // Step 3: Validate cart is non-empty — mid-pipeline guard
    TE.filterOrElse(
      ({ cart }) => cart.items.length > 0,
      (): CheckoutError => ({
        code: "EMPTY_CART",
        message: "Cart has no items",
      }),
    ),

    // Step 4: Calculate total (pure — no async needed, wrap in TE.right)
    TE.bind("total", ({ cart }) => TE.right(calculateTotal(cart.items))),

    // Step 5: Charge the saved payment method (depends on user + total)
    TE.bind("payment", ({ user, total }) =>
      chargePaymentTE(user.savedPaymentMethodId, total),
    ),

    // Step 6: Build the receipt from all collected values
    TE.map(
      ({ user, cart, total, payment }): Receipt => ({
        receiptId: payment.transactionId,
        userId: user.id,
        items: cart.items,
        total,
        chargedAt: new Date(),
      }),
    ),
  );
```

### Step 4: Execute at the edge (HTTP handler / controller)

`TaskEither` is lazy — nothing runs until you call the returned function. Execute it at the boundary (request handler, CLI, etc.) and pattern-match on the result:

```typescript
// HTTP handler — express / next.js style
export const checkoutHandler = async (
  req: Request,
  res: Response,
): Promise<void> => {
  const result = await pipe(
    checkout(req.body.userId),
    TE.fold(
      // Left — map each typed error to the right HTTP status
      (err): T.Task<Response> => {
        switch (err.code) {
          case "USER_NOT_FOUND":
          case "CART_NOT_FOUND":
            return T.of(res.status(404).json(err));
          case "EMPTY_CART":
            return T.of(res.status(422).json(err));
          case "PAYMENT_FAILED":
            return T.of(res.status(402).json(err));
          case "NETWORK_ERROR":
            return T.of(res.status(502).json(err));
        }
      },
      // Right — success
      (receipt): T.Task<Response> => T.of(res.status(200).json(receipt)),
    ),
  )();
};
```

---

## Key Concepts Used

### `TE.tryCatch` — lift any throwing async code

```
TE.tryCatch(
  () => promise,          // the operation
  (thrown) => MyError,    // error mapper — thrown is `unknown`
)
// Returns: TaskEither<MyError, SuccessType>
```

### `TE.Do` + `TE.bind` — sequential steps with named values in scope

```
pipe(
  TE.Do,
  TE.bind("a", ()       => fetchA()),       // 'a' now in scope
  TE.bind("b", ({ a })  => fetchB(a.id)),   // can reference 'a'
  TE.bind("c", ({ a, b}) => fetchC(b.ref)), // can reference 'a' and 'b'
  TE.map(({ a, b, c }) => combine(a, b, c)),
)
```

### `TE.apS` — for independent values (runs in parallel)

If step 2 does NOT need the result of step 1, prefer `apS`:

```typescript
pipe(
  TE.Do,
  TE.apS("config", fetchAppConfig()), // independent
  TE.apS("features", fetchFeatureFlags()), // independent — runs in parallel with config
  TE.bind("user", () => fetchUser(userId)),
);
```

### `TE.filterOrElse` — inline validation that short-circuits the pipeline

```
TE.filterOrElse(
  ({ cart }) => cart.items.length > 0,    // predicate
  (): CheckoutError => ({ code: "EMPTY_CART", message: "..." }), // error if false
)
```

If the predicate returns `false`, the entire pipeline short-circuits with that `Left` error. No subsequent `bind` steps execute.

### `TE.chainW` — when steps have different error types

If your service functions return different error types and you want to widen the union automatically:

```typescript
pipe(
  validateInput(raw), // TE<ValidationError, Input>
  TE.chainW(callApi), // TE<ValidationError | ApiError, Response>
  TE.chainW(saveToDb), // TE<ValidationError | ApiError | DbError, Record>
);
// The 'W' suffix means "widen" — TypeScript infers the union automatically
```

---

## Before / After Comparison

| Aspect                     | async/await + try-catch     | TaskEither + Do notation                  |
| -------------------------- | --------------------------- | ----------------------------------------- |
| Error types                | Erased (`unknown` in catch) | Explicit in return type signature         |
| Callers know what can fail | No                          | Yes — `CheckoutError` is in the type      |
| Mid-pipeline guards        | Imperative `if (!x) throw`  | `filterOrElse` — declarative, in-pipeline |
| Short-circuit on failure   | Relies on exceptions        | Automatic — `Left` skips remaining steps  |
| Values from earlier steps  | Variable scope + nesting    | `bind` keeps all values in context        |
| Execution                  | Eager (runs immediately)    | Lazy (runs when you call `()`)            |
| Pattern matching at edge   | try-catch + `instanceof`    | `TE.fold(onErr, onOk)` — exhaustive       |

---

## Complete Working Example

```typescript
import * as TE from "fp-ts/TaskEither";
import * as T from "fp-ts/Task";
import { pipe } from "fp-ts/function";

// --- Domain types ---

type CartItem = { productId: string; quantity: number; unitPrice: number };
type User = { id: string; cartId: string; savedPaymentMethodId: string };
type Cart = { id: string; items: CartItem[] };
type PaymentResult = { transactionId: string; amount: number };

type CheckoutError =
  | { code: "USER_NOT_FOUND"; message: string }
  | { code: "CART_NOT_FOUND"; message: string }
  | { code: "EMPTY_CART"; message: string }
  | { code: "PAYMENT_FAILED"; message: string; reason?: string }
  | { code: "NETWORK_ERROR"; message: string; status?: number };

type Receipt = {
  receiptId: string;
  userId: string;
  items: CartItem[];
  total: number;
  chargedAt: Date;
};

// --- Pure helpers ---

const calculateTotal = (items: CartItem[]): number =>
  items.reduce((sum, item) => sum + item.quantity * item.unitPrice, 0);

// --- Service adapters (TaskEither wrappers) ---

const fetchUserTE = (userId: string): TE.TaskEither<CheckoutError, User> =>
  TE.tryCatch(
    async () => {
      const res = await fetch(`/api/users/${userId}`);
      if (res.status === 404) throw { code: "USER_NOT_FOUND" };
      if (!res.ok) throw { code: "NETWORK_ERROR", status: res.status };
      return res.json() as User;
    },
    (e: any): CheckoutError =>
      e.code === "USER_NOT_FOUND"
        ? { code: "USER_NOT_FOUND", message: `User ${userId} not found` }
        : {
            code: "NETWORK_ERROR",
            message: "Failed to fetch user",
            status: e.status,
          },
  );

const fetchCartTE = (cartId: string): TE.TaskEither<CheckoutError, Cart> =>
  TE.tryCatch(
    async () => {
      const res = await fetch(`/api/carts/${cartId}`);
      if (res.status === 404) throw { code: "CART_NOT_FOUND" };
      if (!res.ok) throw { code: "NETWORK_ERROR", status: res.status };
      return res.json() as Cart;
    },
    (e: any): CheckoutError =>
      e.code === "CART_NOT_FOUND"
        ? { code: "CART_NOT_FOUND", message: `Cart ${cartId} not found` }
        : {
            code: "NETWORK_ERROR",
            message: "Failed to fetch cart",
            status: e.status,
          },
  );

const chargePaymentTE = (
  paymentMethodId: string,
  amount: number,
): TE.TaskEither<CheckoutError, PaymentResult> =>
  TE.tryCatch(
    () => stripeClient.charge(paymentMethodId, amount),
    (e): CheckoutError => ({
      code: "PAYMENT_FAILED",
      message: "Payment could not be processed",
      reason: e instanceof Error ? e.message : String(e),
    }),
  );

// --- Checkout workflow ---

export const checkout = (
  userId: string,
): TE.TaskEither<CheckoutError, Receipt> =>
  pipe(
    TE.Do,
    TE.bind("user", () => fetchUserTE(userId)),
    TE.bind("cart", ({ user }) => fetchCartTE(user.cartId)),
    TE.filterOrElse(
      ({ cart }) => cart.items.length > 0,
      (): CheckoutError => ({
        code: "EMPTY_CART",
        message: "Cart has no items",
      }),
    ),
    TE.bind("total", ({ cart }) => TE.right(calculateTotal(cart.items))),
    TE.bind("payment", ({ user, total }) =>
      chargePaymentTE(user.savedPaymentMethodId, total),
    ),
    TE.map(
      ({ user, cart, total, payment }): Receipt => ({
        receiptId: payment.transactionId,
        userId: user.id,
        items: cart.items,
        total,
        chargedAt: new Date(),
      }),
    ),
  );

// --- Execution at the boundary ---

// Option A: fold — exhaustive pattern match, returns Task<T>
const runCheckout = async (userId: string): Promise<void> => {
  await pipe(
    checkout(userId),
    TE.fold(
      (err) => {
        switch (err.code) {
          case "USER_NOT_FOUND":
            return T.of(console.error("No such user:", err.message));
          case "EMPTY_CART":
            return T.of(console.error("Nothing in cart"));
          case "PAYMENT_FAILED":
            return T.of(console.error("Payment declined:", err.reason));
          default:
            return T.of(console.error("Unexpected error:", err));
        }
      },
      (receipt) => T.of(console.log("Success!", receipt)),
    ),
  )();
};

// Option B: get the Either directly and handle imperatively
const runCheckoutImperative = async (userId: string) => {
  const result = await checkout(userId)(); // Either<CheckoutError, Receipt>
  if (result._tag === "Left") {
    return { ok: false, error: result.left };
  }
  return { ok: true, receipt: result.right };
};
```

---

## Summary of Rules Applied

- **`fp-ts-taskeither`**: Use `TE.TaskEither<E, A>` for async operations that can fail. Wrap service calls with `TE.tryCatch`. Chain with `TE.chain`/`TE.bind`. Execute with `TE.fold` at the boundary.
- **`fp-ts-do-notation`**: Use `TE.Do` + `TE.bind` to carry multiple named values forward. Use `TE.filterOrElse` for mid-pipeline validation. Use `TE.apS` (not `bind`) when steps are independent.
- **`fp-ts-pipe-flow`**: Use `pipe` to sequence all transformations top-to-bottom instead of nesting function calls.
- **`types-discriminated-union`**: Model `CheckoutError` as a discriminated union with a `code` field — enables exhaustive `switch` at the call site.
