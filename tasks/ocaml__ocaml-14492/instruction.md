`Obj.dup` and `Obj.with_tag` mis-handle closures, particularly for closures represented as “infix” blocks. This shows up when duplicating or retagging values obtained via `Obj.repr`.

Currently, duplicating closures can crash, produce an invalid value, or otherwise behave inconsistently. In addition, `Obj.with_tag` does not correctly account for closure tags vs infix tags, which can allow invalid tag changes or produce incorrect results.

The runtime helper responsible for retagging blocks (exposed through `Obj.with_tag`) must correctly handle closures and infix-tagged blocks:

- Duplicating a normal closure must succeed: `ignore (Obj.dup (Obj.repr f))` should not raise or crash.
- Duplicating an infix closure must also succeed: `ignore (Obj.dup (Obj.repr g))` should not raise or crash.
- Retagging between incompatible closure/infix forms must be rejected. In particular, attempting to apply an infix tag to a non-infix block, or a non-infix tag to an infix block, must raise `Failure _` (not silently succeed):

```ocaml
let non_infix_to_infix () =
  ignore (Obj.with_tag (Obj.tag (Obj.repr f)) (Obj.repr g))

let infix_to_non_infix () =
  ignore (Obj.with_tag (Obj.tag (Obj.repr g)) (Obj.repr f))
```

Both calls above must fail by raising `Failure _`.

Existing correct behaviors must remain correct:

- `Obj.dup` must preserve structural equality of duplicated blocks for regular values, e.g. a duplicated variant value compares equal at the representation level.
- `Obj.with_tag` must correctly retag ordinary blocks (e.g. a value of one constructor retagged to another when layouts match).
- `Obj.with_tag` must set the tag of an existing block (e.g. an array block) so that `Obj.tag (Obj.with_tag new_tag v) = new_tag`.
- `Obj.with_tag` should preserve existing optimization behavior: for some immediate/flat cases it should allocate 0 words, while for others (like retagging a ref cell) it allocates as expected.

Implement the missing closure/infix handling so these closure duplication and forbidden retagging cases behave as specified, without regressing the other `Obj.with_tag` and allocation behaviors.