Calling `Repo.insert_all/3` with an `Ecto.Query` as the source fails when the query’s `select` uses Elixir’s map update syntax (`%{struct | field: value}`) against a schema struct.

For example, given a schema like:

```elixir
defmodule ImageCommentNotification do
  use Ecto.Schema

  @primary_key false
  schema "image_comment_notifications" do
    belongs_to :user, User, primary_key: true
    belongs_to :image, Image, primary_key: true
    belongs_to :comment, Comment
    field :read, :boolean, default: false
    timestamps(type: :utc_datetime)
  end
end
```

and a query that selects an updated version of the same schema struct:

```elixir
new_comment_notifications =
  from cn in ImageCommentNotification,
    where: cn.image_id == ^source.id,
    select: %{cn | image_id: ^target.id}

Repo.insert_all(ImageCommentNotification, new_comment_notifications, on_conflict: :nothing)
```

Ecto currently generates invalid SQL and raises an error like:

```elixir
** (Postgrex.Error) ERROR 42703 (undefined_column) column "|" of relation "image_comment_notifications" does not exist
```

The generated `INSERT` incorrectly treats the map update operator (`|`) as if it were a column name, resulting in an `INSERT INTO ... ("|") (SELECT ...)` shape.

`Repo.insert_all/3` should support using a query as the insert source even when the query `select` returns a schema struct updated via map update syntax. In this case, Ecto should correctly expand the selected struct into the set of fields being inserted (respecting schema sources and excluding virtual fields), and apply the overridden field values (like `image_id`) as part of the select expression so the SQL insert has the proper target columns.

At minimum, the following should work without raising and should insert the expected rows (or no-op with `on_conflict: :nothing`):

1) `Repo.insert_all(SchemaModule, query_selecting_%{schema_struct | field: value}, opts)`

Additionally, selecting only a source struct (i.e., selecting the schema source itself from a query used as `insert_all` input) should be supported as a valid insert source so rows can be moved/copied between tables or within a table, as long as the selected struct can be expanded into insertable fields.

If there are unsupported shapes that cannot be safely expanded, Ecto should raise a clear `Ecto.QueryError` explaining that `insert_all` with a query source requires selecting a plain map or a schema source that can be expanded into insertable fields, rather than emitting malformed SQL.