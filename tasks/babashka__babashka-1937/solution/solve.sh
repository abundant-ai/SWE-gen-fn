#!/bin/bash

set -euo pipefail
cd /app/src

# Apply fix.patch, ignoring the submodule reference change
patch -p1 --reject-file=- < /solution/fix.patch || true

# Update the sci submodule to the fixed commit
cd sci && git checkout 9a6a082b && cd ..
