Filtering IDE results by “dependencies” is currently too indirect and fails to correctly scope declarations to what is actually in scope for the module being edited, especially for data constructors imported via explicit import lists.

When the IDE client (eg a language server) wants to request information relevant to the current module context (hover, completion, etc.), it needs a way to filter the available declarations down to those brought into scope by the module’s imports. Today, clients often approximate this by filtering modules where an identifier appears in an explicit import list or the import is open, but this breaks for cases like data constructors: a constructor can be in scope due to a type import like `import Data.Maybe (Maybe(Just))`, even though the constructor name is not imported as a standalone value.

Implement a dependency/imports-based filter that accepts the current module name, an optional qualifier, and a list of import lines (typically the import section text from the module being edited). Using those import lines, compute which modules/declarations are brought into scope and filter IDE results accordingly.

The filter must correctly handle:

- Open imports (eg `import Prelude`): all exported declarations from that module are in scope.
- Explicit import lists (eg `import Data.Array (head, cons)`): only the listed declarations are in scope.
- Type imports with data constructors (eg `import Data.Maybe (Maybe(Just))` and similar forms like `Foo(A, B)`): the specified constructors must be treated as in-scope declarations as well, so queries for `Just` (or `A`/`B`) are correctly included.
- Qualified imports (eg `import Effect.Console (log) as Console` and `import Data.List as List`):
  - If a qualifier is provided to the filter (eg `Console`), only declarations available through that qualifier should be included.
  - If no qualifier is provided, include unqualified in-scope declarations (and do not include qualified-only names unless they are also imported unqualified).
- Current module name handling: the filter must be able to parse import lines relative to a given “current module name” context.

Expose this behavior through the existing IDE filtering mechanism so that applying the dependency/imports filter to a module map of declarations yields only the modules/declarations that are in scope according to the provided import lines. The entry point for this behavior is the IDE filter function named `dependencyFilter`, which is used via `applyFilters`.

Expected behavior example scenarios:

- Given imports `["import Prelude"]`, results should be limited to declarations from `Prelude` (and not from unrelated modules).
- Given imports `["import Data.Array (head, cons)"]`, results should include `head` and `cons` from `Data.Array` but exclude other `Data.Array` declarations.
- Given imports `["import Data.Maybe (Maybe(Just))"]`, a query scoped by this filter must treat `Just` as in scope.
- Given imports `["import Effect.Console (log) as Console"]` and qualifier `Console`, the filter should include `log` but only in its qualified form context.

Currently, data constructors imported via explicit import lists are not correctly captured by dependency-based scoping, leading to missing or incorrect hover/completion results. After this change, the dependency/imports filter must correctly include those constructors and generally scope IDE results to what the provided import list brings into scope.