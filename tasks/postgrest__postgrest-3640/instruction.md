The spread operator (`...`) in PostgREST select embeddings currently works for `one-to-one` and `many-to-one` relationships, but it does not work correctly for `to-many` relationships (including `one-to-many` and `many-to-many`). This prevents users from flattening fields/aggregations from to-many embeds into the parent row, and also makes it hard to order by those flattened fields.

Implement spread support for to-many relationships so that using `...<relationship>(...)` can project values/aggregates from the related set into the parent object.

When a to-many spread selects a single scalar column, the parent response should include an array of those scalar values (rather than an array of objects). For example:

```http
GET /posts?select=title,tags(...name)
```

Expected JSON shape:

```json
[
  {
    "title": "post title",
    "tags": ["technology", "buddy"]
  }
]
```

The spread operator must also work with aggregations on to-many relationships, including aliasing of the aggregate result. For example, flattening a count into the parent row:

```http
GET /posts?select=title,...hearts(hearts_count:count)
```

Expected JSON shape:

```json
[
  {
    "title": "post title",
    "hearts_count": 10
  }
]
```

Ordering must work on fields introduced via a spread alias, especially for aggregates, e.g.:

```http
GET /posts?select=title,...hearts(hearts_count:count)&order=hearts_count.desc
```

This should successfully sort by the computed/aggregated field and not error due to the field coming from a spread embed.

Spread should work across multiple embed levels, including when a many-to-many relationship is modeled via a junction table. For example:

```http
GET /posts?select=title,...posts_tags(tags(...name))
```

Expected JSON shape:

```json
[
  {
    "title": "post title",
    "tags": ["technology", "food"]
  }
]
```

Additionally, spread should work for many-to-many embeddings where the junction table’s attributes may be included or excluded alongside the spread of the target table. For example, embedding a junction relation while spreading the referenced table’s columns should produce rows where junction columns and target-table columns are both present in each embedded array element.

Overall, `...` must behave consistently regardless of relationship cardinality (one-to-one, many-to-one, one-to-many, many-to-many), and it must support aliasing, nested spreads, and aggregate projections without breaking ordering on the resulting flattened fields.