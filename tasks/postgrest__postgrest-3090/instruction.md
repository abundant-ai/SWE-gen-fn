When clients send an invalid or empty JSON request body to write endpoints, PostgREST currently returns the underlying Aeson JSON parser error message in the response. For example, sending an empty body to an insert endpoint can produce an error payload like:

```json
{
  "code": "PGRST102",
  "details": null,
  "hint": null,
  "message": "Error in $: not enough input"
}
```

This is undesirable because it leaks parser-specific wording and produces inconsistent messaging.

Update the JSON request-body handling so that JSON parsing failures that correspond to an empty body or invalid JSON syntax return a generic message instead. Specifically, when an endpoint that expects a JSON body (e.g., POST insert or PATCH update) receives either:

- an empty payload (""), or
- a malformed JSON payload (e.g. `"}{ x = 2"`),

the server must respond with:

- HTTP status: 400
- Content-Type: application/json
- JSON body exactly:

```json
{"message":"Empty or invalid json","code":"PGRST102","details":null,"hint":null}
```

The error code must remain `PGRST102`, and `details`/`hint` must remain null; only the `message` should be replaced with the generic string `Empty or invalid json` instead of returning Aeson’s parser error text.