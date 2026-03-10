The Reason formatter (`refmt`) mishandles non-empty doc comments (`/** ... */`) that appear immediately before an expression/statement inside a block.

Reproduction:

```reason
let main = () => {
  /**
   *
   */
  Printexc.record_backtrace(true);
  Printexc.record_backtrace(true);
};
```

Expected formatting preserves the doc comment as its own standalone item, with the following statement starting on the next line (i.e., a line break must occur right after the closing `*/`):

```reason
let main = () => {
  /**
   *
   */
  Printexc.record_backtrace(true);
  Printexc.record_backtrace(true);
};
```

Actual behavior today is that the formatter sometimes prints the first statement on the same line as the doc comment terminator, effectively attaching the expression to the `*/`:

```reason
let main = () => {
  /**
   *
   */ Printexc.record_backtrace(true);
  Printexc.record_backtrace(true);
};
```

This should be fixed so that whenever a doc comment is non-empty and is placed before a following item in a block, the formatter always inserts a hard line break after the doc comment closing `*/`, preventing any following code from being printed on the same line. The change must be idempotent (running `refmt` repeatedly should not change output further) and should not regress formatting of regular block comments (`/* ... */`) or other constructs such as infix expressions and attributes surrounding doc comments.