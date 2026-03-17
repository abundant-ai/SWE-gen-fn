When calling PostgREST RPC endpoints for PostgreSQL functions that are overloaded, PostgREST can respond with `300 Multiple Choices` because it cannot decide which function signature to use. This is especially problematic for POST-based RPC calls where the request body is JSON and one of the overloaded variants is designed to accept the entire JSON payload as a single argument (a single unnamed JSON/JSONB parameter).

Problem: If multiple overloaded functions share the same name, and one of them has exactly one parameter which is unnamed and of type JSON (or JSONB), PostgREST should not treat the call as ambiguous for a POST request with a JSON body. Instead, it should select that “single unnamed JSON parameter” overload as the target and execute it, rather than returning `300 Multiple Choices`.

Current behavior: A POST request to `/rpc/<function_name>` with a JSON body can return `300 Multiple Choices` when the target function name is overloaded, even in the case where one overload clearly matches the pattern “single unnamed JSON parameter”.

Expected behavior:
- For POST requests to `/rpc/<function_name>` with a JSON payload, if there are multiple overloads and exactly one of them has a single parameter that is unnamed and of type JSON/JSONB, PostgREST must choose that overload and execute it.
- The response should be the normal RPC success response (e.g., HTTP 200 with the function result) rather than `300 Multiple Choices`.
- This disambiguation should only apply to the specific case described (single parameter, unnamed, JSON/JSONB) and should not break existing overload selection logic for other signatures (e.g., named parameters, multiple parameters, or non-JSON single parameters).

Reproduction example:
1) Create two functions with the same name, where one takes regular named parameters and another takes a single unnamed JSON/JSONB parameter.
2) Send a POST request to `/rpc/<function_name>` with a JSON object body.
3) PostgREST should execute the single-unnamed-JSON-parameter overload; it should not return `300 Multiple Choices`.

Implement the overload resolution change so that this case is handled consistently and does not regress other RPC behaviors (including GET-based RPC calls with query string parameters and POST calls to non-overloaded functions).