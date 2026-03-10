PostgREST currently exposes database values using their internal PostgreSQL representation, which makes it difficult to present “external” representations per column (e.g., store a color as an int4 but expose it as a CSS hex string, or present UUIDs in base58) without resorting to views, triggers, custom C extensions, or proxy-level JSON rewriting.

Implement support for domain-based transformations (“domain representations”) so that PostgREST can automatically format values on output and parse values on input on a per-column basis, using PostgreSQL functions associated with a domain type.

When a table column is typed as a domain that defines a distinct external representation, PostgREST should:

- On SELECT responses (including embedding and computed relationships), return the formatted external representation rather than the underlying stored value.
- On INSERT/UPDATE/PATCH payloads, accept the external representation and correctly parse/convert it to the stored/internal type.
- Support filtering and other query operations against the external representation in a way that still produces correct results (i.e., a client filtering by the formatted value should match the appropriate rows).
- Preserve relationship detection and embedding behavior when a foreign key column uses a domain representation; embedding should continue to work rather than breaking due to the representation layer.
- Work consistently for computed relationships (e.g., relationships exposed via computed functions) so that embedding computed relations continues to behave correctly while applying the relevant representations.

The feature should be driven by schema cache introspection: after loading the schema cache, PostgREST must know which columns are domain-typed and what formatting/parsing functions (or equivalent transformation definitions) apply, and then use that information during planning/execution.

Example scenario that should work end-to-end:

- A domain represents an externally-visible string (like a hex color or base58 UUID) while storing as a more efficient internal type.
- A client can POST/PUT/PATCH with the external string value and PostgREST stores the correct internal value.
- A client can GET the resource and receives the external string value back.
- A client can embed related resources across foreign keys involving such domain-typed columns and still get correct embedding output.

If the domain transformation cannot be applied (e.g., missing/invalid transformation functions, or an input value cannot be parsed), PostgREST should fail the request with a clear error indicating the representation/parsing problem rather than a confusing “column does not exist”/type mismatch style message.

Ensure this works across multiple schemas and in the presence of computed relationships, including many-to-one and one-to-many embedding patterns, and combinations with inner joins and exact counts.