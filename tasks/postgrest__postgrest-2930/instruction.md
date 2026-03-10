When querying a resource with an embedded relationship and applying filters that check whether the embedded resource is NULL/non-NULL, requests succeed normally but fail when a count is requested via the Prefer header.

For example, given a parent table (e.g. `people`) and an embedded child relationship (e.g. `donations`), a request like:

```
GET /people?select=*,donations(*)&or=(and(donations.not.is.null))&donations.or=(and(amount.eq.1))
```

returns the correct rows.

However, sending the same request with a count preference such as:

```
Prefer: count=exact
```

(or other count modes like estimated) results in a PostgreSQL error similar to:

```
{ code: "42703", message: "column \"people_donations_1\" does not exist" }
```

The server should be able to return the response body and include the count information without changing the semantics of the query or introducing invalid SQL references. In particular:

- Adding `Prefer: count=exact` (or other count modes) must not cause requests with embedded NULL/non-NULL filters (e.g. `donations.is.null`, `donations.not.is.null`) to fail.
- The count query must be generated in a way that preserves any required joins/aliases needed by embedded filters, so that no non-existent column/alias (like `people_donations_1`) is referenced.
- The behavior should work for filters on related tables combined with embedded selection, including cases using `or=` at the top level and relationship-scoped boolean logic (e.g. `donations.or=(...)`).