Intermittent compile-time warnings are emitted for valid Ecto associations, such as:

warning: invalid association `family` in schema Core.UserDevices.UserDevice: associated module Core.Families.Family is not an Ecto schema

This warning is a false positive: the associated module is a real Ecto schema at runtime and the application behaves correctly. The warning appears nondeterministically during compilation (including when running `mix test`), suggesting it depends on compilation order and whether the associated module’s schema metadata (like `__schema__/1`) is available at the time association validation runs.

The association verification/validation logic needs to be changed so that association checks do not incorrectly conclude that the associated module “is not an Ecto schema” when the module is valid but not yet fully verified/available during compilation. In particular, association validation should be performed after the compiler has verified modules rather than during earlier compile-time phases that can observe incomplete module state.

When defining schemas using `use Ecto.Schema` with associations such as `belongs_to/3`, `has_many/3`, etc., compiling the project should not emit “invalid association … associated module … is not an Ecto schema” warnings for valid schemas, even under parallel or nondeterministic compilation order.

Expected behavior: Valid associations between two Ecto schemas compile cleanly with no warnings, regardless of compilation order.

Actual behavior: Compilation intermittently emits the warning above even though the associated module is a proper Ecto schema and works at runtime.