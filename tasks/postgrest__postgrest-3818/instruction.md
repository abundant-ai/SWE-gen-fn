PostgREST currently rejects filters that try to express “IS NOT NULL” using the `is` operator with a `not null`-like value. For example, a request such as `GET /no_pk?a=is.not_null` (or equivalently `a=is.not+null` depending on encoding) should be accepted as a valid filter meaning `a IS NOT NULL`, but instead PostgREST fails to parse the filter value and returns an error like:

`failed to parse filter (is.not null)`

This makes it difficult to build dynamic query builders because users must instead negate `is.null` (i.e., `a=not.is.null`) rather than being able to express `is.not_null` directly.

Update filter parsing and query translation so that:

- `is.null` continues to work as `IS NULL`.
- `not.is.null` continues to work as `IS NOT NULL`.
- `is.not_null` is accepted and behaves the same as `IS NOT NULL`.
- `not.is.not_null` is accepted and behaves the same as `IS NULL`.

The behavior should be consistent across column types (e.g., varchar and numeric fields). Requests using these filters should return the correct rows rather than a parse error.