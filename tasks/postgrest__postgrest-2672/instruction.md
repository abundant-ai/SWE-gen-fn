Bulk INSERT and PATCH requests currently fail or behave incorrectly when the request uses the `columns` query parameter and the JSON payload does not provide values for every column listed in `columns`.

There are two related problems:

1) Bulk insert with non-uniform objects (some keys missing) is rejected instead of allowing defaults.

When inserting an array of JSON objects, clients commonly omit optional fields in some objects. Today this can trigger errors like “All object keys must match” on the client side (because the server effectively expects uniform keys/shape). On the server side, when `?columns=` is used to explicitly state which columns are being targeted, PostgREST should be able to treat missing keys as “not provided” and let Postgres apply the column default (or NULL if there is no default), rather than rejecting the request or forcing clients to send explicit nulls.

Example request:

```http
POST /complex_items?columns=id,name,field-with_sep,arr_data
Prefer: return=representation
Content-Type: application/json

[
  {"id": 4, "name": "Vier"},
  {"id": 5, "name": "Funf", "arr_data": null},
  {"id": 6, "name": "Sechs", "field-with_sep": 6, "arr_data": [1,2,3]}
]
```

Expected behavior: the insert succeeds and any column listed in `columns` but missing from a particular object is treated as if it were not supplied, so Postgres applies the column’s DEFAULT value (or NULL if no default exists). For the example above, if `field-with_sep` has a default of `1`, then the returned rows should show `field-with_sep: 1` for the first two inserted rows and `field-with_sep: 6` for the third.

Actual behavior: the insert is rejected or requires clients to manually add missing keys with `null`, preventing use of DEFAULT values and breaking bulk inserts where object keys differ.

2) PATCH cannot “reset” omitted columns to DEFAULT when `?columns=` is used.

When updating, users want to be able to send a partial JSON body while explicitly listing columns via `?columns=...` and have omitted columns from the JSON body revert to their DEFAULT values (instead of being ignored or causing errors). This is needed for “reset to default” workflows.

Example request:

```http
PATCH /complex_items?id=eq.3&columns=name,field-with_sep
Prefer: return=representation
Content-Type: application/json

{"name": "Tres"}
```

Expected behavior: the row is updated so `name` becomes "Tres" and `field-with_sep` is set to its DEFAULT value (e.g., `1`) because it was included in `columns` but not provided in the JSON payload. The response should include the updated representation when `Prefer: return=representation` is used.

Actual behavior: `field-with_sep` is not set to DEFAULT (it may remain unchanged or the request may fail), meaning there is no supported way to reset a column to its default via PATCH using `columns`.

Additional requirement: This behavior should work not only for tables but also for updatable views, as long as the view column has a DEFAULT defined (e.g., via `ALTER VIEW ... ALTER COLUMN ... SET DEFAULT ...`).

Implement support so that, when `?columns=` is present and an appropriate `Prefer` header opt-in is used (the feature is intended to be optional due to increased query cost), any listed column that is missing/undefined in a given JSON object (for bulk insert) or missing from the JSON body (for patch) is treated as DEFAULT instead of causing rejection or requiring explicit nulls. Explicit JSON `null` must still map to SQL NULL (i.e., it should not become DEFAULT).