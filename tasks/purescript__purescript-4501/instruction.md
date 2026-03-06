The compiler fails to fully infer types when a value with a visible type application (VTA) is used directly as a field value in a record literal, leaving an unexpected polymorphic type (`forall`) that later blocks downstream typeclass resolution.

Reproduction:

```purescript
module Example where

import Prelude

import Data.Reflectable (class Reflectable, reflectType)
import Type.Proxy (Proxy(..))

reflect :: forall @t v. Reflectable t v => v
reflect = reflectType (Proxy @t)

use :: String
use = show { asdf: reflect @"asdf" }
```

Expected behavior: this program should compile, and `use` should be a `String` representing the record with the reflected value (e.g. it should behave as if the record field has the inferred monomorphic type needed for `show`).

Actual behavior: compilation fails because the type of `reflect @"asdf"` inside the record is not fully inferred; the compiler leaves it as a `forall`-quantified value. This prevents other constraints needed by `show` from being solved (and in general breaks typeclasses which depend on fully-known row/field types, such as operations involving `RowToList` or `Nub`).

A key symptom is that the issue disappears if the expression is turned into a function application by adding an otherwise-useless argument:

```purescript
reflect :: forall @t v. Reflectable t v => Unit -> v
reflect _ = reflectType (Proxy @t)

use :: String
use = show { asdf: reflect @"asdf" unit }
```

Implement whatever changes are necessary in the type inference / elaboration pipeline so that using VTA at a polymorphic value in a record field triggers the same kind of instantiation/inference as it does in other expression positions, and does not leave an unexpected `forall` at the record field value. After the fix, the original reproduction should compile without requiring the extra dummy argument.