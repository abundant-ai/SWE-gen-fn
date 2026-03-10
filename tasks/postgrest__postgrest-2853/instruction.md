Null filtering on embedded resources can fail when the client requests an exact or estimated row count via the Prefer header.

Given a parent resource with an embedded relationship, queries that include an embedded null-check filter (e.g. `donations.not.is.null` or the equivalent null embed filter logic used for embedded resources) work normally when no count is requested, but fail when `Prefer: count=exact` (and similarly for other count modes) is present.

For example, with a `people` table and a related `donations` table (via `donations.person_id -> people.id`), the following request returns the correct rows:

```bash
curl 'http://localhost:8000/rest/v1/people?select=*,donations(*)&or=(and(donations.not.is.null))&donations.or=(and(amount.eq.1))'
```

But adding the count preference triggers a SQL error:

```bash
curl 'http://localhost:8000/rest/v1/people?select=*,donations(*)&or=(and(donations.not.is.null))&donations.or=(and(amount.eq.1))' \
  -H 'Prefer: count=exact'
```

Current behavior: the server returns a PostgreSQL error like:

`{code: "42703", message: "column \"people_donations_1\" does not exist"}`

Expected behavior: the same request should succeed and return the normal response payload, with counting enabled (i.e., the response should include the count metadata per the Prefer behavior) while still applying all filters, including embedded null-check filters.

The bug appears to be in how SQL is generated for null embed filters when the query is wrapped/rewritten to compute counts: an alias/column reference used for the embedded null-check is valid in the non-count query but becomes invalid (or is referenced at the wrong level) in the count query, leading to the missing-column error.

Fix the SQL generation so that embedded null filtering works correctly regardless of whether `Prefer: count=exact` (or other count modes) is requested. In particular, ensure the logic that builds the SQL fragment for embedded null checks (often referred to as something like `addNullEmbedFilters`) produces valid references both in the main select and in any derived/count query form, so the generated SQL does not reference non-existent aliases like `people_donations_1`.