PostgREST can crashloop and heavily load PostgreSQL when building/loading its schema cache if the database contains a self-referencing (infinitely recursive) view definition. This is an edge case but can happen when a view is replaced with a body that selects from itself.

Reproduction in PostgreSQL:

```sql
create view test.view_projects as
select * from test.projects;

create or replace view test.view_projects as
select * from test.view_projects;

select * from test.view_projects;
-- ERROR:  infinite recursion detected in rules for relation "view_projects"
```

With such a view present in an exposed schema, starting PostgREST (or triggering a schema cache reload) causes the schema-introspection query used for schema cache building to recurse indefinitely (or effectively unbounded), leading to runaway CPU/memory usage on the PostgreSQL side and PostgREST entering a crashloop.

The schema cache loading logic must be changed so that introspection of view dependencies/structure does not recurse infinitely when a view references itself (directly or via a cycle). When PostgREST encounters these recursive view definitions during schema cache construction, it should avoid unbounded recursion and complete schema cache loading without hanging or causing excessive resource usage.

Expected behavior:
- PostgREST should start normally and be able to serve requests (including generating the OpenAPI document) even if the database contains a self-referencing view.
- Schema cache loading should terminate in bounded time and must not trigger runaway recursion in PostgreSQL.
- Recursive/cyclic views should not cause PostgREST to crashloop; they should be ignored, safely truncated in dependency traversal, or otherwise handled so that schema cache construction finishes.

Actual behavior:
- With a self-referencing view present, PostgREST schema cache loading causes PostgreSQL to consume a lot of memory/CPU and PostgREST crashloops due to the introspection query recursing without a safe bound.

Implement a guard in the schema cache view-introspection logic so that dependency traversal has a maximum recursion depth and/or cycle detection, preventing infinite recursion when loading schema information for views. The change should ensure that endpoints that rely on the schema cache (including the root OpenAPI response) continue to work in the presence of such views.