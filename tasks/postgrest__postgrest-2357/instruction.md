When PostgREST runs with OpenAPI enabled and a view is exposed, primary key columns of that view are not consistently detected in v10+ when the view is based on multiple underlying relations (e.g., a view selecting from two base tables). This causes two user-visible regressions compared to v9.

Reproduction schema:

```sql
CREATE TABLE t1 (pk1 INT PRIMARY KEY);
CREATE TABLE t2 (pk2 INT PRIMARY KEY);
CREATE VIEW v AS
SELECT * FROM t1, t2;
```

Problem 1: OpenAPI output for the view omits primary-key metadata for some columns.

Expected behavior: In the OpenAPI schema for resource `v`, both `pk1` and `pk2` must be marked as primary keys using the special marker in the field description, exactly including the substring:

`This is a Primary Key.<pk/>`

So both properties should include a description containing that `<pk/>` marker.

Actual behavior (v10): Only one of the primary key columns (e.g., `pk1`) includes the `description` with `<pk/>`; the other (e.g., `pk2`) is missing the primary key description entirely.

Problem 2: The `Location` header generated after inserting into the view is incomplete.

Reproduction request:

```bash
curl -H "Prefer: return=headers-only" \
     -H "Content-Type: application/json" \
     -d '{"pk1":1,"pk2":1}' \
     -v http://localhost:3000/v
```

Expected behavior: The server should return `201 Created` and the `Location` header must include all primary key components for the inserted row, e.g.:

`Location: /v?pk1=eq.1&pk2=eq.1`

Actual behavior (v10): The `Location` header includes only a subset of the primary key columns, e.g.:

`Location: /v?pk1=eq.1`

This regression is especially problematic for client libraries that rely on the `<pk/>` marker in OpenAPI to identify primary key fields for views.

Fix the primary key detection and OpenAPI generation logic so that views (including views based on multiple relations) correctly recognize and expose all primary key columns, and ensure responses that build `Location` from primary keys include every detected primary key column. This should also work correctly when running in the OpenAPI mode that follows privileges ("follow-privileges"), where the output should remain correct and not drop PK markers due to privilege-related filtering.