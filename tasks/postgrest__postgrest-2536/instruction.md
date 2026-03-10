When embedding a computed relationship inside a normal relationship, PostgREST can generate SQL that references the wrong identifier for the function argument passed to the computed relationship.

A failing example is a request like:

`GET /well?select=well_id,container(root_container(*))`

where `root_container(*)` is a computed relationship function that takes a row of type `container` and returns a single `container` row (e.g., defined with `RETURNS SETOF ... ROWS 1`). In this scenario, PostgREST generates SQL that calls the computed relationship function using an identifier that does not exist in scope, for example:

`FROM "api"."root_container"("container")`

Even though the surrounding query has the related table properly aliased (e.g., `FROM "api"."container" AS "container_1"`), the function call incorrectly uses `"container"` instead of the actual alias (`"container_1"`). PostgreSQL then fails at execution time with:

`ERROR:  column "container" does not exist`

Expected behavior: when a computed relationship is embedded beneath a normal relationship (or otherwise invoked in a context where the parent row source is aliased), the generated SQL must pass the correct in-scope alias (the row value being used as the function argument) to the computed relationship function. The request should succeed and return embedded JSON for the computed relationship rather than raising a SQL error.

This needs to work for computed relationships used as many-to-one embeds (including the `SETOF ... ROWS 1` form) and should not regress existing computed relationship embedding cases (many-to-one, one-to-many, usage with `!inner`, and usage with `count=exact`).