#!/bin/bash

set -euo pipefail
cd /app/src

# Set opam environment
export OPAM_SWITCH_PREFIX=/root/.opam/5.2.0
export PATH="/root/.opam/5.2.0/bin:${PATH}"

patch -p1 < /solution/fix.patch

# Remove the simplified reason_toploop.ml from BASE state (if it still exists after patching)
rm -f rtop/reason_toploop.ml

# Install cppo which was added back as a dependency
opam install cppo -y

# Rebuild rtop with the fixed code
opam exec -- dune clean
opam exec -- dune build @install
