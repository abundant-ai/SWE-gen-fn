The OpenAPI/Swagger JSON served at the API root (GET "/") does not currently advertise any security scheme, which prevents Swagger UI from offering an authorization input for JWT (e.g., an “Authorize” button to set an `Authorization: Bearer <token>` header for requests). As a result, users cannot easily test authenticated endpoints through Swagger UI using PostgREST’s JWT support.

Add support for emitting OpenAPI security metadata when configured. Introduce a configuration option named `openapi-security-active` that controls whether the generated spec includes both a top-level `security` section and a `securityDefinitions` section.

When `openapi-security-active` is enabled, the JSON returned from GET "/" must include:

- A top-level `security` field with value:

```json
[
  { "JWT": [] }
]
```

- A top-level `securityDefinitions` field defining an API key scheme that uses the `Authorization` header:

```json
{
  "JWT": {
    "description": "Add the token prepending \"Bearer \" (without quotes) to it",
    "in": "header",
    "name": "Authorization",
    "type": "apiKey"
  }
}
```

When `openapi-security-active` is disabled (the default), the OpenAPI/Swagger output must not include these security-related fields.

The configuration system must recognize `openapi-security-active` from config files and environment variables, and the option must be reflected in the rendered/normalized configuration output (i.e., it should round-trip like other settings and have a default of `false`).