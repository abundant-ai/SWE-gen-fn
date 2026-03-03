#!/bin/bash

cd /app/src

# Check if the fix has been applied (DL3005.hs shouldn't exist after fix)
if [ ! -f "src/Hadolint/Rule/DL3005.hs" ]; then
  echo "Fix has been applied (DL3005.hs removed), need to rebuild"
  # Clean and rebuild after fix is applied
  cabal clean
  cabal build exe:hadolint -j$(nproc) 2>&1 | tail -50
  if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo "Build failed after fix"
    echo 0 > /logs/verifier/reward.txt
    exit 1
  fi
else
  echo "BASE state (DL3005.hs exists), using existing build"
fi

# Create a test Dockerfile that uses apt-get dist-upgrade (triggers DL3005 in buggy state)
cat > /tmp/test-dockerfile << 'EOF'
FROM ubuntu:20.04
RUN apt-get update && apt-get dist-upgrade -y
EOF

# Find the hadolint binary
HADOLINT_BIN=$(find dist-newstyle -name hadolint -type f -executable | head -1)

if [ -z "$HADOLINT_BIN" ]; then
  echo "ERROR: hadolint binary not found"
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi

# Run hadolint on the test Dockerfile
$HADOLINT_BIN /tmp/test-dockerfile > /tmp/hadolint-output.txt 2>&1 || true

cat /tmp/hadolint-output.txt

# Check if DL3005 is in the output
if grep -q "DL3005" /tmp/hadolint-output.txt; then
  # DL3005 is reported - this is the BASE/buggy state
  echo "DL3005 found in output (buggy state - rule still exists)"
  echo 0 > /logs/verifier/reward.txt
  exit 1
else
  # DL3005 is not reported - this is the HEAD/fixed state
  echo "DL3005 not found in output (fixed state - rule removed)"
  echo 1 > /logs/verifier/reward.txt
  exit 0
fi
