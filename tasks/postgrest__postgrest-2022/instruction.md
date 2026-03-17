PostgREST’s schema cache currently includes PostgreSQL partition child tables as regular tables. This causes relationship/foreign-key discovery and other schema-cache-derived behavior to be incorrect when partitioned tables are present. In particular, when a table is partitioned (created with `PARTITION BY ...`), PostgREST may fail to recognize foreign keys and may not build the expected many-to-many relationships, even though the same schema works correctly if partitions are removed.

Reproduction example (simplified):

```sql
CREATE TABLE public."Diary" (
  school text NOT NULL,
  day text NOT NULL,
  student text NOT NULL,
  room text NOT NULL,
  PRIMARY KEY (school, day, student),
  FOREIGN KEY (school) REFERENCES public."School" (id),
  FOREIGN KEY (school, student) REFERENCES public."Student" (school, student),
  FOREIGN KEY (school, room) REFERENCES public."Room" (school, room)
) PARTITION BY LIST (school);

CREATE TABLE public."Student" (
  school text NOT NULL,
  student text NOT NULL,
  room text NOT NULL,
  PRIMARY KEY (school, student),
  FOREIGN KEY (school) REFERENCES public."School" (id),
  FOREIGN KEY (school, room) REFERENCES public."Room" (school, room)
) PARTITION BY LIST (school);
```

With partitioning enabled, PostgREST’s cached schema should treat only the partitioned parent tables (e.g., `Diary`, `Student`) as API-visible relations and should not treat partition children as separate tables for the purposes of schema cache, relationship discovery, and capability detection.

Fix the schema cache building logic so that partitions (child tables of a partitioned table) are excluded from the schema cache and do not participate in:

- foreign key and relationship detection (including many-to-many relationship generation),
- any table capability/metadata computation derived from the schema cache.

The behavior must also be correct across PostgreSQL versions:

- On PostgreSQL 10+ partitions must be detected and excluded from schema cache.
- On PostgreSQL versions below 10, the schema cache query must not reference `pg_class.relispartition` (or any other catalog attribute not available there), and schema cache building must still work without error.

Additionally, OPTIONS responses must correctly reflect write capability for partitioned parent tables. When performing `OPTIONS /<partitioned_table>` on a writable partitioned table:

- For PostgreSQL >= 11, the `Allow` header must include: `OPTIONS,GET,HEAD,POST,PUT,PATCH,DELETE`.
- For PostgreSQL 10, the `Allow` header must include: `OPTIONS,GET,HEAD,POST,PATCH,DELETE` (no `PUT`).

After the fix, schemas using partitioned tables like above should have their foreign keys/relationships recognized in the same way as non-partitioned schemas, and partition child tables should not appear as separate relations in the schema cache-driven API surface.