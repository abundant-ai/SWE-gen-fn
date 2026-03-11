The OCaml standard library List module is missing an indexed variant of filter_map. Users often need to combine the index-aware mapping of List.mapi with the option-filtering behavior of List.filter_map, but there is currently no List.filter_mapi.

Implement a new function List.filter_mapi with the following behavior:

- Signature: List.filter_mapi : (int -> 'a -> 'b option) -> 'a list -> 'b list
- It traverses the input list left-to-right, calling the provided function with the element index (starting at 0) and the element.
- If the function returns Some y, y is included in the output list; if it returns None, the element is skipped.
- The relative order of kept elements must match the input order.
- Indices must correspond to positions in the original input list (i.e., increment for every input element, not just kept ones).

Example behaviors that must hold:

- List.filter_mapi (fun i x -> if (i + x) mod 2 = 0 then Some (string_of_int (i + x)) else None) [0;1;2;3;4;5;6;7;8;9]
  should return ["0"; "2"; "4"; "6"; "8"; "10"; "12"; "14"; "16"; "18"].

- For a function that keeps only even values regardless of index:
  List.filter_mapi (fun _ x -> if x mod 2 = 0 then Some (string_of_int x) else None) [0;1;2;3;4;5;6;7;8;9]
  should return ["0"; "2"; "4"; "6"; "8"].

The new function must be exposed as part of the public List API so that code can compile when calling List.filter_mapi, and it must behave consistently with existing List.filter_map and List.mapi conventions.