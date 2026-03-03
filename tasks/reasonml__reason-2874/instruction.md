The Reason formatter/printer currently prints certain pattern-constraint constructs ambiguously because it fails to distinguish between a pattern constraint node and a constrained value binding. In particular, when formatting code that uses a type constraint on the left-hand side of a binding (a pattern constraint), the printer can emit output that corresponds to a different AST shape (a value binding constraint), or otherwise loses the correct grouping/parenthesization.

This shows up in formatting round-trips where code like a constrained pattern binding (conceptually: binding where the pattern is constrained, e.g. `(x: t) = expr` or similar constraint forms used in bindings/patterns) is printed in a way that makes it look like the constraint is applied to the entire binding/value rather than to the pattern itself. As a result, running the formatter and then reparsing the formatted output can change the meaning/AST, or produce formatting that differs from the expected canonical form.

Update the printer so it correctly distinguishes AST nodes representing `Ppat_constraint` versus constraints that belong to a `value_binding`, and prints them with the correct syntax and necessary parentheses so that:

- A constraint that is part of the pattern is printed as a pattern constraint (and stays attached to the pattern after formatting).
- A constraint that applies to the bound expression/value binding is printed in the value-binding form (and stays attached to the binding/value after formatting).
- Formatting is stable: formatting output should reformat to the same output again, and reparsing formatted output should preserve the original AST structure with respect to where the constraint lives.

If a binding involves both a pattern that could be constrained and an expression that could also be constrained, the output must be unambiguous and preserve the intended attachment point of each constraint.