RPC calls can incorrectly treat requests as having a single unnamed positional argument when the request actually contains named parameters. This comes from `hasSingleUnnamedParam` matching named parameters incorrectly.

When calling an RPC endpoint (e.g. `/rpc/<function>`) with named arguments provided via query string (like `?min=2&max=4`) or via JSON body (like `{ "min": 2, "max": 4 }`), PostgREST should treat these as named parameters and pass them to PostgreSQL as such. It must not classify these requests as having a single unnamed parameter.

Currently, certain named-parameter requests are misclassified as a single unnamed-parameter call, which causes the RPC invocation to be built incorrectly and can lead to wrong results or failures when combining named args with other RPC-related query options (such as `limit`/`offset` pagination and Range-based pagination). In particular, RPC functions that return sets and support pagination should continue to work when arguments are supplied as named params and pagination is requested via either:

- `Range` / `Prefer: count=exact` headers, or
- `limit` and `offset` query parameters.

Fix `hasSingleUnnamedParam` so that it only returns true for the intended case: a request that truly provides exactly one unnamed argument, and does not accidentally match any request that provides named parameters. After the fix, RPC requests using named args (via query string or JSON body) must paginate correctly and return the expected HTTP status and headers for partial responses (e.g. `206` with `Content-Range` when an exact count is requested) as well as `200` with appropriate `Content-Range` when only slicing is applied.