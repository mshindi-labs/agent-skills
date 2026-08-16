# Industry Benchmarks

Domain → the products worth copying → **the specific mechanic** to borrow.

Cite mechanics, never names. "Make it like Stripe" is unactionable; "right-aligned
tabular-figure amounts in 44px rows" is a design instruction.

Pick **two or three** benchmarks per page. More than three and the design has no
point of view.

---

## Universal mechanics

These hold across every domain below. Apply them by default; the domain sections
add on top.

- **Tabular figures for numbers.** Any column of numerals uses
  `font-variant-numeric: tabular-nums` so digits align vertically.
- **Restraint with colour.** Colour carries meaning (status, destructive, brand
  accent) and nothing else. Neutral greys do the structural work.
- **Weight and spacing over borders.** Hierarchy comes from type weight, size,
  and whitespace. Boxes-inside-boxes is the tell of a dated admin panel.
- **One primary action per screen.** Everything else is secondary or tertiary.
- **Empty states do work.** They explain what goes here and offer the action
  that fills it — never a shrug and a grey illustration.
- **Skeletons matching final layout**, not centred spinners. The page should not
  jump when data lands.
- **Optimistic feedback.** The UI responds on click, not on response.
- **Keyboard paths for repeated actions.** If a user does it fifty times a day,
  it needs a shortcut.
- **Dense by default, comfortable on demand.** Professional tools respect
  vertical space; consumer surfaces can breathe.

---

## Fintech, payments, banking

**Leaders:** Stripe, Mercury, Ramp, Wise

- **Stripe — the transaction table.** Right-aligned amounts in tabular figures,
  ~44px rows, status as a small coloured dot plus text label rather than a filled
  pill. Dense lists stay scannable because the eye tracks one column.
- **Stripe — object detail pages.** A summary header of key/value pairs above a
  chronological event timeline. Every ID is copyable and monospaced.
- **Mercury — money as typography.** Balances set large and light, currency
  symbol de-emphasised relative to the figure, cents smaller than dollars.
  Calm rather than loud.
- **Ramp — spend in context.** Every amount sits next to what it means: budget
  remaining, comparison to last period, the category. A number alone is noise.
- **Wise — fee transparency.** Costs broken out inline at the moment of the
  decision, never disclosed on a later screen.

**For a transactions or ledger page:** dense rows, one filter bar, amounts right-
aligned, status dots, inline row expansion instead of navigation, and a summary
strip above the table (total in, total out, pending).

---

## Work tracking, tickets, project management

**Leaders:** Linear, Height, Todoist

- **Linear — keyboard-first everything.** A command palette (`⌘K`) plus single-key
  actions on the focused row. The mouse is optional.
- **Linear — instant, optimistic mutations.** State changes apply immediately and
  reconcile in the background. No spinners on a status change, ever.
- **Linear — grouped lists over tables.** Items group under collapsible headers
  (status, assignee, cycle) with counts on the header, rather than a flat grid
  with a sort dropdown.
- **Linear — restrained status colour.** Status is a small icon or dot; priority
  is a glyph. Rows stay monochrome so the eye scans titles.
- **Height — inline editing.** Fields edit in place in the list. No modal for a
  one-field change.
- **Todoist — frictionless capture.** Creating an item is one keystroke and
  natural-language parsing, not a form.

**For a ticket or task list:** grouped collapsible sections with counts, single
keyboard-accessible row, inline status/assignee editing, a persistent filter bar
that reads as a sentence, and a detail panel that slides over rather than
navigating away.

---

## Developer tooling, infrastructure, deployments

**Leaders:** Vercel, Railway, Supabase, Planetscale

- **Vercel — status as the loudest element.** Deployment state (building, ready,
  error) is the first thing read, colour-coded, with elapsed time attached.
- **Vercel — monospace for machine data.** Commit SHAs, branch names, URLs, IDs
  all monospaced and copy-on-click.
- **Vercel — logs inline, not elsewhere.** Failure detail expands where the
  failure is reported.
- **Railway — the resource graph.** Relationships between services shown
  visually rather than as a list you must mentally join.
- **Supabase — progressive depth.** A clean surface with a "show SQL" / "show
  API call" escape hatch for users who want the underlying mechanism.
- **Planetscale — safe destructive actions.** Irreversible operations require
  typing the resource name, and say plainly what will break.

**For a deployments or builds page:** status-first rows, monospaced commit metadata,
duration and timestamp on every row, expandable failure logs, and a clear visual
distinction between the live production deploy and history.

---

## Analytics and dashboards

**Leaders:** PostHog, Amplitude, Datadog, Stripe Sigma

- **PostHog — the query is visible.** The controls that produced the chart sit
  above it and are editable in place.
- **Amplitude — comparison baked in.** Every metric shows its delta against the
  prior period. A bare number answers nothing.
- **Datadog — synchronised time range.** One global range control drives every
  panel; hovering one chart cross-hairs the rest.
- **Stripe Sigma — table over chart when the data is tabular.** Not everything
  wants to be a line graph.

**For a metrics page:** a global time-range control, KPI tiles carrying deltas
and sparklines, charts that share an x-axis and hover state, and a drill-down
from any tile into the underlying rows.

---

## Commerce and checkout

**Leaders:** Stripe Checkout, Shopify, Apple

- **Stripe Checkout — one column, one decision per step.** Total visible at all
  times, no surprises after the fold.
- **Shopify — inline validation.** Errors surface on blur, next to the field,
  and the submit button never lies about being ready.
- **Apple — product imagery does the persuading.** Generous whitespace, minimal
  chrome, price and CTA fixed within reach.

**For a cart or checkout:** persistent order summary, per-step totals,
field-level validation, and payment methods presented as recognisable marks.

---

## CRM, sales, records

**Leaders:** Attio, Folk, Pipedrive

- **Attio — every record is a spreadsheet and a page.** The same object edits
  inline in a grid or opens as a full record view.
- **Attio — relationships are first-class.** Linked records render as chips that
  navigate, not as foreign-key strings.
- **Folk — the activity timeline.** Chronological interaction history is the
  spine of the record page.
- **Pipedrive — pipeline as columns.** Stage progression is drag-and-drop with
  value totals per column.

---

## Inbox, messaging, support

**Leaders:** Superhuman, Front, Intercom

- **Superhuman — split pane, keyboard triage.** List left, content right,
  `j`/`k` navigation, single-key archive and snooze.
- **Superhuman — speed as a feature.** Every interaction under 100ms; nothing
  blocks on the network.
- **Front — assignment and internal notes inline.** Team context sits in the
  conversation, visually distinct from customer-facing content.
- **Intercom — composer with structure.** Attachments, macros, and templates
  reachable without leaving the reply box.

---

## Settings, account, admin

**Leaders:** Stripe, Vercel, Linear

- **Stripe/Vercel — one card per concern.** Each settings group is a bordered
  card with its own save action. No page-level save button holding twenty fields
  hostage.
- **Vercel — the danger zone.** Destructive settings isolated at the bottom, in
  a distinctly styled section, with typed confirmation.
- **Linear — settings that autosave.** Toggles apply immediately with a subtle
  confirmation; forms save on blur.
- **Stripe — descriptions under labels.** Every setting explains its consequence
  in one line of muted text.

---

## Auth and onboarding

**Leaders:** Clerk, Linear, Stripe

- **Clerk — social first, email second.** Provider buttons above the fold, email
  as the fallback, with a clear visual divider.
- **Linear — onboarding that produces state.** Each step creates something real
  rather than collecting answers for later.
- **Stripe — progress you can trust.** A step indicator that shows what remains
  and lets you return to completed steps.

---

## Generic product surfaces

Fallback when the domain does not match anything above. Draw on Linear, Vercel,
and Stripe as general-purpose references and lean on the universal mechanics.

- Establish a type scale (e.g. 12 / 14 / 16 / 20 / 30) and use exactly those sizes
- Establish a spacing rhythm (4px base, 8px increments) and use only multiples
- Two neutral greys for text (primary, muted), one accent, one destructive
- Content max-width around 1200px on wide screens; full-bleed only for tables
- Interactive elements have visible focus rings — always, not only on keyboard

---

## Maintaining this file

This is the one file in the skill that goes stale. Products get redesigned and
leaders change. Review it when a benchmark's UI visibly changes, and prefer
adding mechanics over adding names — the mechanics outlive the products.
