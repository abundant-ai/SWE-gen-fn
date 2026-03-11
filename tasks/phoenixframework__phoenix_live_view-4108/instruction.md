TypeScript users can’t reliably type Phoenix LiveView hooks with custom state and/or a specific element type while still being able to pass those hooks into LiveSocket via the `hooks` option.

When a user defines a typed hook like `const CounterHook: Hook<CounterState> = { ... }` (where `CounterState` includes required properties), assigning it into a `HooksOptions` object should typecheck, e.g.:

```ts
import type { Hook, HooksOptions } from "phoenix_live_view/view_hook";

interface LinksInTab {
  tabName: string;
  links: string[];
}

const LinksInTabHook: Hook<LinksInTab> = {
  tabName: "",
  links: [],
  mounted() {
    this.tabName = this.el.dataset.tab || "default";
  },
};

const hooks: HooksOptions = {
  LinksInTab: LinksInTabHook,
};
```

Currently, this kind of assignment can fail under stricter TypeScript settings because `HooksOptions` is too narrowly typed (it doesn’t accept hooks with arbitrary generic parameters), and/or because the `Hook<TState, TEl>` generic is not treated as covariant in `TState`. The result is that `Hook<SpecificState>` is not assignable where a more general hook type is expected, especially when `SpecificState` has required properties.

Update the public TypeScript types so that:

1) `HooksOptions` can accept hooks defined as `Hook<CustomState, CustomElement>` for any custom state and element types, without requiring users to erase types with casts.

2) `Hook<SpecificState>` is assignable to a broader `Hook<object>` (and similarly broader state types), so that typed hooks compose correctly. This should work even when `SpecificState` contains required properties.

3) Hooks that specify a particular element type (e.g. `Hook<CanvasState, HTMLCanvasElement>`) should expose `this.el` as that element type inside hook callbacks like `mounted()`, so code like `this.el.getContext("2d")` typechecks.

4) A plain `Hook` (without explicit generics) should still allow adding custom methods/properties on the hook object and using them via `this` in lifecycle callbacks (for example, defining a `page()` method and setting `this.pending` inside `mounted()` should typecheck).

After the change, TypeScript strict typechecking should succeed for these scenarios without users needing unsafe casts, and LiveSocket initialization via `{ hooks: HooksOptions }` should accept the typed hooks.