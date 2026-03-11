Generating a new Phoenix context currently introduces an unused default argument in some generated functions (notably the "create_*" function). This unused default makes code coverage tools report a false negative for the function body, even when the function is exercised in tests.

You can reproduce in a fresh project by running:

```bash
mix phx.new foo
cd foo
mix phx.gen.context Accounts User users name:string
mix test --cover
```

Then inspect the coverage report for the generated context module and observe that the `create_user/1` function is shown as not covered even though it is called during the test run.

Expected behavior: calling the generated `create_user/1` function during tests should mark the corresponding line(s) in the generated context module as covered.

Actual behavior: the coverage report marks the `create_user/1` implementation as uncovered due to the unused default argument in the generated function signature.

Fix the generator so the generated context functions no longer include this unused default argument, while preserving the public API shape expected from generated contexts (in particular, `create_user/1` should remain callable as generated and should not introduce additional unused defaults that can confuse coverage).