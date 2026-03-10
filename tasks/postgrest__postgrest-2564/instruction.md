PostgREST supports resource embedding via the `select=` query parameter, producing nested JSON objects for related resources. For deep embeds (multiple “hops”), the current behavior forces extra nesting, making it hard to “flatten” fields from to-one relationships (many-to-one and one-to-one) into the parent object.

Implement support for “spread embeds” using the `..` operator inside `select=` so that fields from an embedded to-one resource can be merged into the current JSON object, including when spreads are chained across multiple levels.

For example, a request like:

GET /projects?select=id,..clients(client_name:name)

should return each project with the client name spread into the project object (not nested under a `clients` key), producing rows like:

{ "id": 1, "client_name": "Microsoft" }

and when the relationship is missing it should produce the spread fields with `null` values, e.g.:

{ "id": 5, "client_name": null }

Spreads must also work across multiple hops, e.g.:

GET /grandchild_entities?select=name,..child_entities(parent_name:name,..entities(grandparent_name:name))&limit=3

should flatten both `parent_name` and `grandparent_name` into the top-level object:

[
  {"name":"grandchild entity 1","parent_name":"child entity 1","grandparent_name":"entity 1"},
  {"name":"grandchild entity 2","parent_name":"child entity 1","grandparent_name":"entity 1"},
  {"name":"grandchild entity 3","parent_name":"child entity 2","grandparent_name":"entity 1"}
]

Spreads should be usable inside a normal (non-spread) embed. For example:

GET /grandchild_entities?select=name,child_entity:child_entities(name,..entities(parent_name:name))&limit=1

should keep `child_entity` as an object, but spread `parent_name` into that embedded object:

[{"name":"grandchild entity 1","child_entity":{"name":"child entity 1","parent_name":"entity 1"}}]

Spreads must work for one-to-one relationships as well, e.g.:

GET /country?select=name,..capital(capital:name)

should produce:

[{"name":"Afghanistan","capital":"Kabul"}, {"name":"Algeria","capital":"Algiers"}]

Validation: spreading is only allowed for to-one relationships (many-to-one or one-to-one). If a spread is attempted on a to-many relationship, the request must fail with HTTP 400 and the following JSON error shape and values:

{
  "code": "PGRST119",
  "details": "'<origin>' and '<target>' do not form a many-to-one or one-to-one relationship",
  "hint": null,
  "message": "A spread operation on '<target>' is not possible"
}

(where `<origin>` is the current resource name and `<target>` is the attempted spread embed name).