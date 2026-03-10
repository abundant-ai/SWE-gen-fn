#!/bin/bash

set -euo pipefail
cd /app/src

patch -p1 < /solution/fix.patch

# Rebuild hledger after applying the fix (Haskell is compiled)
cabal install --jobs=$(nproc) --installdir=/root/.local/bin --install-method=copy --overwrite-policy=always \
    --ghc-options="-j$(nproc)" \
    hledger
