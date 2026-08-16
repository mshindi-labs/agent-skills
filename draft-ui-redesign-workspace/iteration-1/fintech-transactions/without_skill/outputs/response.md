Used the frontend-design skill's brainstorm pass to ground this in what the page actually is — a payments ledger for a B2B billing tool — rather than a generic dashboard template. Copy the block below into whatever tool you're using (v0, Lovable, Figma Make, Stitch, etc.):

```
Redesign a "Transactions" table for a B2B fintech billing dashboard. Audience:
finance/ops people reconciling customer payments — they scan for status and
amount fast, then drill into one row. Trust and precision matter more than
flash; this is a ledger, not a marketing page.

DATA (per row):
- date (ISO timestamp → display as "Mar 14, 2026")
- description (e.g. "Acme Corp - invoice #4471")
- counterparty name
- amount_cents → format as currency using the currency field (USD → $2,480.00)
- status: succeeded | pending | failed | refunded
- payment_method (e.g. "card_visa_4242" → show as "Visa •••• 4242")
List is paginated (cursor-based "load more", not numbered pages).

STATES TO DESIGN: populated table, loading (skeleton rows, not a spinner),
empty ("No transactions yet." + one sentence on when they'll appear), error
(plain-language retry, no stack traces).

VISUAL DIRECTION:
Color — cool-neutral base, not warm/cream: background #F7F8FA, surface #FFFFFF,
hairline border #E4E7EC, primary text #14181F, secondary text #5B6472, accent
#2447F5 (cobalt, used only for interactive/focus). Status as tinted dot + label,
not loud badges: succeeded #0E9F6E on #E9FBF3, pending #D97706 on #FEF6E7,
failed #DC2626 on #FDECEC, refunded #6B7280 on #F1F2F4.

Type — pair a grotesk sans (Inter or General Sans) for UI chrome, labels, and
filters with a monospace (IBM Plex Mono) set to tabular-nums for every number:
dates, amounts, transaction IDs. The mono numerals are the signature move —
they read as a ledger, not an admin CRUD table.

Layout — sticky header row, hairline dividers between rows instead of card
shadows, amount column right-aligned in mono, generous row height (48-56px)
for scannability, row hover state that reveals an affordance the row is
clickable (chevron, not just a background tint). Filter bar above the table:
search by description/counterparty, status filter, date range. "Load more"
button at the bottom, not pagination numbers.

Wireframe:
┌─────────────────────────────────────────────────────────┐
│ Transactions                                             │
│ [Search description or customer]  [Status ▾] [Date ▾]    │
│ ────────────────────────────────────────────────────────│
│ DATE       DESCRIPTION              STATUS      AMOUNT   │
│ ────────────────────────────────────────────────────────│
│ Mar 14     Acme Corp — inv #4471    ● Succeeded $2,480.00│
│ Mar 13     Globex — inv #4470       ● Pending     $860.00│
│ ────────────────────────────────────────────────────────│
│                      Load more                           │
└─────────────────────────────────────────────────────────┘

Constraints: keyboard-focusable rows with visible focus ring, WCAG AA contrast
on status colors, respects prefers-reduced-motion, responsive down to a
mobile card-stack layout (date/status/amount as a compact meta line under
the description).
```

Skipped: an actual code implementation — you asked for a design-tool prompt, not the redesigned component. Say the word if you want the React/Tailwind version once you've settled on a look.
