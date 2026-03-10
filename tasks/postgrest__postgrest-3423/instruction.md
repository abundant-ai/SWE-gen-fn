When PostgREST receives a PostgreSQL error raised with the special "PGRST" convention, it validates the JSON provided in the error MESSAGE and/or DETAIL fields to construct the HTTP response (status, headers, and body). Currently, when that JSON is present but does not match the required schema (for example, DETAIL is JSON but not an object with the expected keys like "status" and "headers"), PostgREST responds with the generic error message: "The message and detail field of RAISE 'PGRST' error expects JSON".

This message is misleading because the value is JSON, but it fails schema validation. The error response should instead include the actual invalid payload that failed validation (from MESSAGE or DETAIL, depending on which field was used/failed), so the user can see what was provided and why it is being rejected.

Reproduction example (conceptual): a function raises an error like:

RAISE EXCEPTION USING
  ERRCODE = 'PGRST',
  MESSAGE = '{"status":200}',
  DETAIL  = '{"status": "not-a-number", "headers": []}';

If PostgREST cannot parse the provided MESSAGE/DETAIL into the required structure (e.g., wrong types, missing required keys, headers not an object, status not an integer), the resulting PGRST121 error should mention which field failed (MESSAGE or DETAIL) and echo the offending JSON content in the error message so it’s clear what was rejected.

Expected behavior: PGRST121 error messages should show the failed MESSAGE or DETAIL JSON value (whichever was invalid), rather than only stating that JSON was expected.

Actual behavior: PGRST121 error messages claim the field "expects JSON" even when JSON was provided but did not conform to the required schema, and they do not show the invalid payload.