PostgREST’s `jwt-role-claim-key` configuration does not correctly support selecting a role from a JWT claim that contains an array of roles when the selection expression uses string comparison predicates. This prevents common JWT providers (e.g., Keycloak) from working when roles are emitted as a list.

A typical JWT contains roles like:

```json
{
  "realm_access": {
    "roles": ["role1", "role2"]
  }
}
```

When `jwt-role-claim-key` is configured to point at the roles array (for example `.realm_access.roles`), PostgREST treats the resulting array as a single string value instead of extracting a single role. The server then attempts to `SET ROLE` to the literal array representation and fails with an error such as:

```json
{"hint":null,"details":null,"code":"22023","message":"role \"[\"role1\",\"role2\"]\" does not exist"}
```

This is currently only avoidable by hardcoding an index (e.g. `.realm_access.roles[0]`), which is not acceptable because role ordering is not guaranteed.

`jwt-role-claim-key` should support JSONPath filter predicates that compare each array element as a string and select matching roles. In particular, configuration values like the following must be accepted and preserved by config parsing/dumping, and must work for role extraction:

- `.roles[?(@ == "role1")]`
- `.roles[?(@ != "role1")]`
- `.roles[?(@ ^== "role1")]`
- `.roles[?(@ ==^ "role1")]`
- `.roles[?(@ *== "role1")]`

Expected behavior:
- PostgREST should parse `jwt-role-claim-key` values containing these string-comparison operators without rejecting or mis-parsing them.
- When the JWT claim resolves to an array, applying a JSONPath filter like `?(@ == "role1")` should result in selecting the matching role value(s) as proper strings, so PostgREST can correctly use an actual database role name (e.g., `role1`) instead of a serialized JSON array.
- `--dump-config` output should represent the JSONPath in a valid, quoted form (e.g., ensuring property names like `roles` are quoted as needed), without altering the meaning of the expression.

Actual behavior:
- String comparison predicates in the JSONPath for `jwt-role-claim-key` are not supported/handled correctly, causing either incorrect parsing/quoting of the expression or incorrect evaluation that yields an array/stringified array rather than a role string, resulting in the database error about a non-existent role.