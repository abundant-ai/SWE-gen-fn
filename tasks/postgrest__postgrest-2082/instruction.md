When PostgREST returns an error due to an embedding/relationship resolution failure, the error response should include an additional actionable hint telling the user to verify that the referenced tables and foreign key relationship actually exist in the database (before restarting/reloading the schema cache).

Currently, when an embed fails because no relationship can be resolved (e.g., the requested embedded resource name does not correspond to a valid relationship from the source resource), the response does not provide guidance about the common root cause where the underlying tables or foreign keys are missing/renamed/dropped. Users may restart the schema cache, but if the relationship is invalid in the database, that will not help.

Update the relationship/embedding error handling so that the JSON error body includes a `hint` string that recommends verifying:

- the existence of the involved tables/views in the database, and
- the existence/correctness of the foreign key relationship between them,

before restarting the schema cache.

This should apply to relationship errors produced by embedding requests (for example requests like `GET /message?select=id,body,sender(name)` or `GET /sites?select=*,big_projects(*)` where relationship resolution fails). The existing hint behavior for ambiguous relationship errors (where multiple relationships are found and the user must disambiguate using `!<relationship>`) must remain intact; the new guidance should be added in a way that does not remove or contradict the current disambiguation hint content.

Expected behavior: error responses for relationship/embedding failures include the new hint about checking table and foreign key existence (and still include any existing disambiguation guidance when the error is ambiguity-related). Actual behavior: the response lacks this additional guidance.