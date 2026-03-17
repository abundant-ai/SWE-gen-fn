When a project depends on a local/path dependency, and that dependency reads compile-time configuration via `Application.compile_env/2` (or related compile-time env APIs), changing the compile-time configuration currently triggers a full recompilation of the entire path dependency. This is overly broad and causes unnecessary recompilation of modules that do not actually depend on the compile-time configuration.

Reproduction scenario: create a project that depends on a path dependency (a dependency pulled from a local directory). In the dependency, have at least one module (or top-level code evaluated at compile time) call `Application.compile_env(:some_app, :some_key)` (or equivalent). Compile the project, then change the compile-time configuration value for that app/key and compile again.

Actual behavior: the next compilation recompiles the whole path dependency (all modules in that dependency), even though only some modules actually access compile-time env.

Expected behavior: changing compile-time configuration should only force recompilation of the modules within the path dependency that actually access compile-time env (directly or through compile-time evaluation), and it should not trigger a full recompilation of the entire dependency when only a subset of modules are affected.

The dependency compilation tracking should correctly record compile-time env usage at module granularity and use that information during incremental recompilation so that unaffected modules remain up-to-date and are not recompiled unnecessarily.