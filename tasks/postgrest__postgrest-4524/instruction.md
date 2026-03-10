When performing a read request with `Prefer: count=exact`, PostgREST generates SQL that can end up scanning the same underlying relation twice: once to produce the (empty) page body and once to compute the total count. This is especially visible for `HEAD` requests, where no response body is needed but the generated SQL still includes a full source selection that causes an extra scan and slows the request unnecessarily.

Reproduction example:

```bash
curl -I 'http://localhost:3030/big_table' -H 'Prefer: count=exact'
```

Current behavior: the query plan shows two sequential scans of the same table (one for the count CTE/subquery and another for the main source), making `HEAD` with `count=exact` slower than it should be.

Expected behavior: if there is no `limit`, no `offset`, and no `db-max-rows` restriction affecting the query, the `count=exact` SQL for `HEAD` should avoid the redundant source scan and only perform the work required to compute the exact count and produce headers/status. In particular, for `HEAD` requests without pagination constraints, the generated SQL should not include a full `SELECT * FROM <table>` source that forces a second scan.

The optimization must preserve correctness for other cases:
- If `limit` and/or `offset` are present, behavior should remain correct (page totals and total count must match the semantics of pagination).
- If `db-max-rows` is set (or otherwise applies), behavior must still respect that limitation and must not return counts inconsistent with the effective row limiting.
- The change must not affect non-`count=exact` preferences or normal `GET` responses beyond the intended optimization.

The result should be that `HEAD` requests with `Prefer: count=exact` on an unpaginated resource complete faster by avoiding unnecessary scans, while still returning the same count-related headers as before.