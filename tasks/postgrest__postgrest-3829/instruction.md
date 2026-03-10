Bulk inserts that use the HTTP preference `Prefer: missing=default` currently pick the wrong default value when inserting into a column typed as a domain that also has its own default.

PostgreSQL default precedence is:
1) column default (if defined)
2) domain default (if column default is not defined)
3) underlying type default

However, PostgREST currently uses the domain default even when the column has an explicit default.

Reproduction scenario (SQL):

```sql
create domain defdom as integer default 1;

create table test_defdom (
  id int primary key,
  val defdom default 10
);
```

Then insert a row while omitting `val` but requesting missing fields be filled with defaults:

```bash
curl -X POST 'http://localhost:3000/test_defdom?columns=id,val' \
  -H 'Content-Type: application/json' \
  -H 'Prefer: missing=default, return=representation' \
  -d '[{"id": 1}]'
```

Expected response body (column default 10 should be applied):

```json
[{"id":1,"val":10}]
```

Actual response body (domain default 1 is applied incorrectly):

```json
[{"id":1,"val":1}]
```

Fix PostgREST so that when `Prefer: missing=default` is used and a JSON object in a bulk insert omits a column, the inserted value uses the column’s default expression if the column defines one; only if the column has no default should the domain default be used. This should work for bulk inserts (JSON arrays) and return correct values when `return=representation` is requested.