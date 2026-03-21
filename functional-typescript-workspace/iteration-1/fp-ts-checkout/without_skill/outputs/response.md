# fp-ts Checkout Function

Your async/await + try-catch pattern is messy because errors are invisible in the type signature and control flow is imperative. fp-ts solves this by making errors part of the type and chaining operations declaratively.

The core type you need is `TaskEither<E, A>`, which is just `() => Promise<Either<E, A>>`. Left = failure with typed error, Right = success value. Nothing runs until you call it.

---

## The Before (what you have now)

```typescript
async function checkout(userId: string): Promise<Receipt> {
  try {
    const user = await fetchUser(userId);
    if (!user) throw new Error("User not found");

    const cart = await fetchCart(user.cartId);
    if (!cart) throw new Error("Cart not found");

    if (cart.items.length === 0) throw new Error("Cart is empty");

    const payment = await chargePaymentMethod(
      user.savedPaymentMethodId,
      cart.total,
    );
    if (!payment.success) throw new Error("Payment failed");

    return buildReceipt(payment);
  } catch (e) {
    // What type is e? Who knows. What can throw? Everything.
    throw e;
  }
}
```

Problems:

- The return type `Promise<Receipt>` hides all possible failures
- Callers must guess what can throw and what the error shape looks like
- Each new step adds another try-catch or conditional throw

---

## Step 1: Define your error union

Give every failure a discriminated union tag. TypeScript will exhaustiveness-check your handlers.

```typescript
type CheckoutError =
  | { readonly code: "USER_NOT_FOUND"; readonly userId: string }
  | { readonly code: "CART_NOT_FOUND"; readonly userId: string }
  | { readonly code: "EMPTY_CART" }
  | { readonly code: "PAYMENT_FAILED"; readonly reason: string }
  | { readonly code: "FETCH_ERROR"; readonly message: string };
```

---

## Step 2: Lift each async operation into TaskEither

Each function wraps a throwing Promise with `TE.tryCatch`. The second argument maps the unknown exception to your typed error.

```typescript
import * as TE from "fp-ts/TaskEither";
import * as T from "fp-ts/Task";
import { pipe } from "fp-ts/function";

// Wrap fetch — network errors become FETCH_ERROR
const fetchUserTE = (userId: string): TE.TaskEither<CheckoutError, User> =>
  TE.tryCatch(
    async () => {
      const res = await fetch(`/api/users/${userId}`);
      if (!res.ok) throw { status: res.status };
      const user = (await res.json()) as User | null;
      if (!user) throw { code: "USER_NOT_FOUND" };
      return user;
    },
    (e): CheckoutError =>
      (e as any)?.code === "USER_NOT_FOUND"
        ? { code: "USER_NOT_FOUND", userId }
        : { code: "FETCH_ERROR", message: String(e) },
  );

const fetchCartTE = (userId: string): TE.TaskEither<CheckoutError, Cart> =>
  TE.tryCatch(
    async () => {
      const res = await fetch(`/api/carts/${userId}`);
      if (!res.ok) throw { status: res.status };
      const cart = (await res.json()) as Cart | null;
      if (!cart) throw { code: "CART_NOT_FOUND" };
      return cart;
    },
    (e): CheckoutError =>
      (e as any)?.code === "CART_NOT_FOUND"
        ? { code: "CART_NOT_FOUND", userId }
        : { code: "FETCH_ERROR", message: String(e) },
  );

const chargePaymentMethodTE = (
  paymentMethodId: string,
  amount: number,
): TE.TaskEither<CheckoutError, PaymentResult> =>
  TE.tryCatch(
    async () => {
      const res = await fetch("/api/payments/charge", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ paymentMethodId, amount }),
      });
      if (!res.ok) {
        const err = await res.json().catch(() => ({}));
        throw { reason: (err as any).message ?? "Payment declined" };
      }
      return res.json() as PaymentResult;
    },
    (e): CheckoutError => ({
      code: "PAYMENT_FAILED",
      reason: (e as any)?.reason ?? String(e),
    }),
  );
```

---

## Step 3: Compose with Do notation

`TE.Do` starts an accumulator context `{}`. Each `TE.bind` adds a named value to it; later binds can reference earlier ones. `TE.filterOrElse` validates mid-pipeline without breaking the chain.

```typescript
const checkout = (userId: string): TE.TaskEither<CheckoutError, Receipt> =>
  pipe(
    TE.Do,

    // Fetch user — result available as ctx.user downstream
    TE.bind("user", () => fetchUserTE(userId)),

    // Fetch cart — depends on user.id, so must be bind (not apS)
    TE.bind("cart", ({ user }) => fetchCartTE(user.id)),

    // Validate non-empty cart inline — short-circuits with EMPTY_CART if false
    TE.filterOrElse(
      ({ cart }) => cart.items.length > 0,
      (): CheckoutError => ({ code: "EMPTY_CART" }),
    ),

    // Charge the saved payment method
    TE.bind("payment", ({ user, cart }) =>
      chargePaymentMethodTE(user.savedPaymentMethodId, cart.total),
    ),

    // Map the final context to a Receipt — pure transformation, no TE needed
    TE.map(({ user, cart, payment }) => buildReceipt(user, cart, payment)),
  );
```

The return type `TE.TaskEither<CheckoutError, Receipt>` tells every caller exactly what can go wrong. No guessing.

---

## Step 4: Execute at the edge

The pipeline is lazy — nothing runs until you call it. At the HTTP handler or entry point, execute and pattern-match:

```typescript
// HTTP handler example
const handleCheckout = async (req: Request): Promise<Response> => {
  const userId = req.params.userId;

  const result = await pipe(
    checkout(userId),
    TE.fold(
      // Left branch — typed error, exhaustive match
      (err): T.Task<Response> => {
        switch (err.code) {
          case "USER_NOT_FOUND":
            return T.of(
              new Response(`User ${err.userId} not found`, { status: 404 }),
            );
          case "CART_NOT_FOUND":
            return T.of(new Response("Cart not found", { status: 404 }));
          case "EMPTY_CART":
            return T.of(new Response("Cart is empty", { status: 400 }));
          case "PAYMENT_FAILED":
            return T.of(
              new Response(`Payment failed: ${err.reason}`, { status: 402 }),
            );
          case "FETCH_ERROR":
            return T.of(new Response("Internal error", { status: 500 }));
        }
      },
      // Right branch — success
      (receipt): T.Task<Response> =>
        T.of(new Response(JSON.stringify(receipt), { status: 200 })),
    ),
  )();

  return result;
};
```

---

## Key patterns used and why

### `TE.tryCatch` — wrap any throwing async code

The second argument is the error mapper. It receives the unknown thrown value and converts it to your typed error. This is the only place you touch `unknown`.

### `TE.Do` + `TE.bind` — replace async/await sequencing

`bind` is the fp-ts equivalent of `const x = await ...`. It threads intermediate values through the pipeline without manual tuple construction.

### `TE.filterOrElse` — inline validation

Validates the accumulated context and short-circuits with a typed error if the predicate fails. No need to extract, check, and re-enter the chain.

### `TE.chainW` vs `TE.chain` — error union widening

If different steps can return different error types, use `chainW`. The `W` widens the accumulated error union so TypeScript tracks all possible failures:

```typescript
// If fetchCartTE returned CartError instead of CheckoutError:
pipe(
  fetchUserTE(userId), // TE<UserError, User>
  TE.chainW((user) => fetchCartTE(user.id)), // TE<UserError | CartError, Cart>
  TE.chainW((cart) => chargeTE(cart)), // TE<UserError | CartError | PaymentError, Receipt>
);
```

### `TE.fold` at the edge — exhaust both branches

`fold` forces you to handle both Left and Right. The discriminated union on `code` gives TypeScript enough information to enforce exhaustiveness with a `switch`.

---

## When to use `apS` vs `bind`

Use `TE.apS` for operations that do not depend on earlier bindings — they communicate parallelism intent:

```typescript
// If you also needed to fetch shipping config independently:
pipe(
  TE.Do,
  TE.bind("user", () => fetchUserTE(userId)),
  TE.apS("shippingConfig", fetchShippingConfig()), // independent — can run in parallel
  TE.bind("cart", ({ user }) => fetchCartTE(user.id)),
  // ...
);
```

Use `TE.bind` when the step needs a value from an earlier binding.
