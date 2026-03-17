PostgREST’s filter parser/SQL generator mishandles the `is` operator in two important ways.

1) The `is` operator is not fully parameterized and currently relies on a fallback that formats the right-hand side as a SQL literal (previously via `pgFmtLit`). This creates a non-parameterized fragment inside generated SQL for `is.<value>` filters. Besides being inconsistent with other operators, this is undesirable from a security perspective because it leaves room for SQL injection in theory when arbitrary values are allowed.

2) The `is` operator’s accepted values are inconsistent and regression-prone. A request like:

GET /projects?id=is.NULL

should behave the same as `id=is.null` and match rows where `id` is NULL. Instead, the parser rejects uppercase values with an error like:

{"details":"unexpected \"N\" expecting null or trilean value (unknown, true, false)","message":"\"failed to parse filter (is.NULL)\" (line 1, column 4)"}

In addition, the `is` operator should support the SQL tri-state semantics required by PostgREST filtering. It must accept exactly these right-hand values (case-insensitive):

- `null`
- `true`
- `false`
- `unknown`

and it must reject other values rather than trying to escape/format them into SQL.

Implement support for `unknown` for the `is` operator and make the accepted value set strict at the parsing level, so that `is` cannot be used with arbitrary unrecognized values. Ensure that `is.<value>` is handled without relying on any SQL-literal formatting/escaping fallback (i.e., remove any code path equivalent to `pgFmtLit` being used for `is`).

Expected behavior examples:

- `GET /no_pk?a=is.null` returns only rows where `a` is NULL.
- `GET /no_pk?a=not.is.null` returns only rows where `a` is not NULL.
- `GET /projects?id=is.NULL` works (case-insensitive) and matches NULL ids.
- `GET /table?col=is.unknown` is accepted and generates correct SQL semantics for IS UNKNOWN.
- `GET /table?col=is.somevalue` is rejected with a parse/validation error (rather than being interpolated/escaped into SQL).

The fix should ensure consistent parsing (case-insensitive), correct semantics for NULL/boolean/UNKNOWN, and no non-parameterized SQL literal fallback for the `is` operator.