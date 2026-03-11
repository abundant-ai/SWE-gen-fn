Boolean HTML attributes that are configured to be ignored on client-side patches are still being set by server-driven updates.

When a client marks an element to ignore specific attributes (via the LiveView JS API), subsequent patches from the server should not modify those attributes. This works for normal attributes, but it fails for boolean attributes when the server patch includes the attribute (e.g., the server renders `hidden`), because the patch logic ends up applying it anyway. This is particularly visible when the attribute was removed on the client and then later gets re-applied by a patch.

Reproduction pattern:

1) Render an element with a boolean attribute controlled by the server, such as:

```html
<div id="abc" hidden>...</div>
```

2) On the client, configure LiveView to ignore that attribute for the element and then remove it locally:

```js
let el = document.getElementById("abc")
liveSocket.js().ignoreAttributes(el, ["hidden"]) // or wildcard that covers it
el.removeAttribute("hidden")
```

3) Trigger a server update that re-renders the element with `hidden` present in the HTML/patch.

Expected behavior:
The attribute listed in `ignoreAttributes` must remain untouched during patching. In the example above, `hidden` should stay removed (the element should remain visible), even if the server patch includes `hidden`.

Actual behavior:
The patch applies the boolean attribute from the server anyway, causing `hidden` (and similar boolean attributes) to be set back onto the element despite being ignored.

Fix required:
Ensure the client-side patching/diff application respects ignored attributes for boolean attributes the same way it does for normal attributes. If an attribute name is ignored (including via wildcard rules), patch application must not add, remove, or toggle that attribute, even when the server-side HTML includes it.