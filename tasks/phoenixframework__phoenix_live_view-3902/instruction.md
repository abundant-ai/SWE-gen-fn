Rendering in Phoenix LiveView currently emits an unnecessarily complex rendered structure for templates that contain no dynamic segments. Even when a template is fully static (or otherwise produces no dynamic parts after compilation), the engine still builds and returns a dynamic function/structure as if dynamics were present, which adds overhead and can change the shape of the produced rendered output.

Adjust the template compilation/emission so that when there are no dynamic segments, the emitted code is simplified and does not allocate or execute a dynamic function for the rendered result.

The rendered structure produced by evaluating templates must continue to behave as follows:

- For templates that include dynamics like "foo<%= 123 %>bar", evaluation should yield a rendered value whose `static` is `{"foo", "bar"}`-equivalent (two static parts surrounding the dynamic), and whose `dynamic` callable returns the list of dynamic string parts (e.g. `["123"]`) when invoked.
- For templates where dynamics appear at the beginning or end, the `static` list must include empty strings as placeholders (e.g. "foo<%= 123 %>" results in `static == ["foo", ""]`, and "<%= 123 %>bar" results in `static == ["", "bar"]`).
- For templates that consist only of dynamics, `static` must still be `["", ""]` and the `dynamic` callable must return all dynamic parts in order (e.g. "<%= 123 %><%= 456 %>" returns `["123", "456"]`).

In addition, for templates with no dynamic segments at all (for example, plain text/HTML with no `<%=` interpolations), the evaluation result should be simplified so it does not include or rely on a dynamic function to produce output; rendering such a template should be equivalent to directly returning the static content.

All existing escaping and safety rules must remain unchanged: HTML in regular expressions must be escaped, nested content is treated as safe, `{:safe, iodata}` must not be escaped, and accessing missing assigns (e.g. using `@foo` when `foo` is not provided) must still raise `KeyError`.