Embedding becomes ambiguous and fails with `300 Multiple Choices` when a view exists that can be reached via the same foreign key path as a table, even if the request clearly intends to embed the table. This can break previously working requests simply by adding an unrelated view.

Reproduction example:

```sql
CREATE TABLE series (
  id bigint PRIMARY KEY,
  title text NOT NULL
);

CREATE TABLE adaptation_notifications (
  id bigint PRIMARY KEY,
  series bigint REFERENCES series(id),
  status text
);

CREATE VIEW series_popularity AS
SELECT id, random() AS popularity_score
FROM series;
```

Requesting an embed by using the foreign-key column name as the embed target:

```http
GET /adaptation_notifications?select=id,status,series(*)
```

Currently returns `300 Multiple Choices` with error code `PGRST201`, because PostgREST finds more than one relationship for `adaptation_notifications` and `series` (one to the table `series`, and another to the view `series_popularity`). The response includes details similar to:

- `adaptation_notifications` many-to-one `series`
- `adaptation_notifications` many-to-one `series_popularity`

and a hint suggesting disambiguation, e.g. `series!adaptation_notifications_series_fkey` or `series_popularity!adaptation_notifications_series_fkey`.

However, attempting to disambiguate using the “target” syntax with a column/FK name does not work in this situation. Requests like the following still fail with the same ambiguity:

```http
GET /adaptation_notifications?select=id,status,series!adaptation_notifications_series_fkey(*)
GET /adaptation_notifications?select=id,status,series!series(*)
```

At the same time, explicitly embedding the view works:

```http
GET /adaptation_notifications?select=id,status,series_popularity(*)
```

The expected behavior is:

1) When using a column name or foreign key name as the embedding target (e.g. `series(*)` where `series` is a FK column on the origin table), PostgREST should only consider relationships that embed tables, not views. Adding views must not make these table-oriented embeds ambiguous or break existing requests.

2) When the origin resource is a view, embedding via a column/FK name should still be able to resolve to the underlying table relationships (so views can continue to embed tables through their columns).

3) Self-referencing relationships should be disambiguatable when embedding from views using the column-as-target form. For example, a self-referencing table like:

```sql
CREATE TABLE test (
  id bigint PRIMARY KEY,
  parent_id bigint REFERENCES test(id)
);
```

should allow embedding the parent row via a relationship keyed by `parent_id` even if a view exists over the same table, without turning the request into an unsolvable ambiguity.

After implementing the above, requests that previously returned `PGRST201`/`300 Multiple Choices` due solely to the presence of a view should instead embed the table relationship successfully, and view relationships should only be chosen when explicitly requested by naming the view in the embed target.