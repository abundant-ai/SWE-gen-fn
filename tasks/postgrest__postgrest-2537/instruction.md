PostgREST’s query string parsing is currently too permissive and inconsistent, which leads to confusing behavior and misleading error messages. The server should parse query parameters more strictly and reject ambiguous or malformed syntax early, instead of silently accepting it or producing unrelated database errors.

One problem is that `select` parsing allows invalid field syntax involving whitespace. For example, a request like:

`GET /table?select=name,join (*)`

treats the trailing space in `join (*)` as part of the field name and produces incorrect interpretation. Leading whitespace is handled differently (e.g. `select=name, join(*)` works), so behavior is inconsistent. Expected behavior: whitespace around field names and embedding parentheses should not become part of the identifier; `join (*)` should be interpreted the same as `join(*)` (or be rejected consistently if such spacing is not allowed). Actual behavior: trailing spaces can change the identifier and break selection/embedding.

Another problem is that bracket characters inside `select` items (e.g. `name[]`) are not being parsed/quoted correctly, resulting in a misleading error message that looks like a missing relationship/column on the parent table. For example:

`GET /projects?select=id,clients(name[])`

currently can surface an error like:

`column projects.clients does not exist`

with a hint about `projects.client_id`, which is not the real problem. Expected behavior: the error should reflect the actual invalid column token inside the embedded select (the `name[]` identifier), similar to PostgreSQL’s own error for referencing a column literally named `name[]` (e.g. `column "name[]" does not exist`, with a hint pointing to `projects.name` if applicable). The parser should not misinterpret `[]` in a way that changes the error to a missing relationship/field on the outer table.

Finally, `select` currently allows confusing mixed usage where the same identifier can be interpreted both as an embedded relationship and as a computed column, so both of these can return results:

`GET /premieres?select=*,film(*)`

and

`GET /premieres?select=*,film`

This is ambiguous and leads to surprising output depending on whether parentheses are present. Expected behavior: query string parsing should be strict enough to avoid this ambiguity. When an identifier refers to an embedded relationship/computed relationship, it should require embedding syntax (parentheses) to embed; when it refers to a scalar/computed column, it should be selected as a field, and invalid combinations should be rejected with a clear error. The server should not accept both forms when they imply different semantics.

Fix the query string parsing/validation so that:
1) whitespace does not become part of selected field/relationship identifiers (and behavior is consistent for leading/trailing spaces),
2) invalid bracket syntax like `[]` inside `select` does not get mis-parsed into unrelated missing-column/relationship errors, and instead results in an error message consistent with the actual invalid identifier, and
3) ambiguous mixing of computed columns and relationship embedding via `select` is not silently accepted; ambiguous cases should be rejected or require unambiguous syntax, with clear user-facing errors.