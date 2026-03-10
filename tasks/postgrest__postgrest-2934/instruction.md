Requests that negotiate the OpenAPI representation via the Accept header are not being handled consistently after moving media-type logic into the planning layer. The server should correctly recognize and serve the OpenAPI document only on the root path, and it should reject unsupported or inappropriate OpenAPI/media-type requests with the proper HTTP status.

When a client requests the root path with an OpenAPI Accept header, e.g.

```http
HEAD /
Accept: application/openapi+json
```

the response must succeed with status 200 and include:

```http
Content-Type: application/openapi+json; charset=utf-8
```

Similarly, a GET to `/` with `Accept: application/openapi+json` must return a valid OpenAPI JSON document.

However, OpenAPI content negotiation must not “leak” to non-root resources. If a client requests a non-root path with an OpenAPI Accept header, e.g.

```http
GET /items
Accept: application/openapi+json
```

the server must respond with HTTP 415 Unsupported Media Type (it must not return a normal resource response, and it must not return the OpenAPI document).

The server must also reject unsupported media types on the root path for OpenAPI negotiation. For example:

```http
GET /
Accept: text/csv
```

must respond with HTTP 415.

Fix the media type negotiation/planning so that OpenAPI is only produced for the root path when the client explicitly requests `application/openapi+json`, uses `application/openapi+json; charset=utf-8` as the Content-Type for that response, and returns 415 for the two error cases described above (OpenAPI requested on non-root paths, and unsupported Accept on the root path).