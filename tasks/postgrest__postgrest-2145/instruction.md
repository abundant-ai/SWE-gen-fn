PostgREST should support accessing array items and fields of composite types through JSON operators in all relevant query contexts (select shaping, ordering, and filtering). Currently, requests that use JSON operators like `->`/`->>` to index into PostgreSQL arrays (including multidimensional arrays) can generate SQL that binds index values as untyped/`text` parameters, which causes incorrect behavior or operator resolution errors when PostgreSQL expects integer indexes.

A failing example is a request that both selects indexed array elements and orders by an indexed element:

```http
GET /arrays?select=a:numbers->0,b:numbers->1,c:numbers_mult->1->1,d:numbers_mult->2->3&order=numbers->0.desc
```

The generated SQL uses parameter placeholders for the indexes but sometimes omits the required integer cast, producing expressions like:

```sql
to_jsonb(arrays.numbers)->$1
```

instead of ensuring the index parameter is treated as an integer, e.g.:

```sql
to_jsonb(arrays.numbers)->$1::int
```

This missing cast can make PostgreSQL interpret the placeholder as `text`/unknown, which breaks proper array element access via `->`/`->>` and leads to failures in `select` and `order` (even if filtering may appear to work in some cases). The behavior is inconsistent: some index parameters are cast to `::int` while others are not within the same request.

The server needs to consistently treat numeric JSON-operator path segments used as array indexes as integers when they are passed as prepared-statement parameters, across:

- Response shaping via the `select` parameter when using expressions like `col->0`, `col->1`, and nested forms like `col->1->1`.
- Ordering via the `order` parameter when ordering by JSON-operator expressions like `col->0.desc`.
- Filtering where the left-hand side uses JSON-operator expressions involving array indexing.

Additionally, composite type field access should be supported through these JSON operators so that users can filter/select/order on composite subfields in a similar way (e.g. being able to address fields of a composite value through the JSON operator expression pipeline PostgREST supports).

After the fix, array indexing through JSON operators should work reliably for single- and multi-dimensional arrays in `select` and `order`, with SQL that always uses integer-typed indexes for `->`/`->>` when the path segment is numeric, avoiding operator/type errors and returning the expected projected values and ordering.