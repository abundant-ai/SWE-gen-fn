When an incoming request contains an invalid resource embedding (for example, requesting an embed for a relationship that does not exist), PostgREST correctly returns an error response (e.g., code "PGRST200" with message "Could not find a relationship between 'projects' and 'wrong' in the schema cache"), but it still opens and commits a database transaction before returning the error.

This is visible when making a request like:

curl 'http://localhost:3000/projects?select=*,wrong(*)'

Even though the response is an error about failing to find the relationship, the server logs show it executes a transaction sequence (BEGIN ... followed by setting request-local GUCs via set_config, then COMMIT). The expected behavior is that a failed embed/relationship planning error should be detected before any transaction is started, so no BEGIN/COMMIT should occur for this request.

Fix the request processing so that planning/validation for embeds (the logic that validates relationships using the schema cache/DbStructure and produces a query plan) happens prior to starting a transaction. In particular, if planning fails with the relationship-not-found error, PostgREST must return the same error response but must not open a transaction or run any SQL (including set_config statements). This should apply to GET requests and similarly to other request types where the failure occurs before any query can be executed.

As part of this refactor, the planning boundary should be explicit (e.g., a function shaped like plan :: DbStructure -> Request -> Either PlanError QueryPlan), and errors produced at the planning stage must short-circuit execution so that query execution/transaction setup is never entered.