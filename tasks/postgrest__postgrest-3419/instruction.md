OpenAPI schema generation fails to annotate certain foreign key columns when the column is part of a one-to-one (O2O) relationship.

When PostgREST builds its OpenAPI document, it adds a note to column descriptions for detected foreign keys (e.g., a description containing the text "Note: This is a Foreign Key to ..."). This works for a column defined only as a foreign key, but it stops working if the same column also has a UNIQUE constraint.

Reproduction example (in SQL):

- For a table column defined as:

  todo_id int references api.todos(id)

  the generated OpenAPI schema should include the foreign key note in the description for `todo_id`.

- For a table column defined as:

  todo_id int references api.todos(id) unique

  the generated OpenAPI schema should still include the same foreign key note in the description for `todo_id`, but currently the note is missing.

This typically happens in one-to-one relationships, where the foreign key column is also unique.

Fix the OpenAPI generation so that foreign key detection and annotation is not suppressed by the presence of a UNIQUE constraint. After the fix, requesting the OpenAPI document (e.g., with `Accept: application/openapi+json`) must produce a schema where a column that is both a foreign key and unique is still tagged/annotated as a foreign key in the same way as a non-unique foreign key column.