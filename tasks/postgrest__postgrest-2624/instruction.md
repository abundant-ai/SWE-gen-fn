PostgREST’s generated OpenAPI document currently uses fixed values for the API metadata in the `info` object (notably `info.title` and `info.description`), and there is no supported way to customize these values.

Add support for customizing the OpenAPI title and description based on the database schema comment of the exposed API schema. When a schema has a SQL comment set, the OpenAPI output at the root endpoint must use that comment to populate `info.title` and `info.description`.

Behavior requirements:

- When requesting the OpenAPI document (e.g., `GET /` with `Accept: application/openapi+json`), the response JSON must include:
  - `info.title` set to the first paragraph/section of the schema comment.
  - `info.description` set to the remaining text after the title, preserving embedded newlines.

- The schema comment format to support is:
  - A title followed by a blank line, followed by a multi-line description.
  - Example schema comment:
    ```sql
    COMMENT ON SCHEMA test IS $$My API title

    My API description
    that spans
    multiple lines$$;
    ```
  - Expected OpenAPI fragment:
    ```json
    {
      "info": {
        "title": "My API title",
        "description": "My API description\nthat spans\nmultiple lines"
      }
    }
    ```
    (Note: the description should not include the title, and it should not include the separating blank line; it should preserve the line breaks within the description.)

- If the schema comment is absent or does not contain a description portion, PostgREST should still return a valid OpenAPI document. In such cases, it should fall back to the existing default behavior for `info.title` and/or omit `info.description` (or keep the current default) in a consistent way that does not break OpenAPI responses.

- Existing OpenAPI behavior must remain intact:
  - `HEAD /` with `Accept: application/openapi+json` must return status 200 and no body, with `Content-Type: application/openapi+json; charset=utf-8`.
  - Requests for OpenAPI on non-root paths (e.g., `GET /items` with `Accept: application/openapi+json`) must continue to return 415.

Implement the parsing/extraction logic and integrate it into the OpenAPI generation so that schema comments can drive `info.title` and `info.description` as described above.