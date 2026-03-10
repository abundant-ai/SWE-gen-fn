A regression introduced in v11.0.0 causes PostgREST to incorrectly reject normal column filters when the filter key matches the name of an embedded resource.

Given a table with foreign keys like `user_friend.user1 -> profiles.id` and a request that embeds the related resource using `select=*,user1(*),user2(*)`, filtering by the FK column using `&user1=eq.<uuid>` should work as a regular column filter on `user_friend.user1`.

Instead, PostgREST interprets `user1=eq.<uuid>` as a filter on the embedded resource `user1` (the relationship name), which triggers the embedded-resource null-filtering restriction. The request fails with:

```json
{"code":"PGRST120","details":"Only is null or not is null filters are allowed on embedded resources","hint":null,"message":"Bad operator on the 'user1' embedded resource"}
```

This is especially problematic when a column name is the same as a relationship/embed name (e.g., a FK column `user1` and an embedded relationship also named `user1`). Users currently must work around it by disambiguating the embed with explicit relationship syntax and aliases (e.g., `profile1:profiles!user1(*)`) just to be able to filter the base column.

PostgREST should accept non-null operators like `eq`, `gt`, etc. when the target is a base table column (e.g., `user_friend.user1`), even if there is also an embedded resource with the same name in `select`. Embedded-resource filtering should not “steal” such filters and incorrectly apply the embedded null-filtering rule.

After the fix, requests like the following should succeed and return matching rows rather than erroring:

```
GET /user_friend?select=*,user1(*),user2(*)&user1=eq.a02fb934-3a4d-469b-a6b6-4fcd88b973cf
```

The embedded-resource null filtering behavior (allowing only `is.null` / `not.is.null` when the filter is truly targeting an embedded resource) must still be preserved for actual embedded-resource filters; the bug is specifically about incorrect interpretation/disambiguation when `column = relation` name collisions occur.