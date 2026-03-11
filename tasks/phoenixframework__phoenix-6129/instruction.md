In a newly generated Phoenix project, the default setup uses Tailwind to build the main stylesheet and esbuild to bundle JavaScript. However, when a developer adds a JavaScript dependency that imports CSS (for example, adding an `import "some-lib/dist/styles.css"` in `assets/js/app.js`), esbuild will also emit a CSS bundle named `app.css`. This conflicts with the default Tailwind output file (also `app.css`).

The result is confusing and unstable: whichever watcher/build runs last overwrites the final `app.css`, causing either (a) missing Tailwind styles (if esbuild’s CSS wins) or (b) missing dependency styles (if Tailwind’s CSS wins). Both workflows appear “broken” because the output CSS is nondeterministic during development.

Update the generated project defaults so that this conflict cannot happen out of the box. The generated Tailwind stylesheet should no longer use the name `app.css`; instead, the default Tailwind output should be renamed to `main.css`, and the rest of the generated project must consistently reference that new name.

After the change, a freshly generated project should:

- Serve the stylesheet under the new name (`main.css`) in the default layout so the browser loads it.
- Configure Tailwind’s build/watch commands to output `main.css` (not `app.css`).
- Keep esbuild’s JavaScript entrypoint and output behavior as-is, so that if esbuild emits `app.css` due to CSS imports in JS, it will no longer overwrite Tailwind’s stylesheet.

Generating a new project with default options (and generating a new umbrella project with default options) should produce scaffolding that is internally consistent: all config and templates should refer to `main.css` wherever the default CSS asset is referenced, and there should be no remaining default references to `app.css` for the Tailwind-generated stylesheet.