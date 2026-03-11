When generating URLs via Phoenix VerifiedRoutes, query parameters can appear in an unstable order. This makes assertions in tests brittle when query params are built dynamically (for example, redirect URLs where the backend constructs a query map and the resulting ordering is not predictable).

The VerifiedRoutes pipeline should produce a deterministic query string ordering during tests so that URLs are stable across runs. In particular, query string serialization should sort query parameters in test mode (and only in test mode), so that the same logical query (regardless of insertion order in a map/keyword list or how it is constructed) results in the same URL string.

Currently, calling the VerifiedRoutes path generation (including via the `~p` sigil) with query params like `%{b: 2, a: 1}` may produce either `?b=2&a=1` or `?a=1&b=2` depending on construction/order, which causes equality-based URL assertions to fail intermittently.

Update the VerifiedRoutes URL rewriting/encoding so that, in the final URL output, the query portion is deterministically ordered during tests. This should apply consistently to query strings produced from both static and dynamic query params.

The change should be implemented in the VerifiedRoutes query encoding/rewrite flow (for example, around `rewrite_path/4` and/or `Phoenix.VerifiedRoutes.__encode_query__/1`) so that:

```elixir
~p"/posts?b=2&a=1"
```

and

```elixir
~p"/posts?#{%{b: 2, a: 1}}"
```

produce a path whose query string is sorted (e.g. `"/posts?a=1&b=2"`) when running in the test environment.

Outside of tests, URL generation behavior should remain unchanged (no added sorting overhead or behavior differences in development/production).