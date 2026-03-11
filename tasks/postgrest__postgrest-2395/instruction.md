PostgREST currently over-quotes PostgreSQL identifiers that contain a dollar sign ($). In PostgreSQL, unquoted identifiers may include $ after the first character (identifiers must start with a letter or underscore, and subsequent characters may include letters, digits, underscores, and $). Despite this, PostgREST treats $ as requiring double quotes and generates SQL that unnecessarily quotes such column names.

This causes incorrect or inconsistent behavior when querying tables that have columns containing $ in their names. For example, requests that select, filter, or order by a column like foo$bar should work without PostgREST forcing quoting solely because of the $ character.

Fix the identifier-handling logic used when building SQL queries so that:

- Identifiers containing $ are considered valid unquoted identifiers (as long as they otherwise meet PostgreSQL’s identifier rules).
- PostgREST does not add double quotes around an identifier just because it contains $.
- Query operations that reference such columns (e.g., select lists, filters like eq/ne/lt, and order clauses) succeed and return the expected results.

The change should be applied consistently across all query-building paths that decide whether an identifier must be quoted, so that behavior is uniform for reading and filtering responses on columns with $ in their names.