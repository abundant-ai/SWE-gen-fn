Calling instance methods via Java interop on certain Jsoup elements fails in babashka, specifically for HTML <form> elements returned by Jsoup selectors. For example, evaluating the following should return the tag name "form" without error:

```clojure
(.tagName (first (.getElementsByTag (org.jsoup.Jsoup/parseBodyFragment "<form></form>") "form")))
```

Currently, this interop call does not work for the form element instance returned by `(.getElementsByTag ... "form")` (even though similar interop works for other Jsoup element types). This indicates babashka’s Java interop method resolution/dispatch is not correctly handling this particular runtime type (likely a Jsoup `FormElement` subtype) when invoking `tagName()`.

Fix babashka so that invoking `(.tagName some-jsoup-form-element)` works the same way as for other Jsoup `Element` instances: it should successfully call the underlying Java method and return the correct string (e.g., "form") rather than throwing or failing method resolution. Ensure the behavior works on the result of `org.jsoup.Jsoup/parseBodyFragment` combined with `getElementsByTag` and `first`, as shown above.