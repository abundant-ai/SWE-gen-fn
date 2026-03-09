#!/bin/bash

set -euo pipefail
cd /app/src

# Apply the fix patch
patch -p1 < /solution/fix.patch

# Remove the files from dune_rules to avoid dependency cycle
# (fix.patch creates files in dune_lang, but bug.patch moved them to dune_rules)
rm -f src/dune_rules/lib_dep.ml src/dune_rules/lib_dep.mli
