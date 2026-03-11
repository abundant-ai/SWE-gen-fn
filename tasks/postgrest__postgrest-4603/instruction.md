JWT role extraction currently supports navigating JSON claims via a configured `jwt-role-claim-key` (e.g., object keys and array indexing), but it cannot transform string values. This makes it impossible to derive roles from JWT claims whose string values need trimming or substring extraction.

A concrete case is WLCG IAM tokens where groups are stored under a claim like `postgrest.wlcg.groups` and each group is a string prefixed with `/`, e.g.:

```json
{
  "postgrest": {
    "wlcg.groups": ["/groupa", "/groupb", "/groupa/subgroupa1"]
  }
}
```

If `jwt-role-claim-key` is configured as:

```text
jwt-role-claim-key = ".postgrest.wlcg.groups[0]"
```

the extracted role becomes `/groupa`, but the expected role is `groupa` (without the leading slash). There is currently no supported syntax to trim or slice the string after selecting it.

Extend `jwt-role-claim-key` so it supports a string slicing operator using bracket syntax with a start/end range, so users can select a substring from a string claim value. After this change, configurations like the following should be supported:

```text
jwt-role-claim-key = ".postgrest.wlcg.groups[0][1:]"
```

and should result in the role `groupa` when the first group is `/groupa`.

The slicing operator must work after other navigation operators (e.g., after selecting an array element), and it must only apply to string values; non-string values should not be treated as sliceable strings. Slicing should allow omitting the end bound to mean “to the end of the string” (as in `[1:]`).