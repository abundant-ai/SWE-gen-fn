When a client requests a query plan using the plan media type, PostgREST should return a JSON plan response that preserves existing behavior for total cost reporting and optional EXPLAIN settings. After the refactor that removed the old QueryCost logic and switched to using PlanSpec, plan responses can regress: total cost may not be correctly extracted/returned, and the plan output may ignore or mishandle plan options like buffers.

Reproducible scenarios:

1) Total cost for a filtered table read
- Make a GET request to /projects?id=in.(1,2,3) with an Accept header of application/vnd.pgrst.plan+json.
- Expected: HTTP 200, and Content-Type exactly application/vnd.pgrst.plan+json; charset=utf-8.
- Expected: the JSON response includes a plan from which the “total cost” can be determined, and the extracted total cost must match PostgreSQL’s EXPLAIN total cost for this query. For PostgreSQL versions > 12.0 the expected total cost is 15.63; for PostgreSQL 12.0 and below the expected total cost is 15.69.

2) Total cost for a filtered view read
- Make a GET request to /projects_view?id=gt.2 with Accept: application/vnd.pgrst.plan+json.
- Expected: HTTP 200, Content-Type application/vnd.pgrst.plan+json; charset=utf-8.
- Expected: the extracted total cost matches PostgreSQL’s EXPLAIN total cost. For PostgreSQL versions > 12.0 the expected total cost is 24.28; for PostgreSQL 12.0 and below the expected total cost is 32.28.

3) Buffers option must surface block metrics (PostgreSQL >= 13)
- Make a GET request to /projects with Accept: application/vnd.pgrst.plan+json; options=buffers.
- Expected: HTTP 200 and Content-Type exactly application/vnd.pgrst.plan+json; options=buffers; charset=utf-8.
- Expected: the JSON plan output includes buffer/block information in the planning/execution details (e.g., keys like "Shared Hit Blocks", "Shared Read Blocks", "Local Hit Blocks", etc.). This data must be present when the buffers option is requested, and absent when it is not.

The fix should ensure that the PlanSpec-based plan parsing/encoding preserves these behaviors: correct total cost extraction for table and view reads across PostgreSQL versions, correct propagation of the plan media type and its parameters into the response Content-Type, and correct handling of EXPLAIN options such as buffers so that the corresponding block metrics appear in the returned plan JSON.