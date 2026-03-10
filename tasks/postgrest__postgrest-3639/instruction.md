When using embedded resources only to apply filters/joins (e.g., `!inner`) but not to actually select any columns from that embedded resource, PostgREST currently returns “empty” embedded objects/arrays in the JSON response. This makes it impossible to filter through an embedded relationship without also getting a useless placeholder embed in the output.

Reproduction example (many-to-many through a join table):

```http
GET /tags?select=*,post_tag!inner(posts!inner())&post_tag.posts.status=eq.published
```

Expected behavior: the request should filter `tags` to only those linked to `published` posts, but because no fields were selected from `post_tag` (and `posts` is only used to filter via the inner join), the response should not include a `post_tag` key at all.

Actual behavior: the response includes the embedded relationship with empty values, e.g.:

```json
{
  "tag_id": "...",
  "name": "Hooks",
  "post_tag": [ {} ]
}
```

This should also work correctly for deeper nesting: if an embed tree contains nodes that end up with no selected fields (because they’re only used for filtering/inner joins), those nodes must be omitted from the final JSON rather than rendered as `{}` or `[{}]`. In other words, nested empty embeds must not produce empty objects/arrays, and should be correctly excluded from the output while preserving the filtering semantics of `!inner` embeds.

Fix the embed rendering/planning so that embeds with no selected fields do not appear in the response, including when they are nested within other embeds, while ensuring the underlying join/filter still applies and the correct rows are returned.