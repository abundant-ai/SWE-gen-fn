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

# Manual test: replicate the cram test scenario from eager-package-lookup.t
# The test checks that when a package fails to resolve, it shouldn't prevent rules from loading
cd /tmp
mkdir -p test_scenario
cd test_scenario

# Set up the test project structure (from eager-package-lookup.t)
cat >dune-project <<'EOF'
(lang dune 3.11)
(using dune_site 0.1)
(package (name a))
EOF

cat >dune <<'EOF'
(install
 (section (site (foobarpkg baz)))
 (files foo))
(rule (with-stdout-to foo (echo bar)))
EOF

# The actual test: try building foo even though foobarpkg doesn't exist
# In the buggy state, this should fail because dune eagerly evaluates the package
# In the fixed state, this should succeed - the rule can still be built despite the invalid package reference
test_output=$(dune build foo 2>&1)
test_status=$?

# The test PASSES (reward=1) if the build SUCCEEDS (exit code 0)
# The test FAILS (reward=0) if the build FAILS (exit code non-zero)
if [ $test_status -eq 0 ]; then
  # Build succeeded - test passed
  echo 1 > /logs/verifier/reward.txt
  exit 0
else
  # Build failed - test failed
  echo "$test_output"
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi
