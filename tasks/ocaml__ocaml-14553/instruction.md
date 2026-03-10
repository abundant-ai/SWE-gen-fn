The OCaml standard library’s Array module is missing two common combinators that exist for lists: functions to fold over two arrays in lockstep. This inconsistency makes it harder to write uniform code across List and Array, and users currently have to reimplement this behavior manually.

Implement two new functions in the Array module:

- Array.fold_left2 : ('acc -> 'a -> 'b -> 'acc) -> 'acc -> 'a array -> 'b array -> 'acc
- Array.fold_right2 : ('a -> 'b -> 'acc -> 'acc) -> 'a array -> 'b array -> 'acc -> 'acc

Behavior requirements:

1) These functions must traverse the two input arrays in parallel and apply the combining function to corresponding elements.

- Array.fold_left2 f init a b should compute, for arrays of length n, the value:
  f (... (f (f init a.(0) b.(0)) a.(1) b.(1)) ...) a.(n-1) b.(n-1)

- Array.fold_right2 f a b init should compute, for arrays of length n, the value:
  f a.(0) b.(0) (f a.(1) b.(1) (... (f a.(n-1) b.(n-1) init) ...))
  (i.e., iterate from the last index down to 0).

2) If the two arrays do not have the same length, both functions must raise Invalid_argument (with the same message style used by existing Array “*2” functions, e.g. map2/iter2), rather than silently truncating or producing an out-of-bounds exception.

3) For empty arrays, the result must be the initial accumulator without calling the combining function.

4) These functions must be exposed as part of the public Array API (so that code can compile using Array.fold_left2 and Array.fold_right2), and they should behave consistently with the corresponding List.fold_left2 and List.fold_right2 in terms of argument order and error behavior.

Example expectations:

- Array.fold_left2 (fun acc x y -> acc + (x * y)) 0 [|1;2;3|] [|4;5;6|] = 32
- Array.fold_right2 (fun x y acc -> (x - y) :: acc) [|1;2|] [|3;4|] [] = [1-3; 2-4]

- Array.fold_left2 f init [|1|] [| |] must raise Invalid_argument due to length mismatch.