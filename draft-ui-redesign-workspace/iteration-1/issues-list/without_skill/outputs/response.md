The sandbox is empty — this is just the snippet you pasted, so the prompt below is grounded in that alone (no existing design tokens to reference). I also noticed a Stitch (Google's AI design tool) integration is connected in this session — happy to run the prompt through it directly if you want an actual mockup instead of just the text, just say so.

Here's the prompt, written so a design tool can't accidentally invent new features while making it look good:

```
Redesign the visual design of an "Issues List" screen. This is a pure visual/UX polish pass — the underlying behavior, data, and interactions must not change in any way.

CONTEXT
Internal issue tracker, list view. Currently functional but visually flat and slow-feeling — plain HTML list, no hierarchy, no color, no density control. Target feel: Linear's issue list — dense, fast to scan, quiet color use, confident typography.

BEHAVIOR THAT MUST STAY EXACTLY AS-IS (do not add, remove, or restyle-into-a-new-interaction):
- One filter control with exactly three states: All / Open / Closed. Single-select. No multi-select, no additional filter fields, no search box, no sort control.
- Clicking anywhere on a row navigates to that issue's detail page. The whole row is the click target — no separate buttons, checkboxes, or menus per row.
- One list, no pagination, no infinite scroll, no kanban/board toggle, no grouping. Assume the API already returns the right set of rows for the active filter.
- No new client-side state (no saved views, no remembered sort, no column customization).

DATA AVAILABLE PER ROW (style what's useful, don't invent fields):
- id — short code, e.g. "ISS-142"
- title — string
- status — "open" | "closed"
- priority — integer (confirm the actual min/max range from the API before picking an icon set; don't hardcode assuming a specific scale)
- assignee — { name, avatar_url } or null → show avatar + name, or "Unassigned" when null
- labels — string[], can be empty
- updated_at — ISO timestamp → show as relative time ("2h ago")
- comment_count — integer → only show when > 0

Currently only title, status (as raw text), and assignee name are displayed. Priority, avatar, labels, updated_at, and comment_count are already returned by the API but unused — surfacing them is a visual improvement, not a behavior change, since no new interaction is attached to them (they're read-only display, same as title/status/assignee are today).

DESIGN DIRECTION
- Dense, scannable rows: title as primary text, everything else as secondary/muted metadata aligned to the right or in a metadata row.
- Status as a small colored dot/icon instead of raw text.
- Priority as a compact icon, not a number.
- Labels as small low-contrast pills, wrapping gracefully if there are several.
- Avatar as a small circle (initials fallback if avatar_url fails to load).
- Subtle row hover state to reinforce that rows are clickable.
- Style the filter control as a segmented control or clean dropdown — same three options, no new ones.
- Handle empty state (filter matches nothing) and the brief moment before data arrives, gracefully — these situations already occur today, just unstyled. Don't design elaborate skeleton/optimistic-UI beyond a simple loading treatment.

OUT OF SCOPE — do not include: search, sorting, bulk actions, multi-select, kanban/board view, new filter types, pagination controls, keyboard shortcuts. If any of these feel tempting, flag them separately as "future idea," not part of this deliverable.
```

Skipped: writing this from a real design system (none exists in the sandbox) — if you have one, tell me and I'll fold in actual tokens/colors instead of leaving that to the tool's judgment.
