PostgREST currently over-detects many-to-many (m2m) relationships and exposes them for embedding, which can cause previously working requests to fail with relationship ambiguity errors (HTTP 300 with code PGRST201) after upgrading or after adding new views/relationships.

This shows up when PostgREST auto-generates m2m relationships through “junction” tables too permissively. In schemas where a table has two foreign keys to two other tables, PostgREST may infer an m2m relationship even when the table is not a strict associative entity (e.g., it has a surrogate primary key and the FK columns are not part of the primary key). These extra inferred m2m relationships can create multiple possible embedding paths between resources and make embedding resolution ambiguous.

The relationship generation must be restricted so that PostgREST only auto-creates m2m relationships when the junction table is a strict junction:

- The junction table has foreign keys to exactly two other tables (for the m2m pairing), and
- The foreign key columns used for the pairing are included in the junction table’s primary key.

When the FK columns are not part of the primary key (typical “surrogate id” junction tables), PostgREST must not generate an automatic m2m relationship from that table.

After this change, embedding should no longer become unexpectedly ambiguous simply because additional objects (like views) exist or because a non-strict junction table exists; PostgREST should avoid offering unintended m2m relationship choices. Requests that embed related resources through explicit, unambiguous foreign-key relationships should continue to work, and the API should no longer return PGRST201 for cases that only became ambiguous due to these extra auto-generated m2m relationships.

Example of the kind of failure that should be avoided: a request like

GET /adaptation_notifications?select=id,status,series(*)

should not become ambiguous and return

HTTP 300 Multiple Choices
code: PGRST201
message: "Could not embed because more than one relationship was found for 'adaptation_notifications' and 'series'"

due solely to additional inferred relationships created by non-strict junction detection. The relationship inference should be conservative so that only strict junction tables generate m2m relationships.