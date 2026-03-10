PostgREST should expose its running version to SQL by setting PostgreSQL’s `fallback_application_name` connection parameter to a value that includes the PostgREST version (e.g., `postgrest-10.1.2`). This allows users to query `pg_stat_activity.application_name` and identify the PostgREST instance/version from within the database.

Currently, when PostgREST connects to PostgreSQL, `pg_stat_activity.application_name` is not guaranteed to include the PostgREST version, so queries like:

```sql
select distinct application_name
from pg_stat_activity
where application_name like '%postgrest%';
```

may return no rows or not include the version.

Update the database connection behavior so that PostgREST always provides `fallback_application_name=<postgrest-version-string>` as part of the connection URI/options it uses to connect. This must be done in a way that still allows users to override `application_name` explicitly (so `fallback_application_name` should be used, not forcing `application_name`).

When constructing the final connection URI, append the `fallback_application_name` parameter correctly:
- If the configured DB URI has no query string, append `?fallback_application_name=<version>`.
- If the configured DB URI already has a query string, append `&fallback_application_name=<version>`.

The version string should be the current PostgREST version as reported by the server build/version metadata.

After this change, a SQL function like the following should return a value containing the PostgREST version (and matching the pattern `postgrest-<version>`):

```sql
CREATE FUNCTION test.get_version() RETURNS pg_stat_activity.application_name%TYPE
AS $$
  select distinct application_name
  from pg_stat_activity
  where application_name like '%postgrest%';
$$ LANGUAGE sql;
```

Expected behavior: calling `test.get_version()` (or directly querying `pg_stat_activity`) while PostgREST is running returns an `application_name` that includes the PostgREST version via `fallback_application_name`.

Actual behavior: `application_name` does not reliably include the PostgREST version, making it impossible to obtain the version through SQL without external knowledge.