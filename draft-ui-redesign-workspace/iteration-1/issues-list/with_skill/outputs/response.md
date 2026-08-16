Written to `docs/redesign/issues-list-redesign.md`. Paste **Section 3** into your design tool — it's self-contained.

Quick summary of what it says:

- **Domain/benchmark:** work tracking, benchmarking against Linear — grouped status sections with counts, restrained status-dot colour, and keyboard row navigation (scoped to the one action this screen has: opening an issue).
- **Cheapest win:** `priority`, `labels`, `updated_at`, `comment_count`, `assignee.avatar_url`, and `id` are already in the API response but never rendered today — the redesign surfaces all of them with zero API changes.
- **One API addition, capped well under the limit of 3:** an optional `counts` field on the existing `/api/issues` response so grouped headers can show "Open (34)" — degrades to plain headers with no count until it ships.
- **Invariants:** filter still drives the same query param, row click/keyboard-enter still does the same `router.push`, unassigned still reads "Unassigned" — nothing about behavior changes.

=== FILE: docs/redesign/issues-list-redesign.md ===

# Redesign: Issues List

**Source:** `IssuesList` component (pasted inline) · **Data:** `GET /api/issues?status=`
**Domain:** work tracking · **Benchmarks:** Linear

Presentation-only redesign. No logic, route, or existing API contract changes.

## 1. Current State

### Rendered content

| Element               | Data point (source field)                                                 | Interaction                         | Effect                                               |
| --------------------- | ------------------------------------------------------------------------- | ----------------------------------- | ---------------------------------------------------- |
| Page heading          | static text "Issues"                                                      | none                                | none                                                 |
| Status select         | local `status` state                                                      | `onChange` sets `status`            | re-triggers `useSWR` with new `?status=` query param |
| Issue row title       | `issues[].title`                                                          | click anywhere on `<li>`            | `router.push('/issues/:id')` using `issues[].id`     |
| Issue row status text | `issues[].status`                                                         | none (row click covers it)          | same as above                                        |
| Issue row assignee    | `issues[].assignee.name`, fallback `'Unassigned'` when `assignee` is null | none (row click covers it)          | same as above                                        |
| Row key               | `issues[].id`                                                             | n/a (React key only, not displayed) | n/a                                                  |

### States handled today

- **Loading:** not handled — `data` is `undefined` until the fetch resolves, so the list is just empty with no indicator.
- **Empty:** not handled — an empty `issues` array renders an empty `<ul>` with no message.
- **Error:** not handled — `useSWR`'s `error` value isn't read; a failed fetch looks identical to a loading or empty state.
- **Other:** none (no unauthorized/partial/stale handling).

Note: `useSWR` already exposes `isLoading` and `error` — wiring loading/empty/error states into the redesign is a presentation change only, it doesn't require any new data or API work.

### Derived in the component

- `assignee?.name ?? 'Unassigned'` — fallback display string when `assignee` is `null`.

### In the response but not rendered

- `priority` (integer, e.g. `2`)
- `labels` (string array, e.g. `["bug", "webhooks"]`)
- `updated_at` (ISO timestamp)
- `comment_count` (integer)
- `assignee.avatar_url`
- `id` (used for navigation, never shown as text)

Six fields are already being paid for and thrown away — this is the cheapest lever in this redesign.

### Assessment

The list is a bare `<ul>` with no visual hierarchy: title, status, and assignee run together as plain inline text with no spacing, colour, or alignment system, so a long list is hard to scan. Six fetched fields (priority, labels, freshness, comment count, avatar, id) never reach the screen, leaving the page far sparser than the data backing it. There's also no loading, empty, or error state, so a slow network or a filter with zero matches both look identical to a blank page.

## 2. Benchmarks

**Linear** — grouped, collapsible lists with a count in each group header, instead of a flat unstyled `<ul>`. When the status filter is "All", group rows under "Open" and "Closed" headers so the eye doesn't have to hunt through a mixed list; the "Open"/"Closed" filter options continue to work exactly as today, just pre-selecting a group.

**Linear** — restrained status colour: a small coloured dot plus label for `status`, and a compact glyph/level indicator for `priority`, instead of bare text and an unrendered number. Colour is reserved for status and priority only, so the rest of the row stays monochrome and titles stay the most scannable thing on the page.

**Linear** — keyboard-first navigation, scoped to this screen's one action: arrow keys move focus between rows and Enter opens the focused issue. This is not a new capability, it's a second path to the exact `router.push('/issues/:id')` call the row click already triggers.

## 3. Generation Prompt

Paste this into Claude Design, Stitch, v0, Lovable, or Figma Make.

```text
Product and user: This is an internal issue tracker, similar in spirit to Linear. The user is a software engineer or product manager triaging and scanning a list of work items several times a day.

Screen purpose: This screen's single job is letting the user scan a filtered list of issues and open the one they care about. Nothing on this screen edits data — opening an issue is the only action.

Content inventory — render every item below, using these as realistic example values:

Filter control: a three-way filter (All / Open / Closed). Currently selected value is one of "all", "open", "closed".

Each row in the list represents one issue with these fields:
- id: a short code like "ISS-142" (currently not displayed at all — show it, e.g. as small muted text near the title, monospaced)
- title: a sentence, e.g. "Webhook retries drop the idempotency key"
- status: one of "open" or "closed"
- priority: a small integer, e.g. 2 (no fixed label set is defined — render it as a compact ordinal indicator such as stacked bars or a two-character badge like "P2"; do not invent a named scale like "Urgent/High/Medium/Low" since that mapping isn't provided)
- assignee: either a person with a name (e.g. "Priya Raman") and an avatar image URL, or absent, in which case show the literal text "Unassigned" with a neutral placeholder avatar
- labels: zero or more short tags, e.g. ["bug", "webhooks"]
- updated_at: an ISO timestamp, e.g. "2026-03-12T16:04:00Z" — render as a relative time like "5mo ago"
- comment_count: an integer, e.g. 7 — render with a small comment/bubble icon next to the count; omit the icon entirely when the count is 0

Layout and hierarchy: A filter control sits above the list. Below it, when the filter is "All", group rows under two collapsible section headers, "Open" and "Closed", each showing a count of issues in that group (e.g. "Open (34)"). When the filter is "Open" or "Closed", show a single flat list with no group header since it's already filtered. Within a row, the title is the dominant element (largest weight); status, priority, assignee, labels, comment count, and relative time are all secondary and sit in a single-line row layout, right-aligned metadata after the title.

Design direction: Dense rows, around 40-44px tall, generous horizontal padding, no boxes-inside-boxes or heavy borders — use whitespace and type weight for hierarchy, not cards. A 12/14/16/20/30 type scale and a 4px spacing rhythm (multiples of 4/8) throughout. Status renders as a small coloured dot plus label (green-ish for open, muted grey for closed) — colour is reserved for status and priority only, everything else stays neutral grey/black so titles stay the most scannable element. Labels render as small neutral pill-less tags (text with a faint background, not bright filled pills). Rows are keyboard-navigable: arrow keys move a focus highlight between rows, Enter opens the focused row — this mirrors the existing click-to-open behavior, it does not add any new action.

States: Design a loading state that shows skeleton rows matching the final row layout (not a centered spinner), an empty state for when a filter matches zero issues (explain there are no issues in this view, no illustration), an error state for a failed fetch (short message, no stack trace), and a dense/overflowing case showing how a list of 50+ issues with long titles and multiple labels stays readable.

Responsive: On desktop, show the full row layout described above. On tablet, keep all fields but tighten horizontal spacing. On mobile, stack each row into two lines — title on the first line, status/priority/assignee/labels/comment count/time wrapping onto a second line — while keeping every field visible, none hidden behind a menu.

Render every item in the content inventory. Do not invent data points beyond it, and do not remove any of them. Do not add features, filters, or actions that are not listed. This is a visual redesign of an existing screen — the behaviour is fixed, only the presentation changes.
```

## 4. Proposed API Additions

### Status group counts

**Why:** The Linear-style grouped view (section 2) shows a count per status group — "Open (34)", "Closed (94)" — even when the current filter only returns one status's worth of issues. The existing endpoint only returns the subset matching the active filter, so counts for the other group aren't available today.

**Extends:** `GET /api/issues?status=` — adds optional field `counts`

**Response:**

```json
{
  "issues": ["...unchanged..."],
  "counts": { "all": 128, "open": 34, "closed": 94 }
}
```

**Non-breaking:** new optional field — existing consumers that only read `issues` are unaffected.

**Degrades to:** group headers render with no count ("Open", "Closed") until this field is present.

## 5. Behavioural Invariants

Must still hold after the redesign ships:

- [ ] Changing the filter control still calls `useSWR` with `/api/issues?status=all|open|closed` and re-fetches
- [ ] Clicking (or keyboard-selecting) an issue row still calls `router.push('/issues/:id')` with that issue's `id`
- [ ] An issue with no assignee still displays the literal text "Unassigned"
- [ ] An empty `issues` array still renders a distinct empty state, not a broken or blank layout
- [ ] A fetch error still renders a distinct error state, not a silent blank list
- [ ] No field is read from anywhere other than the current `GET /api/issues?status=` response (plus the optional `counts` addition above)
