# Output Document Template

Write to `docs/redesign/<page>-redesign.md`. Five sections, in this order.

---

## Template

````markdown
# Redesign: <Page Name>

**Source:** `<path/to/page>` · **Data:** `<endpoint or handler path>`
**Domain:** <inferred domain> · **Benchmarks:** <product>, <product>

Presentation-only redesign. No logic, route, or existing API contract changes.

## 1. Current State

### Rendered content

| Element | Data point (source field) | Interaction | Effect |
| ------- | ------------------------- | ----------- | ------ |
| ...     | ...                       | ...         | ...    |

### States handled today

- **Loading:** ...
- **Empty:** ...
- **Error:** ...
- **Other:** ... (unauthorized, partial, stale)

### Derived in the component

- ... (values computed client-side rather than returned by the API)

### In the response but not rendered

- ... (data already paid for and thrown away — cheapest possible win)

### Assessment

Two or three sentences. What specifically fails here — density, hierarchy,
scannability, state handling, hierarchy of actions. Name the problem, not a
verdict.

## 2. Benchmarks

**<Product>** — <the specific mechanic>. <Why it fits this page.>

**<Product>** — <the specific mechanic>. <Why it fits this page.>

## 3. Generation Prompt

Paste this into Claude Design, Stitch, v0, Lovable, or Figma Make.

```text
<the self-contained prompt — see structure below>
```

## 4. Proposed API Additions

<Per the additive-API format below. If none, write: "No API changes required —
the redesign renders entirely from the current response.">

## 5. Behavioural Invariants

Must still hold after the redesign ships:

- [ ] ...
````

---

## The prompt block (section 3)

The only section that leaves this repo. It lands in a tool with **no access to
the codebase and no memory of this conversation**. It may not reference "the
table above", file paths, or field names without saying what they contain.

Structure it in this order:

1. **Product and user** — one or two sentences. Who uses this and what they are
   trying to get done.
2. **Screen purpose** — the single job this screen exists to do.
3. **Content inventory** — every item from the audit, with realistic example
   values. This is the longest part and the most important. Group it as it should
   appear.
4. **Layout and hierarchy** — what dominates, what recedes, what the reading
   order is.
5. **Design direction** — type scale, spacing rhythm, density, colour usage,
   border and elevation treatment, borrowed mechanics named concretely.
6. **States** — loading, empty, error, and the dense/overflowing case.
7. **Responsive** — behaviour at desktop, tablet, mobile.
8. **Constraints** — the closing paragraph, always:

> Render every item in the content inventory. Do not invent data points beyond
> it, and do not remove any of them. Do not add features, filters, or actions
> that are not listed. This is a visual redesign of an existing screen — the
> behaviour is fixed, only the presentation changes.

Write it as prose and lists addressed to a designer. Not JSON, not component
code, not markdown headings inside the fenced block (they collide with the
document's own structure — use plain labelled lines).

### Register

> Bad: "Modern, clean, professional dashboard with a nice table."
>
> Good: "A dense transaction ledger. Rows are 44px with 16px horizontal padding.
> The amount column is right-aligned in tabular figures, negative values in the
> neutral text colour rather than red — red is reserved for failed status.
> Status renders as a 6px dot plus label, not a filled pill."

Adjectives are unactionable. Measurements, alignments, and named mechanics are.

---

## Additive API format

One block per addition, maximum three.

````markdown
### <What it provides>

**Why:** <the design element that needs it, and what the screen shows without it>

**Endpoint:** `GET /api/<path>` _(new)_
— or —
**Extends:** `GET /api/<existing>` — adds optional field `<name>`

**Response:**

```json
{
  "...": "..."
}
```

**Non-breaking:** <new endpoint — no existing consumer affected> — or —
<new optional field — existing consumers ignore it; absent field means the
component renders X instead>

**Degrades to:** <what the redesign shows before this ships>
````

Rules:

- New endpoint, or new **optional** field. Never change the type, meaning,
  nullability, or presence of an existing field. Never remove one.
- Every addition needs a **Degrades to** line. If the design breaks without the
  field, the design is wrong — fix the design, not the API.
- If a value is computable from data already in the response, it is not an API
  addition. Note the derivation in section 1 instead.
- Three is the cap. Beyond that, write "further data would require product
  changes beyond this page" and stop.

---

## Behavioural invariants (section 5)

A checklist a reviewer can walk after the redesign ships. Derive it mechanically
from the audit — every interaction row becomes an invariant, plus every state.

```markdown
- [ ] Clicking a row still navigates to `/transactions/:id`
- [ ] The status filter still persists to the `?status=` query param
- [ ] Empty state still shows when the array is empty, distinct from the error state
- [ ] Amounts still display in the account's currency, not a hardcoded symbol
```

Specific and checkable. "Looks good" is not an invariant.
