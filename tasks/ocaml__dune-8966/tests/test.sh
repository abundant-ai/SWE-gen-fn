#!/bin/bash

cd /app/src

# Set up opam environment for running tests
export OPAM_SWITCH_PREFIX=/root/.opam/4.14.1
export PATH="/root/.opam/4.14.1/bin:${PATH}"

# Rebuild dune if source files were modified (by Oracle agent)
# This ensures we test the current code state
echo "Rebuilding dune to reflect any code changes..."
opam exec -- ocaml boot/bootstrap.ml > /dev/null 2>&1
opam exec -- ./_boot/dune.exe build dune.install --release --profile dune-bootstrap > /dev/null 2>&1

# Use the locally built dune binary for testing
export PATH="/app/src/_build/install/default/bin:${PATH}"

# Create a test directory for our scenario
TEST_DIR=/tmp/coq-test
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# Create a wrapper around coqc that can fail on --config
mkdir -p bin
cat > bin/coqc <<'EOF'
#!/bin/bash
if [ "$1" = "--config" ] && [ -n "$FAIL_CONFIG" ]; then
  echo "coqc --config has failed for some reason" >&2
  exit 1
elif [ "$1" = "--print-version" ] && [ -n "$FAIL_VERSION" ]; then
  echo "coqc --print-version has failed for some reason" >&2
  exit 1
fi
# Forward to real coqc
exec /root/.opam/4.14.1/bin/coqc "$@"
EOF
chmod +x bin/coqc

# Put our wrapper first in PATH
export PATH="$TEST_DIR/bin:$PATH"

# Create a simple Coq project
cat > dune-project <<'EOF'
(lang dune 3.11)
(using coq 0.8)
EOF

cat > dune <<'EOF'
(coq.theory
 (flags -noinit)
 (name foo))

(rule
 (deps
  (env_var FAIL_CONFIG))
 (action
  (write-file a.v "")))
EOF

# The key test: with FAIL_CONFIG=1, the HEAD code should emit a warning and succeed,
# but the BASE code should fail with an error
FAIL_CONFIG=1 dune build 2>&1 > /tmp/test_output.txt
test_status=$?

# Check the output and exit code
# BASE (buggy): exits non-zero with "Error: Error while running"
# HEAD (fixed): exits zero with "Warning: Skipping installed theories"

if [ $test_status -eq 0 ]; then
  # Build succeeded - this is the expected behavior for HEAD (fixed) code
  echo 1 > /logs/verifier/reward.txt
else
  # Build failed - this is the expected behavior for BASE (buggy) code
  echo 0 > /logs/verifier/reward.txt
fi

exit "$test_status"
