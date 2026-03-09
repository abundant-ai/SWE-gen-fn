Pandoc’s LaTeX writer should support producing PDF/A, PDF/X, and PDF/UA compliant output by honoring a new document metadata field named `pdfstandard`. When a document is converted to LaTeX (`-t latex -s`) and the input metadata includes `pdfstandard`, the generated LaTeX must emit a `\DocumentMetadata{...}` block before `\documentclass` so that LaTeX’s PDF management can configure the requested standard.

Currently, users who need standards compliance (e.g., PDF/A for archiving or PDF/UA for accessibility) have to manually inject LaTeX code (such as loading `pdfx` and creating `\jobname.xmpdata`) and duplicate title/author/language metadata. Pandoc should instead generate the appropriate `\DocumentMetadata` configuration directly from document metadata.

The `pdfstandard` metadata value must accept either a single string (e.g. `ua-2`) or a list of standards (e.g. `['ua-2', 'a-4f']`). The produced LaTeX should set `pdfstandard={...}` with one or more standards and should enable XMP metadata (`xmp=true`). The document language must be forwarded into `\DocumentMetadata` as `lang=<lang>` when the document has `lang` metadata (e.g. `lang: en-US`).

Some standards require additional configuration:

- For PDF/UA (`ua-1`, `ua-2`), tagging must be enabled. The generated `\DocumentMetadata{...}` must include `tagging=on` when one of these standards is requested.
- For PDF/A conformance variants, Pandoc must infer the required PDF version unless the user explicitly supplies one. For example, when `pdfstandard: a-2b` is specified, the generated `\DocumentMetadata` must include `pdfversion=1.7`.
- If the user provides an explicit PDF version value (e.g. `1.7` or `2.0`) alongside the standards request, that explicit version must be used rather than inferred.

If a user specifies an unknown/unsupported standard name in `pdfstandard`, Pandoc must not fail the conversion, but it must emit a warning indicating the standard name is unsupported.

In addition, LaTeX kernel compatibility must be handled. For newer LaTeX kernels (notably when tagging is off and starting from the 2025-11-01 format), setting the standard and related metadata needs to be routed through the PDF management interface rather than relying solely on `\DocumentMetadata` keys directly. Pandoc should conditionally generate LaTeX that uses `\IfFormatAtLeastTF{2025-11-01}{...}{...}` to choose the correct setup path.

If `pdfstandard` is specified but the LaTeX kernel is too old to support this workflow reliably (kernel earlier than 2025-06-01), Pandoc must emit an error or warning explaining that the requested `pdfstandard` requires a newer LaTeX kernel.

Example expected behavior:

- Input metadata:
  ```yaml
  ---
  pdfstandard: a-2b
  lang: en-US
  ---
  ```
  Output LaTeX should include (before `\documentclass`):
  ```tex
  \DocumentMetadata{
    pdfversion=1.7,
    pdfstandard={a-2b},
    lang=en-US,
    xmp=true}
  ```

- Input metadata:
  ```yaml
  ---
  pdfstandard: ua-1
  lang: en-US
  ---
  ```
  Output LaTeX should include (before `\documentclass`):
  ```tex
  \DocumentMetadata{
    pdfstandard={ua-1},
    tagging=on,
    lang=en-US,
    xmp=true}
  ```

The emitted `\DocumentMetadata` must always appear early enough to satisfy LaTeX’s requirement that it precede `\documentclass`, and it must integrate cleanly with the existing LaTeX writer behavior (e.g., it should not break the usual package option passing and language handling).