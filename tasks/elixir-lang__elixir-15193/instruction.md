Mix’s dependency override mechanism is currently too coarse: when a dependency is marked with `override: true`, it forces that dependency version/source globally, but it does not allow selectively overriding only certain transitive dependencies while leaving other parts of the dependency graph intact.

This becomes a problem when a project needs to keep a parent dependency as-is, but override a specific dependency that appears deeper in the graph (or override one occurrence while not unintentionally forcing other, unrelated dependencies). In these cases, Mix either refuses the override as conflicting, or applies the override too broadly, leading to incorrect convergence results and/or dependency conflict errors.

Mix should allow overriding specific dependencies while converging dependencies, so that a user can declare an override for a particular app and have Mix pick that overridden requirement/source for that app, without requiring that the entire parent dependency chain be overridden. In other words, overrides should be able to target a specific dependency entry in the graph and replace that dependency’s definition during convergence, even if the dependency is brought in transitively.

When calling `Mix.Dep.Converger.converge/1` for a project that declares dependencies with `override: true`, dependency resolution should:

- Prefer the explicitly overridden dependency definition for the matching app.
- Allow the override to apply even when the dependency is introduced transitively by another dependency.
- Avoid incorrectly overriding other dependencies that are not the targeted app.
- Avoid raising dependency conflict errors in cases where the override is intended to resolve a conflict by selecting a specific dependency requirement/source.

The end result should be that converging dependencies produces a consistent dependency set where the specifically overridden dependency is the one selected by Mix, while the rest of the dependency graph remains consistent and unchanged except as required by normal resolution.