Stitch prompts work best as one dense descriptive paragraph/list rather than a spec doc, so here's something sized to paste directly into its prompt box.

---

**Paste into Stitch:**

> Redesign a "Deployments" dashboard page (desktop web app, developer tool aesthetic — think Vercel/Netlify/Railway). Dark-mode-friendly, dense, monospace accents for technical values.
>
> **Header:** Page title "Deployments" with a subtitle showing the project/repo name. Optional filter/search bar (by branch, environment, status) aligned right.
>
> **List layout:** Replace the flat row list with a clean table or stacked-card list, one row per deployment, containing:
>
> - **Status badge** (pill, left-aligned): color-coded — green "Ready", blue/pulsing "Building", red "Error", gray "Canceled", yellow "Queued"
> - **Branch + commit**: branch name as a small tag/chip (e.g. `main`), commit message as primary text, short commit SHA (`9f3c1ab`) in monospace next to it
> - **Environment tag**: "Production" or "Preview" as a subtle badge, visually distinct (e.g. black/filled for production, outlined for preview)
> - **Author**: avatar or initials + username
> - **Timestamp**: relative time ("2h ago"), full date on hover
> - **Duration**: build time, e.g. "1m 24s", de-emphasized/secondary text
> - **Preview URL**: clickable link/icon that opens the deployment
> - **Actions**: overflow menu (⋯) containing "Visit", "Rollback", "View logs" — rollback should feel like a guarded/destructive action (confirmation on click, not a bare inline button)
>
> **States:** empty state when no deployments exist; skeleton/loading rows; hover state highlights the row and reveals actions.
>
> **Style:** compact row height, clear visual hierarchy (commit message > metadata), generous use of monospace for SHAs/durations, subtle dividers between rows, rounded status pills.

---

Current component only renders `id`, `status`, `branch`, `created_at` — the API already returns `commit_message`, `author`, `duration_ms`, `environment`, and `url` that aren't shown at all, so I folded those into the brief. Also moved Rollback off a bare inline button since it's a destructive action with no confirmation today.
