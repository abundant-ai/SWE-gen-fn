#!/bin/bash

set -euo pipefail
cd /app/src

patch -p1 --no-backup-if-mismatch < /solution/fix.patch || true
cd babashka.nrepl && git checkout 436c8824f52bf0b67751fa4c3245bf1c068fbc8a && cd ..
