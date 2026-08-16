Here's a summary of the issues found, ranked by severity:

---

**1. Critical — SQL injection (`search_users`, line 12)**

The f-string `f"SELECT ... WHERE name LIKE '%{term}%'"` passes user input directly into the SQL string. Use Django's parameterized placeholder instead:

```python
cursor.execute("SELECT id, name FROM users WHERE name LIKE %s", [f"%{term}%"])
```

**2. High — `None` when `q` is absent (`search_users`, line 12)**

`request.GET.get("q")` returns `None` if the param is missing, producing `WHERE name LIKE '%None%'`. Validate early:

```python
term = request.GET.get("q", "").strip()
if not term:
    return []
```

**3. Medium — Unbounded `User.objects.all()` (`get_recent_signups`, line 4)**

No `LIMIT` or pagination means the entire users table loads into memory. Add `.order_by('-date_joined')[:100]` or wire it through a paginator.

**4. Medium — N+1 queries (`get_orders_with_items`, line 7)**

One extra `SELECT` fires per order. Replace with a single prefetch:

```python
orders = Order.objects.filter(user_id=user_id).prefetch_related('orderitem_set')
```

Then access `order.orderitem_set.all()` inside the loop — no additional queries.

---

`get_user_email` (line 17) is clean: it uses `%s` parameterization correctly.
