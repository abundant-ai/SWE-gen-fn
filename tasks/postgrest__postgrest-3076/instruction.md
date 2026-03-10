PostgREST supports “SQL handlers for custom media types” by letting users create domains named like media types (e.g. "text/plain", "image/png") and then defining functions/aggregates that return those domains so PostgREST can select the right handler based on the request’s Accept header.

Currently, it is not possible to define a generic handler that matches any media type via the wildcard media type "*/*". Even if a user creates a PostgreSQL domain named "*/*" and defines a function that returns it, PostgREST does not treat it as a valid custom media type handler during content negotiation. As a result, users cannot implement a single SQL function that can serve different media types dynamically (including setting a specific Content-Type header at runtime) when the client sends either no Accept header or "Accept: */*".

The server should allow using "*/*" as a return type for custom SQL handlers and correctly pick that handler when appropriate.

Reproduction example:

1) In the database, define a domain and a function:

```sql
create domain "*/*" as bytea;

create or replace function ret_some_mt ()
returns "*/*" as $$
declare
  req_accept text := current_setting('request.headers', true)::json->>'accept';
  resp bytea;
begin
  case req_accept
    when 'app/chico'   then resp := 'chico';
    when 'app/harpo'   then resp := 'harpo';
    when '*/*'         then
      perform set_config('response.headers', '[{"Content-Type": "app/groucho"}]', true);
      resp := 'groucho';
    else
      raise sqlstate 'PT415' using message = 'Unsupported Media Type';
  end case;
  return resp;
end; $$ language plpgsql;
```

2) Call the RPC endpoint:

- `curl localhost:3000/rpc/ret_some_mt` should return body `groucho` and respond with `Content-Type: app/groucho` (because when no Accept header is provided, the request is treated as accepting */*).

- `curl localhost:3000/rpc/ret_some_mt -H "Accept: app/harpo"` should return body `harpo`.

- `curl localhost:3000/rpc/ret_some_mt -H "Accept: unknown/unknown" -i` should return `HTTP/1.1 415 Unsupported Media Type`.

Expected behavior:
- PostgREST must recognize custom SQL handlers whose return type is the domain named "*/*".
- When the client’s Accept header is missing or is "*/*", PostgREST should be able to select the "*/*" handler.
- When the "*/*" handler is selected, PostgREST must allow the SQL handler to set `response.headers` (e.g., to a specific Content-Type) and return raw bytes/text accordingly.
- For table endpoints that use custom aggregate-based handlers, it should also be possible to define a "*/*"-style handler (via the same domain approach) so generic binary outputs can be served when the request accepts anything.

Actual behavior:
- The "*/*" domain return type is not accepted/recognized as a valid custom media type handler, so requests that should be handled by the wildcard handler instead fail content negotiation (typically with a 415 Unsupported Media Type / “None of these media types are available …”) or fall back incorrectly rather than invoking the SQL handler.