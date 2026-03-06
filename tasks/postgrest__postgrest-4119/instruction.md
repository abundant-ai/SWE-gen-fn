When calling an RPC endpoint with the `Prefer: handling=strict` header, PostgREST should reject preferences that cannot be correctly enforced for the given RPC result type.

Currently, the `max-affected` preference is not failing for RPC calls when `handling=strict` is used and the RPC returns `void` or a scalar value (non-table/non-composite). This is incorrect because PostgREST cannot reliably determine the number of affected rows from an RPC that returns `void` or a scalar, so `max-affected` cannot be validated.

Reproduction example:

1) Create an RPC that returns `void` but performs a DML statement internally:
```sql
create or replace function test.delete_items_returns_void() returns void as $$
  delete from items where id <= 15;
$$ language sql;
```

2) Call it with strict handling and max-affected:
```sh
curl "http://localhost:3000/rpc/delete_items_returns_void" \
  -X POST \
  -H "Prefer: handling=strict, max-affected=10"
```

Actual behavior: the request succeeds (no error), even though `max-affected` cannot be enforced.

Expected behavior: the request must fail with HTTP 400 when `handling=strict` is present and `max-affected` is provided for an RPC that returns `void` or a scalar value.

The failure should be surfaced as the same “invalid preferences with handling=strict” class of error used when strict handling is combined with unsupported/invalid preferences, including:
- JSON error response with `code` = `PGRST122`
- `message` = `Invalid preferences given with handling=strict`
- `details` listing `max-affected` as invalid in this context

This strict validation should apply specifically to RPC calls whose declared return type is `void` or a scalar. RPC calls that return row sets / composite types (where affected rows can be determined consistently) should not be rejected solely due to `max-affected` being present.