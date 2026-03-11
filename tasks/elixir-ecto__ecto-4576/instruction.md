Ecto.Repo is missing a convenience function for fetching multiple rows by keyword conditions, analogous to Repo.get_by/3. Users can call Repo.get_by(queryable, clauses, opts) to fetch a single result, but there is no Repo.all_by(queryable, clauses, opts) to fetch all matching results.

Implement Repo.all_by/3 as a public Repo function that mirrors the behavior and options of Repo.get_by/3, except that it returns all matching rows (like Repo.all/2) instead of a single struct (like Repo.one/2). It must accept the same kinds of inputs as Repo.get_by/3:

- queryable can be a schema module or an Ecto.Query
- clauses is a keyword list of field/value pairs (and should support the same semantics as get_by for building the where conditions)
- opts is the same options keyword list accepted by Repo.all/2 and Repo.get_by/3, including (but not limited to) options such as :prefix and any repo-specific query options

Expected behavior:

- Repo.all_by(MySchema, [field: value]) returns a list of all structs matching the given clauses.
- Repo.all_by(from(s in MySchema, where: ...), [field: value]) applies the additional clauses on top of the existing query and returns all matches.
- When no rows match, it returns an empty list.
- It must respect schema prefixes and explicit :prefix options the same way Repo.get_by/3 does, including interactions with associations and schemas that define @schema_prefix.

Current behavior is that calling Repo.all_by/3 fails because the function does not exist, preventing users from using a symmetrical API to fetch all records by clauses.