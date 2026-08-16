Written to `docs/redesign/transactions-redesign.md`. The paste-ready prompt is **Section 3** — copy just that fenced block into Claude Design, Stitch, v0, Lovable, or Figma Make.

Worth knowing before you use it:

- I flagged that the current code hardcodes `$` and ignores the `currency` field already in the payload — the redesign fixes that for free, no API change needed.
- `counterparty` and `payment_method` are in the response today but never rendered — the redesign surfaces them as a muted secondary line per row (Ramp-style), also free.
- I proposed exactly one additive API (`GET /api/transactions/summary`) for the total-in/total-out strip, because summing the current page would misreport a partial total as the account total — the design degrades to hiding that strip until you ship it.
- Row-click-to-navigate stays as the only interaction; I explicitly told the design tool not to swap it for inline expansion even though that's the more "Stripe" pattern, since that would be a behavior change, not a presentation one.

=== FILE: docs/redesign/transactions-redesign.md ===

# Redesign: Transactions Page

**Source:** `TransactionsPage` component (provided inline) · **Data:** `GET /api/transactions`
**Domain:** Fintech / billing · **Benchmarks:** Stripe, Mercury, Ramp

Presentation-only redesign. No logic, route, or existing API contract changes.

## 1. Current State

### Rendered content

| Element            | Data point (source field)          | Interaction | Effect                                                                   |
| ------------------ | ---------------------------------- | ----------- | ------------------------------------------------------------------------ |
| Date column        | `created_at`                       | none        | formatted via `toLocaleDateString()`                                     |
| Description column | `description`                      | none        | plain text                                                               |
| Amount column      | `amount_cents`                     | none        | divided by 100, formatted as `$X.XX` (hardcoded `$`, ignores `currency`) |
| Status column      | `status`                           | none        | text inside `badge-{status}` class                                       |
| Table row          | (whole transaction, keyed by `id`) | click       | `navigate(`/transactions/${t.id}`)`                                      |

### States handled today

- **Loading:** unstyled `<div className="spinner" />`
- **Empty:** plain `<p>No transactions.</p>`
- **Error:** plain `<div>Something went wrong</div>`, no retry action
- **Other:** none — no unauthorized, partial-data, or stale-data handling

### Derived in the component

- Date formatting: `new Date(created_at).toLocaleDateString()`
- Amount formatting: `(amount_cents / 100).toFixed(2)`, prefixed with a hardcoded `$` regardless of the transaction's actual `currency`

### In the response but not rendered

- `currency` — present per-transaction, but ignored in favor of a hardcoded `$`
- `counterparty.name`, `counterparty.id` — who the money moved with, not shown at all
- `payment_method` — how it was paid (e.g. `card_visa_4242`), not shown at all
- `has_more` — pagination signal exists in the payload; there is no pagination or "load more" control anywhere in the component

### Assessment

Bootstrap striped table with no visual hierarchy, no summary of what's on the page, and no use of half the payload — counterparty and payment method are paid for and thrown away, and currency is actively mis-rendered as a hardcoded `$`. There's no way to scan status at a glance (text-only badges), no responsive handling, and no feedback beyond a bare spinner and two plain-text state messages.

## 2. Benchmarks

**Stripe** — the transaction table: right-aligned amounts in tabular figures, ~44px rows, status as a small coloured dot plus label instead of a filled pill. This is a dense list of money movements; the eye needs to track one column (amount) and one glyph (status) without noise.

**Mercury** — money as typography: balances set large and light, currency symbol de-emphasised relative to the figure, cents smaller than the dollar amount. Applies to the new summary totals (see Section 4) — calm, confident numbers rather than a shouted dashboard stat.

**Ramp** — spend in context: an amount means little alone. Surfacing counterparty and payment method inline next to each row (currently fetched, never shown) gives every number a reason.

## 3. Generation Prompt

Paste this into Claude Design, Stitch, v0, Lovable, or Figma Make.

```text
Product and user: This is the transactions page of a billing/fintech dashboard. The user is a business owner or finance team member checking incoming and outgoing payments — reconciling invoices, spotting failed charges, confirming a customer paid.

Screen purpose: Let the user scan a list of transactions and quickly answer "what came in, what went out, and is anything wrong" — then click through to any transaction for detail.

Content inventory — render every one of these, using these as realistic example rows (a dense list, expect 20-50+ rows on a real account):

Row 1
- Date: March 14, 2026
- Description: "Acme Corp - invoice #4471"
- Amount: $2,480.00, currency USD
- Status: succeeded
- Counterparty: Acme Corp
- Payment method: Visa card ending 4242

Row 2 (illustrative — vary the state)
- Date: March 13, 2026
- Description: "Globex LLC - invoice #4470"
- Amount: $890.00, currency USD
- Status: pending
- Counterparty: Globex LLC
- Payment method: ACH bank transfer ending 8831

Row 3 (illustrative — vary the state)
- Date: March 12, 2026
- Description: "Initech - invoice #4469"
- Amount: $150.00, currency USD
- Status: failed
- Counterparty: Initech
- Payment method: Mastercard ending 0192

Every row has: a date, a free-text description, a monetary amount tied to a currency, a status (succeeded / pending / failed are the known values — design the status treatment so an unfamiliar status word still renders sensibly, e.g. "refunded"), a counterparty name, and a payment method. Clicking anywhere on a row is the only per-row action, and it always navigates to that transaction's own detail page — do not replace this with inline expansion or a modal, and do not add row-level actions (menus, buttons, checkboxes) that don't exist today.

Layout and hierarchy: A single dense table/list is the primary content, full width, no card-in-a-card nesting. Above it, a slim summary strip showing total in, total out, and pending count for the currently visible set (see states below for how this behaves before real aggregate data exists). Below or beside the summary, one filter/search affordance is acceptable to imply visually (e.g. a search-by-description input) but do not wire up new filter logic — it's a static element in this pass, not a new feature.

Design direction: Dense rows, around 44px tall, 16px horizontal padding. Amount column right-aligned with tabular (monospaced-width) figures — negative/outgoing amounts in the normal text color, not red; red is reserved only for a "failed" status indicator. Status renders as a small 6-8px colored dot plus a short label (green=succeeded, amber=pending, red=failed, grey=any other/unknown value) — never a filled pill or colored badge background. Counterparty name and payment method (e.g. "Visa •••• 4242") appear as a secondary, muted line under or beside the description — smaller type, lower-contrast grey. Summary strip totals are set large and light in weight, currency symbol small and de-emphasised relative to the digits, cents rendered smaller than the whole-dollar amount. Type scale: 12/14/16/20/30. Spacing on an 8px rhythm. Two greys for text (primary near-black, muted mid-grey), one accent color for links/focus, red reserved for destructive/failed only. Flat design — hierarchy from weight, size and whitespace, not boxes and borders. Every interactive element (rows, any control) has a visible focus ring.

States to design:
- Loading: a skeleton matching the final row layout (shimmering placeholder bars for date/description/amount/status columns) — not a centered spinner.
- Empty: no transactions yet — friendly message plus, if relevant, a pointer to what creates a transaction (no invented action beyond what a static empty state can say).
- Error: a clear inline message with a retry affordance, visually distinct from the empty state (this is a fetch failure, not "no data").
- Dense/overflowing: design for 50+ rows — the table should stay scannable at that density, with the summary strip staying pinned/visible near the top.
- Summary strip before real aggregate data exists: since the current page of transactions is paginated, do not silently sum only the visible rows and label it as a total — either omit the summary strip in this state, or clearly scope it as reflecting only the loaded rows.

Responsive: Desktop shows the full table with all columns. Tablet condenses counterparty/payment method into the secondary muted line under description (already the design above) rather than a separate column, so no column needs to be dropped. Mobile collapses each row into a two-line stacked card: date + status on one line, description/counterparty and right-aligned amount on the next — still tappable as a full row.

Render every item in the content inventory. Do not invent data points beyond it, and do not remove any of them. Do not add features, filters, or actions that are not listed. This is a visual redesign of an existing screen — the behaviour is fixed, only the presentation changes.
```

## 4. Proposed API Additions

### Aggregate summary totals (total in, total out, pending count)

**Why:** The Stripe/Ramp-style summary strip above the table needs a trustworthy total across _all_ transactions, not just the current page. The list endpoint is paginated (`has_more`), so summing the loaded rows client-side would silently mislabel a partial sum as the account total.

**Endpoint:** `GET /api/transactions/summary` _(new)_

**Response:**

```json
{
  "total_in_cents": 1245000,
  "total_out_cents": 892000,
  "pending_count": 3,
  "currency": "USD"
}
```

**Non-breaking:** new endpoint — no existing consumer affected.

**Degrades to:** the summary strip is omitted entirely until this ships. It is never computed from the paginated `transactions` array, since that would show an inaccurate partial total.

## 5. Behavioural Invariants

Must still hold after the redesign ships:

- [ ] Clicking a row still navigates to `/transactions/:id`
- [ ] Loading state still shows while the query is in flight
- [ ] Error state still shows on fetch failure, distinct from the empty state
- [ ] Empty state still shows when `transactions` is an empty array
- [ ] Amounts still derive from `amount_cents / 100`, displayed in the transaction's own `currency` (not a hardcoded `$`)
- [ ] Status label still reflects the raw `status` field value, including values not covered by the illustrative examples above
- [ ] No new filters, row actions, or pagination controls are wired to real logic — this pass is presentation only
