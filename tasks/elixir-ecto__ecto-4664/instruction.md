Ecto queries currently allow specifying a schema-mapped source as a tuple like {"user_posts", MySchema} in the from clause, so the query has both a concrete source and a schema to map fields/types. However, the same mapping is not supported when the source is a SQL fragment.

When building a query whose source is a fragment, users need to be able to associate that fragment source with a schema, e.g. using from(x in {fragment("select generate_series(?::integer, ?::integer) as num", ^0, ^2), MySchema}, ...). This should behave like other schema-mapped sources: the query should treat the second element as the schema for field mapping and type information, while the first element is the actual source expression.

Right now, attempting to use a fragment as the source in a {source, schema} tuple is not handled consistently across the query pipeline. In particular:

- Inspecting such a query should produce a stable, readable representation that includes both the fragment source and the schema module, similar to how {"user_posts", MySchema} is shown.
- Planning/normalizing the query must accept this form as a valid query source and carry the schema mapping through the planner, so later compilation stages can rely on correct schema metadata.

Example that should work:

import Ecto.Query

query =
  from(x in {fragment("select generate_series(?::integer, ?::integer) as num", ^0, ^2), Inspect.Comment},
    select: x
  )

Expected behavior:

- The query is accepted (no error during query construction/planning).
- inspect(query) renders the from source as a tuple where the first element is the fragment expression (as a stringified fragment in the inspect output) and the second element is the schema module.

Actual behavior:

- The query either fails to plan/normalize due to the fragment source not being recognized as a valid schema-mapped source, or it loses/does not apply the schema mapping.
- The inspect output does not properly represent this {fragment(...), Schema} form.

Implement support for fragment sources mapped to schemas in the from source tuple so that query inspection and query planning both handle {fragment(...), Schema} consistently.