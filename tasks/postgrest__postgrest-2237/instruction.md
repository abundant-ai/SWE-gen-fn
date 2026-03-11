PostgREST currently supports pattern-matching filters like `like`/`ilike`, but it does not expose PostgreSQL’s POSIX regular expression operators. Users need to be able to filter rows using PostgreSQL regex matching (`~`) and case-insensitive regex matching (`~*`), including for types like `ltree` where `~` is used to match an `lquery`.

When a client calls an endpoint with a filter such as `GET /items?name=regex.<pattern>`, PostgREST should translate this into a SQL predicate equivalent to `name ~ <pattern>`.

Similarly, `GET /items?name=iregex.<pattern>` should translate into `name ~* <pattern>`.

At the moment, these operator names are not recognized as valid filter operators, so requests using them fail during query parsing/plan construction (e.g., they are treated as invalid operators and result in an error response rather than a filtered result set).

Implement support for two new filter operators:

- `regex` maps to the PostgreSQL `~` operator
- `iregex` maps to the PostgreSQL `~*` operator

The operators must work in the same places other comparison operators work (regular column filters), and must behave consistently with other filters regarding negation. For example, `GET /items?name=not.regex.<pattern>` should behave like `NOT (name ~ <pattern>)`, and `GET /items?name=not.iregex.<pattern>` should behave like `NOT (name ~* <pattern>)`.

Example expected behavior:

- If a table has rows with `name` values `"foo"`, `"FoO"`, and `"bar"`, then `GET /items?name=regex.^f` should match `"foo"` but not `"FoO"`.
- `GET /items?name=iregex.^f` should match both `"foo"` and `"FoO"`.

For `ltree` usage, a request like `GET /table?path=regex.*.foo.*` should be supported so that it can express the SQL semantics `path ~ '*.foo.*'`.

After implementing this, requests using `regex`/`iregex` filters should return HTTP 200 with correctly filtered JSON results, rather than rejecting the operator.