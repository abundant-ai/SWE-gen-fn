Reason/Refmt currently does not reliably support Unicode letters in identifiers (as introduced minimally in OCaml 5.3). Code containing identifiers such as `Été`, `là`, `ça`, `straße`, `øre`, `Æsop`, `Œuvre`, etc. should parse and format correctly, but today such inputs can fail to parse, be rejected as invalid identifiers, or be reformatted incorrectly.

Update the identifier handling so that Unicode letters are accepted in:

- Variant constructors and type constructors (e.g. `type saison = Hiver | Été | Printemps | Automne;` and `let x = Été;`).
- Value identifiers (e.g. `let été = "summer"; let là = (ça) => ça;`).
- Identifiers used in pattern matching and expressions (e.g. `fun | Élégant => 4;` and `assert(f(Élégant) == 4);`).
- Extension/sugar forms that embed identifiers in their payload and qualified names, including constructs like `%âcre.name`, `%Âcre.sub`, and `let%À.ça x = ();`.
- Quoted-string delimiters and extension payload delimiters that use Unicode letters (e.g. `{où|x|où}` and `{%Là |x|}`), while still rejecting invalid delimiters.

Normalization behavior is important: identifiers that are canonically equivalent under Unicode normalization (for example, NFC vs NFD spellings of the same apparent name like `Élégant` written as a single composed character vs `E` + combining accent) must be treated as the same identifier for name-resolution purposes. If both forms are defined in the same scope, the compiler/parser pipeline should raise a duplicate-definition error (the user-visible error should be of the form “Multiple definition …” for the second definition).

At the same time, formatting must be stable and not corrupt Unicode identifiers. Running the formatter on code using Unicode identifiers should produce valid output that:

- Preserves the intended identifier spelling (no loss or mangling of Unicode letters).
- Prints/pretty-prints the same identifiers consistently.
- Is idempotent: formatting the formatted output again yields identical output.

Concrete scenarios that must work end-to-end (parse + pretty-print/format + reparse) include:

```reason
type saison = Hiver | Été | Printemps | Automne;
let x = Été;

let là = (ça) => ça;

type t = Æsop | Âcre | Ça | Élégant | Öst | Œuvre;

let été = "summer";
let ça = "that";
let straße = "street";
let øre = "ear";

let f = fun
  | Æsop => 1
  | Âcre => 2
  | Ça => 3
  | Élégant => 4
  | Öst => 5
  | Œuvre => 6;

let x = {où|x|où};
let ko = {%Là |x|};
let x = {%âcre.name été|x|été};
let x = {%Âcre.sub été|x|été};
let%À.ça x = ();
```

And this must be rejected as a duplicate definition due to Unicode normalization equivalence:

```reason
module Élégant = {};
module Elegant = {}; /* same apparent name via a different Unicode normalization form */
```

Ensure the lexer/parser recognize the appropriate Unicode letter ranges for identifier characters (in line with OCaml 5.3’s “minimal support”), and ensure the pretty-printer/refmt output remains correct and idempotent for these constructs.