#!/bin/bash

set -euo pipefail
cd /app/src

# Apply fix.patch, ignoring the submodule reference change
patch -p1 --reject-file=- < /solution/fix.patch || true

# Update the sci submodule to the fixed commit
cd sci && git checkout 4b2510ee2973ced351cb02f22531a71f2a6ef864 && cd ..
