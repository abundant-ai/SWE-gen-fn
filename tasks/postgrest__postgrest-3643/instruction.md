Calling PostgreSQL functions (RPC) via PostgREST using HTTP GET can produce significantly worse query plans than running the same function call directly in SQL, especially for SQL functions that can be inlined and benefit from LIMIT pushdown.

For example, given a stable SQL function like:

```sql
create or replace function get_notifications (uid text, unseen_only boolean, max_num integer)
returns setof user_notifications language sql stable parallel safe as $$
  select *
  from user_notifications as n
  where n.user_id = uid
    and (not unseen_only or not ((n.data->'isSeen')::boolean))
  order by ((n.data->'createdTime')::bigint) desc
  limit max_num
$$;
```

Running it in SQL as:

```sql
explain analyze select * from get_notifications('AJw...', true, 300);
```

can use an index scan and execute quickly, while calling the same RPC through PostgREST (e.g. `/rpc/get_notifications?uid=AJw...&unseen_only=true&max_num=300` or an equivalent client RPC call) can result in a plan that scans the function in a way that prevents the planner from pushing `LIMIT` into the inlined function call, often showing up as a `Function Scan` plan node and slower execution.

This discrepancy happens because PostgREST is currently constructing the SQL for GET-based RPC calls by passing arguments as a JSON payload rather than as direct function arguments. That forces Postgres to use a calling expression shape (typically involving a LATERAL join/record expansion) that blocks inlining-related optimizations such as LIMIT pushdown.

Fix PostgREST so that when an RPC is invoked via HTTP GET, the generated SQL calls the function with its arguments directly (typed parameters in the function call), instead of wrapping the arguments into a JSON body that is then unpacked. After the change, explaining a GET-based RPC should yield a comparable query plan to the direct SQL call (notably allowing LIMIT to be pushed down and enabling index usage where applicable), and overall execution should no longer be significantly slower solely due to the way PostgREST passes parameters.

The change must preserve existing behavior for RPC invocation semantics (argument parsing and typing) and must not break query plan output endpoints (e.g., requests that ask for `application/vnd.pgrst.plan+json` should still return valid plan JSON with the correct content type).