When embedding resources, PostgREST incorrectly exposes and considers foreign-key relationships that are only partially visible through views, which can make otherwise valid embeds fail with an ambiguity error.

Given a database where the exposed schema contains views that only project a subset of columns from underlying tables, only relationships whose referencing and referenced columns are all exposed by the views should be eligible for embedding/disambiguation.

Repro schema (conceptual):
- A table `ta(a1 primary key, a2, unique(a1,a2))`.
- A table `tb(b1 references ta(a1), b2, foreign key (b1,b2) references ta(a1,a2))`.
- In the exposed schema, a view `va` that selects only `a1` from `ta`.
- In the exposed schema, a view `vb` that selects only `b1` from `tb`.

In this setup, only the relationship based on `b1 -> a1` is actually representable through the exposed views. The composite foreign key `(b1,b2) -> (a1,a2)` should not be considered because `b2` (and `a2`) are not exposed by the views.

However, a request like:

```http
GET /va?select=vb(*)
```

currently fails with:
- HTTP status 300
- error code `PGRST201`
- message: `Could not embed because more than one relationship was found for 'va' and 'vb'`
- and a hint suggesting disambiguation options including both the simple FK and the composite FK (e.g. `vb!tb_b1_fkey` and `vb!tb_b1_b2_fkey`).

Expected behavior:
- PostgREST must not surface relationships for embedding/disambiguation when not all FK column pairs are exposed through the participating views.
- In the example above, embedding `vb(*)` into `va` should succeed without requiring any explicit disambiguation, because only one valid relationship remains after filtering to visible columns.
- More generally, when building the schema cache and when determining embeddable relationships between resources, relationships involving hidden/unselected columns must be excluded so they cannot cause `PGRST201` ambiguity errors.

Also ensure existing embed disambiguation behavior remains correct for genuinely ambiguous cases (e.g. when multiple valid relationships exist such as many-to-one vs many-to-many, or circular references), still returning `PGRST201` with status 300 and the corresponding `details`/`hint` fields.