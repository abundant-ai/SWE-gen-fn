#!/bin/bash

set -euo pipefail
cd /app/src

# Apply fix.patch (will fail on submodule, which is expected)
patch -p1 < /solution/fix.patch || true

# Manually update submodule to fixed version (patch can't handle submodule changes)
cd babashka.nrepl && git checkout d48f09c7da0db8cec4631bc968bb703c3ad74e61 && cd ..
