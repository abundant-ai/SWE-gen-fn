When running PostgREST with the `--dump-schema` flag, the JSON schema dump is missing information that is present in the loaded schema cache.

In particular, after starting PostgREST against a database where the schema cache reports that it loaded Media Type Handlers and Timezones, invoking `postgrest ... --dump-schema` produces a JSON object where:

- `dbMediaHandlers` is an empty array (`[]`) even though media handlers exist and are used by the server.
- `dbTimezones` is also empty (`0` elements) even though timezones should be discoverable/dumped.

Example observed behavior:

- Normal startup log indicates something like: “Schema cache loaded … 45 Media Type Handlers”.
- But `postgrest ... --dump-schema | jq '.dbMediaHandlers'` returns `[]`.
- Counting elements in the dump yields `dbMediaHandlers: 0` and `dbTimezones: 0` while other fields (tables, relationships, routines, representations) are populated.

`--dump-schema` should output a complete and faithful JSON representation of the in-memory schema cache, including media handlers and timezones, in the same way it already outputs tables, relationships, routines, and representations.

Fix `--dump-schema` so that:

- `dbMediaHandlers` is present and contains the discovered media handler mappings.
- `dbTimezones` is present and contains the discovered timezone data.
- The output is valid JSON and can be consumed by tools like `jq`.

The behavior should be consistent with what PostgREST reports it loaded into the schema cache (i.e., dumping should not silently drop these fields or serialize them as empty when they are populated).