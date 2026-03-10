PostgREST v10 has incorrect and sometimes nondeterministic detection of primary keys (PKs) and foreign key (FK) relationships for database views, especially when a view is defined over multiple base relations or includes self-joins. This breaks OpenAPI metadata generation and can also produce incorrect HTTP response headers for inserts.

A reproducible case is a view selecting from two base tables, each with its own primary key:

```sql
CREATE TABLE t1 (pk1 INT PRIMARY KEY);
CREATE TABLE t2 (pk2 INT PRIMARY KEY);
CREATE VIEW v AS
SELECT * FROM t1, t2;
```

Expected behavior: the view should expose all underlying primary key columns as primary keys in PostgREST metadata. In the OpenAPI schema for resource `v`, both `pk1` and `pk2` should be marked as primary keys (e.g., both columns have the primary key annotation/description).

Actual behavior in v10: only one of the PK columns is marked as a primary key (commonly `pk1`), while the other (`pk2`) is treated as a regular column.

This incorrect PK detection also affects insert responses. When inserting into the view and requesting headers-only, PostgREST should include all primary key columns in the `Location` header query string. For example:

```bash
curl -H "Prefer: return=headers-only" \
     -H "Content-Type: application/json" \
     -d '{"pk1":1,"pk2":1}' \
     -v http://localhost:3000/v
```

Expected: `Location: /v?pk1=eq.1&pk2=eq.1`

Actual in v10: `Location` only contains one key (e.g. `Location: /v?pk1=eq.1`).

A second class of problems occurs with views defined from multiple references to the same table (self-joins), where PostgREST sometimes detects relationships differently across server restarts (non-deterministic embeddings/relationships). Example schema:

```sql
CREATE SCHEMA hidden;

CREATE TABLE hidden.t (
  id INT PRIMARY KEY,
  parent INT REFERENCES hidden.t,
  type TEXT
);

CREATE VIEW v1 AS
SELECT parent.parent AS grandparent,
       child.parent,
       child.id
  FROM hidden.t AS parent
       JOIN hidden.t AS child
         ON child.parent = parent.id
 WHERE child.type = 'A';

CREATE VIEW v2 AS
SELECT parent.parent AS grandparent,
       child.parent,
       child.id
  FROM hidden.t AS parent
       JOIN hidden.t AS child
         ON child.parent = parent.id
 WHERE child.type = 'B';

CREATE VIEW v3 AS
SELECT parent.parent AS grandparent,
       child.parent,
       child.id
  FROM hidden.t AS parent
       JOIN hidden.t AS child
         ON child.parent = parent.id
 WHERE child.type = 'C';
```

Expected behavior: relationship and key detection for these views should be stable across restarts, and key/relationship annotations in OpenAPI should not vary between runs. Additionally, PKs exposed by the view should be correctly attributed (e.g., `id` consistently recognized as a PK where appropriate) and FKs should not be spuriously inferred between unrelated views.

Fix required: ensure PostgREST consistently exposes primary key columns from all base tables that contribute to a view (not just one), and use that complete PK set when generating OpenAPI metadata and when constructing `Location` headers after inserts into views. Relationship detection for views involving multiple references to the same base table must be deterministic across runs and must not randomly assign FK relationships between views.