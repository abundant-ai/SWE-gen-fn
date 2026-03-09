The Appendable_list data structure needs to be re-implemented/refactored without changing its observable behavior. After the refactor, several core operations must still preserve ordering and emptiness semantics exactly as before.

The following functions and operators must behave correctly:

- Appendable_list.empty must represent an empty sequence.
- Appendable_list.singleton x must produce a list containing exactly x.
- Appendable_list.cons x xs must prepend x to xs, preserving order when converted to a normal list.
- The append operator (@) must concatenate two appendable lists so that converting the result to a normal list yields elements from the left operand followed by elements from the right operand, with correct associativity behavior in nested appends.
- Appendable_list.concat must concatenate a list of appendable lists in order, including handling many small singletons.
- Appendable_list.to_list must return the elements in the correct order for all of the above constructions.
- Appendable_list.of_list must produce an empty appendable list when given an empty list.
- Appendable_list.is_empty must correctly identify emptiness, including for values produced by:
  - concat []
  - concat [empty]
  - concat [empty; empty]
  - of_list []

Currently, after the re-implementation, at least one of these invariants can be violated (most importantly, emptiness detection and/or preservation of element order through combinations of cons, append (@), and concat). Fix the implementation so that all of the above operations are consistent: converting to a list always yields the expected sequence of elements, and is_empty returns true exactly for logically empty appendable lists (even when constructed indirectly via concat/of_list), and false for non-empty ones.