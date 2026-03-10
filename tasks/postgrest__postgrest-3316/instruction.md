INSERT/POST requests currently normalize the incoming JSON body by calling PostgreSQL’s json_typeof/jsonb_typeof to determine whether the payload is an array, and if it’s not, wrap it with json_build_array so that json_to_recordset can be used uniformly. This adds measurable overhead on write-heavy workloads.

Change the request handling/query generation so that PostgREST no longer uses json_typeof/jsonb_typeof for write requests. Instead, perform lightweight validation on the raw JSON request body (before sending it to PostgreSQL) to decide whether the payload is a JSON array or a single JSON object, using lazy ByteString operations (i.e., without fully decoding the JSON into an Aeson Value).

Behavior requirements:

When a client sends a write request (e.g., POST/INSERT) with a JSON request body:

- If the payload is a JSON array (e.g. `[{