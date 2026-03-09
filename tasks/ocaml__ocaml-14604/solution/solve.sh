#!/bin/bash

set -euo pipefail
cd /app/src

# Apply the fix patch
patch -p1 < /solution/fix.patch

# Rebuild the compiler after applying the fix (OCaml is a compiled language)
make -j$(nproc)
