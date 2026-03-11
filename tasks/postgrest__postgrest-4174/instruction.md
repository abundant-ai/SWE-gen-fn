When generating the OpenAPI specification, PostgREST currently advertises GET endpoints for RPC/function routes even when the underlying PostgreSQL function is marked VOLATILE. At runtime, these same VOLATILE functions correctly reject GET requests with a "405 Method Not Allowed", so the OpenAPI output is misleading and causes client code generators or tools to attempt invalid GET calls.

Fix the OpenAPI generation so that GET is only included for non-volatile functions. Specifically, the OpenAPI PathItem created for a function route must respect the function’s volatility metadata (available as the procedure description’s volatility field, e.g. `pdVolatility`).

Expected behavior:
- For VOLATILE functions, the OpenAPI spec must expose only the POST operation (no GET operation present under that path).
- For STABLE functions, the OpenAPI spec must expose both GET and POST operations.
- For IMMUTABLE functions, the OpenAPI spec must expose both GET and POST operations.

Actual behavior:
- The OpenAPI spec includes GET for all functions regardless of volatility, even though VOLATILE functions return 405 on GET at runtime.

The change should be implemented in the function-path OpenAPI builder (the logic responsible for creating a PathItem for procedures, e.g. `makeProcPathItem()`), ensuring method exposure in the spec matches the existing runtime method allowance semantics.