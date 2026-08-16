Written to `docs/redesign/deployments-redesign.md`. Paste **Section 3** into Stitch — it's self-contained.

Quick summary of what the audit found: the current page only renders 4 of 10 API fields (skips commit SHA, message, author, duration, environment, URL) and handles no loading/empty/error states. The redesign borrows Vercel's status-first + monospace treatment, Planetscale's confirm-before-destructive pattern for Rollback, and Supabase's progressive-depth row (dense by default, expand for detail). Two additive, optional API pieces are proposed — an `error_summary` field and a logs endpoint — both with explicit degrade-to-today behavior so the design still works before either ships.

=== FILE: docs/redesign/deployments-redesign.md ===

# Redesign: Deployments

**Source:** `Deployments` component (renders `deployments` prop) · **Data:** `GET /api/deployments`
**Domain:** Developer tooling / infrastructure · **Benchmarks:** Vercel, Planetscale, Supabase

Presentation-only redesign. No logic, route, or existing API contract changes.

## 1. Current State

### Rendered content

| Element         | Data point (source field)                  | Interaction | Effect                                    |
| --------------- | ------------------------------------------ | ----------- | ----------------------------------------- |
| ID text         | `id` (e.g. `dpl_7Kq2`)                     | none        | display only                              |
| Status text     | `status` (e.g. `ready`)                    | none        | display only, plain text, no color coding |
| Branch text     | `branch` (e.g. `main`)                     | none        | display only                              |
| Timestamp text  | `created_at` (e.g. `2026-03-14T11:02:44Z`) | none        | display only, raw ISO string, unformatted |
| Rollback button | —                                          | `onClick`   | calls `rollback(d.id)`                    |

### States handled today

- **Loading:** not handled — no loading state in the component
- **Empty:** not handled — an empty `deployments` array renders an empty list with just the `<h1>`
- **Error:** not handled — no error state
- **Other:** no unauthorized or partial/stale-data handling

### Derived in the component

- None — every rendered value is passed through from the API field as-is

### In the response but not rendered

- `commit_sha` — short commit hash
- `commit_message` — commit message for the deploy
- `author` — who triggered the deployment
- `duration_ms` — build duration
- `environment` — e.g. `production`, `preview`
- `url` — live URL for that deployment

Six of ten response fields are paid for and thrown away — the single cheapest improvement here is simply rendering what's already returned.

### Assessment

The page is a flat, unstyled list of `<span>` tags with no visual hierarchy, no status color-coding, and no formatting — a raw ISO timestamp and a bare status word carry the same weight as everything else. Over half the API response (commit info, author, duration, environment, URL) is fetched but never shown, so the page under-serves the data it already has before any redesign work even begins. There's also no loading, empty, or error handling, so those states need to be designed from scratch, not just restyled.

## 2. Benchmarks

**Vercel** — status as the loudest element (color-coded, first thing read, with elapsed time attached) plus monospace, copy-on-click treatment for commit SHAs and URLs. This page's core content — status, branch, commit — is exactly what Vercel's deployment list optimizes for.

**Planetscale** — safe destructive actions: irreversible operations require typing the resource name and state plainly what will change. `Rollback` here fires immediately on click with no confirmation; it's exactly the kind of action this mechanic protects.

**Supabase** — progressive depth: a clean row by default with a "show more" escape hatch. Lets the row stay dense (id, status, branch, time) while commit message, author, duration, environment, and URL live behind an inline expand instead of cluttering every row.

## 3. Generation Prompt

Paste this into Stitch.

```text
Product and user: This is the deployments page of a developer platform (in the spirit of Vercel or Railway). The user is a software engineer checking whether their latest deploy succeeded, comparing it to recent history, and occasionally rolling back to a previous deployment.

Screen purpose: A single job — let the engineer see the status of every deployment at a glance, and roll back safely if something is wrong.

Content inventory — every deployment row has these fields, all already available today:
- Deployment ID: a short identifier like "dpl_7Kq2"
- Status: one of "ready", "building", or "error"
- Branch: the git branch, e.g. "main"
- Commit SHA: a short hash, e.g. "9f3c1ab"
- Commit message: e.g. "fix: handle null region in edge config"
- Author: the username who triggered the deploy, e.g. "bmulumia"
- Created at: an ISO timestamp, e.g. "2026-03-14T11:02:44Z" — format this as a relative or readable time
- Duration: milliseconds, e.g. 84200 — format this as "1m 24s"
- Environment: "production" or "preview"
- URL: the live deployment URL, e.g. "https://app-9f3c1ab.example.dev"
- A Rollback action per row

Design for at least three example rows with different statuses so the states are visible: one "ready" deployment on main/production, one "building" deployment on a preview branch with no duration yet, and one "error" deployment on a feature branch.

Layout and hierarchy: A dense, single list of deployment rows, most recent first. Status is the first thing the eye should read on each row — it dominates over the ID or branch. Branch, commit message, and author are secondary. Commit SHA, deployment ID, and URL are tertiary, tertiary-styled, monospaced.

Design direction: Borrow Vercel's mechanic of making status the loudest element — a colored dot or label plus elapsed/duration time sits first in the row, color-coded (e.g. green for ready, blue/pulsing for building, red for error). Commit SHAs, deployment IDs, and URLs render in a monospace font and are copyable on click, again following Vercel's treatment of machine-readable data. Each row stays collapsed and dense by default — id, status, branch, and time only — and expands inline to reveal commit message, author, duration, environment, and URL, following Supabase's progressive-depth pattern, rather than cramming all ten fields into every row. Use a restrained palette: neutral grays for structure and text, color reserved for status only. Tabular figures for any numeric/time values so they align in a column. Establish a type scale (e.g. 12/14/16/20/30) and 8px spacing rhythm rather than boxed borders between rows.

Rollback action: Follow Planetscale's safe-destructive-action mechanic. Clicking Rollback does not fire immediately — it opens a confirmation step that states plainly which deployment will become live and requires an explicit confirm action before proceeding.

States: Design a loading state that skeletons the row layout (status dot, branch, time placeholders) rather than a centered spinner. Design an empty state for when there are no deployments yet, explaining what a deployment is and how to trigger the first one. Design an error state for when the deployment list itself fails to load, distinct from a row showing status "error". Also design the dense case — at least 15-20 rows — to confirm the list stays scannable at that length.

Responsive: On desktop, show the full row (status, branch, commit, author, time) inline. On tablet, secondary fields may wrap to a second line within the row. On mobile, collapse each row to status, branch, and time, with everything else behind the expand.

Render every item in the content inventory. Do not invent data points beyond it, and do not remove any of them. Do not add features, filters, or actions that are not listed. This is a visual redesign of an existing screen — the behaviour is fixed, only the presentation changes.
```

## 4. Proposed API Additions

### Inline failure reason on error rows

**Why:** Vercel's status-first mechanic surfaces _why_ a deployment failed right on the row, not just that it failed. Today `status: "error"` carries no explanation, so an error row can only say "error" with no detail — the design's expand-to-detail affordance has nothing to show for a failure.

**Extends:** `GET /api/deployments` — adds optional field `error_summary`

**Response:**

```json
{
  "deployments": [
    {
      "id": "dpl_9Ff1",
      "status": "error",
      "branch": "feature/edge-cache",
      "commit_sha": "1a2b3c4",
      "commit_message": "wip: edge cache invalidation",
      "author": "bmulumia",
      "created_at": "2026-03-14T09:11:02Z",
      "duration_ms": 12400,
      "environment": "preview",
      "url": null,
      "error_summary": "Build failed: module not found './edgeConfig'"
    }
  ]
}
```

**Non-breaking:** new optional field — existing consumers ignore it; absent field means the component renders the status label alone, with no inline reason.

**Degrades to:** the expanded row shows status only, no failure detail, exactly as today.

### Build/deploy logs

**Why:** Supabase's progressive-depth mechanic and Vercel's inline-logs mechanic both point to letting the user drill from a failure straight into the raw build output, without leaving the page. No log content exists in the current response.

**Endpoint:** `GET /api/deployments/:id/logs` _(new)_

**Response:**

```json
{
  "lines": [
    {
      "timestamp": "2026-03-14T09:10:58Z",
      "text": "Installing dependencies..."
    },
    {
      "timestamp": "2026-03-14T09:11:02Z",
      "text": "Error: module not found './edgeConfig'"
    }
  ]
}
```

**Non-breaking:** new endpoint — no existing consumer affected.

**Degrades to:** the row's expand view omits the "View logs" affordance entirely and shows only the fields already in the deployments response (plus `error_summary` above, once shipped).

## 5. Behavioural Invariants

Must still hold after the redesign ships:

- [ ] Clicking Rollback still calls `rollback(d.id)` with the same deployment id, only gated behind a confirmation step
- [ ] Every deployment in the `deployments` array still renders as a row — none are hidden or paginated away by default
- [ ] `status`, `branch`, and `created_at` still render for every row, unchanged in meaning
- [ ] Empty `deployments` array still shows an empty state, distinct from an error state
- [ ] All ten current response fields (`id`, `status`, `branch`, `commit_sha`, `commit_message`, `author`, `created_at`, `duration_ms`, `environment`, `url`) remain visible somewhere on the row (collapsed or expanded), none dropped
