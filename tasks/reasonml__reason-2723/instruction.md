There is a formatting/parsing bug affecting Reason syntax extensions when they appear inside a module body. Running the formatter on code that contains a module definition with extension nodes inside it can either mis-format the output or fail to preserve the extension payload correctly.

Reproduction:

```reason
[%%toplevelExtension "payload"];
module X = {
  /* No payload */
  [%%someExtension];
  [%%someExtension "payload"];
};
```

Expected behavior: formatting should succeed and preserve all extension nodes and their payloads exactly, producing output equivalent to:

```reason
[%%toplevelExtension "payload"];
module X = {
  /* No payload */
  [%%someExtension];
  [%%someExtension "payload"];
};
```

Actual behavior: when an extension appears nested inside a module, the formatter mishandles it (for example, dropping the payload, attaching it incorrectly, or producing invalid formatting).

Fix the formatter/parser pipeline so that extension nodes inside module structures are handled the same way as at the toplevel, including both no-payload extensions (`[%%someExtension]`) and payload-carrying extensions (`[%%someExtension "payload"]`). The behavior should be consistent for nested extensions and should not depend on whether an extension appears at the toplevel or within a module body.