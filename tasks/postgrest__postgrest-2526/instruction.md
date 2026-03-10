PostgREST v10 can detect foreign-key relationships for views nondeterministically when a view contains multiple columns that ultimately reference the same underlying table column. This causes embedding/relationship discovery (and the generated OpenAPI schema) to change between server startups even though the database schema is unchanged.

Reproduction example:

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

Observed behavior: restarting PostgREST multiple times leads to different sets of detected relationships for `v1`, `v2`, and `v3`. For example, on some runs `v1.parent` is annotated as a foreign key to `v1.id`, while on other runs that annotation appears on `v2.grandparent` (or other columns), making OpenAPI output and embedding behavior appear random.

Expected behavior: relationship detection must be deterministic and complete. If multiple view columns can be traced back to the same base table column (e.g., both `grandparent` and `parent` ultimately correspond to `hidden.t.parent` under different aliases/joins), PostgREST should reliably detect all applicable relationships for the view every time it starts, and it must not “drop” or misassign relationships depending on catalog ordering.

This impacts embedding and disambiguation behavior as well. When a client requests an embed that is ambiguous because more than one relationship exists between two resources (including relationships derived from views), the server should consistently return HTTP 300 with error code `PGRST201` and a JSON body containing:

- `message`: "Could not embed because more than one relationship was found for '<source>' and '<target>'"
- `hint`: suggesting explicit relationship selection using the `!` syntax (e.g. `target!relationship_name`)
- `details`: an array listing each candidate relationship with its `cardinality`, a human-readable `relationship` description, and the `embedding` pair

The fix should ensure the internal relationship discovery logic for views does not collapse multiple view columns that reference the same table column, and that any logic that derives view primary keys (e.g., `addViewPrimaryKeys`) remains correct and does not introduce compilation/runtime regressions while making relationship detection deterministic.