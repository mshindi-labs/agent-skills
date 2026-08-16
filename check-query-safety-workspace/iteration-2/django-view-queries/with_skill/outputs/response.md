Now I'll apply the skill's review steps to the provided code.

**Step 1 — ORM detection:** Django ORM (`objects.filter`, `objects.all`) plus raw SQL via `connection.cursor()`.

---

```
Query safety review: Django view/data-access module
──────────────────────────────────────────────────

SQL injection risks (1)
1. [high] f-string interpolation in raw query — search_users, line 3 of that function
   cursor.execute(f"SELECT id, name FROM users WHERE name LIKE '%{term}%'")
   Input source: request.GET.get("q") — direct user-controlled query parameter, no sanitization
   Fix:
     cursor.execute("SELECT id, name FROM users WHERE name LIKE %s", [f"%{term}%"])
   Note: get_user_email uses %s parameterization correctly — that pattern is safe.

N+1 patterns (1)
1. [medium] Query inside loop — get_orders_with_items
   Order.objects.filter(user_id=user_id) fetches N orders, then
   OrderItem.objects.filter(order_id=order.id) fires once per order → N+1 total queries.
   Fix:
     orders = Order.objects.filter(user_id=user_id).prefetch_related("orderitem_set")
     # Django will batch the OrderItem fetch into a single IN query automatically.
     # Then iterate order.orderitem_set.all() instead of querying inside the loop.

Unbounded queries (1)
1. [medium] No limit, no filter — get_recent_signups
   User.objects.all() returns every row in the users table with no LIMIT.
   The function name implies recency but no date filter or pagination exists.
   Fix:
     from django.utils import timezone
     from datetime import timedelta
     cutoff = timezone.now() - timedelta(days=30)
     User.objects.filter(date_joined__gte=cutoff).order_by("-date_joined")[:100]

Over-fetching (1)
1. [low] All columns fetched when downstream use is unknown — get_recent_signups
   User.objects.all() selects every column (including password hash, metadata, etc.).
   If only a subset of fields is presented to the caller, use .only() or .values():
     User.objects.filter(...).only("id", "email", "date_joined")

Missing transactions (0)
   No multi-table write sequences found in this module.

Summary
  Issues requiring immediate attention — one high-severity SQL injection
  vulnerability (search_users) that allows arbitrary query manipulation via the
  "q" parameter. Fix before code review proceeds. The N+1 and unbounded scan
  issues are medium severity and should be addressed before a performance-
  sensitive release.
```
