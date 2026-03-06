Generating an OpenAPI spec can produce invalid Swagger/OpenAPI JSON because the reusable `preferParams` parameter is emitted with an empty `enum` array.

This is observable when requesting the OpenAPI document (e.g. with `Accept: application/openapi+json`) and inspecting the generated schema under `parameters.preferParams`. In some setups (notably when using `/rpc/login` from the SQL user-management tutorial), the OpenAPI output contains:

```yaml
parameters:
  preferParams:
    name: Prefer
    description: Preference
    required: false
    enum: []
    in: header
    type: string
```

Many OpenAPI/Swagger validators reject this with an error like:

`Structural error at parameters.preferParams.enum: should NOT have fewer than 1 items (limit: 1)`

The OpenAPI generator should not emit an `enum` field at all when there are no allowed values to enumerate (or otherwise ensure that `enum` is never an empty array). After the fix, the OpenAPI document must validate successfully in common OpenAPI/Swagger validators, and `preferParams` must not contain an empty `enum` list.