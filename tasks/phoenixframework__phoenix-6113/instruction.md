Browsers are deprecating the HTTP response header `X-Frame-Options`, and Phoenix currently includes this header as part of its secure browser headers. This causes applications generated or configured with Phoenix’s secure browser header defaults to rely on a mechanism that is no longer recommended and may stop working in modern browsers.

Phoenix should stop relying on `X-Frame-Options` for clickjacking protection and instead enforce framing restrictions via Content Security Policy using the `frame-ancestors` directive. When secure browser headers are applied, the response should include a `Content-Security-Policy` header that contains an appropriate `frame-ancestors` value (matching the previous intent of preventing embedding), and Phoenix should no longer emit `X-Frame-Options` as part of the default secure browser headers.

The change must preserve the existing secure-headers API and usage patterns: applications calling Phoenix’s secure header helper(s) should continue to work without changing their code, but the resulting headers should reflect the modern CSP-based framing protection. If an application already sets a `Content-Security-Policy` header, the secure-header behavior should not break or remove that policy; it should either integrate the `frame-ancestors` directive correctly or otherwise ensure the final response still has a valid CSP that enforces the intended framing restrictions.

Reproduction example:

```elixir
conn
|> put_secure_browser_headers()
```

Expected behavior: the response includes a `Content-Security-Policy` header with a `frame-ancestors` directive that prevents the page from being framed by other origins (equivalent to the old default protection), and does not depend on `X-Frame-Options`.

Actual behavior: the response includes `X-Frame-Options`, which is deprecated, and may not include CSP `frame-ancestors` framing protection.