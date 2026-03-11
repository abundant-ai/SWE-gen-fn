OpenAPI output is missing primary-key markers for views. In the generated OpenAPI schema, primary key columns should include a description containing the exact marker string `This is a Primary key.<pk/>`. This marker is still present for table primary key columns, but for views it regressed and no longer appears after recent refactoring.

When a database view has a primary key (or a set of columns that PostgREST treats as the view’s primary key), the OpenAPI document returned by the API must mark those columns the same way it does for tables: the column’s OpenAPI description must include `This is a Primary key.<pk/>`. Client libraries depend on the presence of the `<pk/>` marker to detect primary keys.

Currently, calling the OpenAPI endpoint (e.g. requesting the OpenAPI JSON via the root endpoint with `Accept: application/openapi+json`) produces schema definitions where view columns that are part of the view’s primary key do not include the PK description marker, even though they should.

Additionally, primary key detection for views must be correct: columns that are merely foreign key columns must not be incorrectly classified as primary key columns on views. The primary key columns for tables should be obtained from database metadata, and primary key columns for views should be derived in a way that reflects the view’s key dependencies (so that only the correct key columns are marked as PK). The ordering of relationship/join columns used to derive these dependencies must be stable and deterministic.

Expected behavior: OpenAPI generation marks PK columns for both tables and views by adding `This is a Primary key.<pk/>` to the column description, and view PK classification does not mistakenly tag FK columns as PK.

Actual behavior: For views, PK columns are not marked with `This is a Primary key.<pk/>` in OpenAPI output; in some cases a view FK column may be wrongly considered a PK column.