When generating income statement reports with CSV output, using the --summary-only option incorrectly includes period/date columns in the CSV header even though the report has been reduced to a single summary column.

Reproduction example:

1) Create a journal with multiple months of expenses, then run:

hledger -f f.journal is --monthly --average --summary-only -O csv

Current behavior: the CSV header includes monthly columns (eg "Jan","Feb","Mar") along with the summary column:

"Account","Jan","Feb","Mar","Average"

but the body of the report only contains a single numeric column per row (the summary/average), causing a mismatch between header and data and producing misleading exports.

Expected behavior: when --summary-only is used, CSV output should not include date/period columns at all. The header should reflect only the account column and the single summary column being reported, eg:

"Account","Average"

The same should hold for similar combinations where a multi-period report is reduced by --summary-only: CSV/TSV output must omit the per-period headers and emit only the columns that are actually present in each row.

After the fix, running the command above should produce a CSV with a title row (if titles are normally included for this report format) followed by a header consistent with the summary-only layout, and all subsequent rows should have the same number of columns as the header.