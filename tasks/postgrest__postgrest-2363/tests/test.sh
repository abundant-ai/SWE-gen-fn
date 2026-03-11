#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io/configs/expected"
cp "/tests/io/configs/expected/aliases.config" "test/io/configs/expected/aliases.config"
mkdir -p "test/io/configs/expected"
cp "/tests/io/configs/expected/boolean-numeric.config" "test/io/configs/expected/boolean-numeric.config"
mkdir -p "test/io/configs/expected"
cp "/tests/io/configs/expected/boolean-string.config" "test/io/configs/expected/boolean-string.config"
mkdir -p "test/io/configs/expected"
cp "/tests/io/configs/expected/defaults.config" "test/io/configs/expected/defaults.config"
mkdir -p "test/io/configs/expected"
cp "/tests/io/configs/expected/no-defaults-with-db-other-authenticator.config" "test/io/configs/expected/no-defaults-with-db-other-authenticator.config"
mkdir -p "test/io/configs/expected"
cp "/tests/io/configs/expected/no-defaults-with-db.config" "test/io/configs/expected/no-defaults-with-db.config"
mkdir -p "test/io/configs/expected"
cp "/tests/io/configs/expected/no-defaults.config" "test/io/configs/expected/no-defaults.config"
mkdir -p "test/io/configs/expected"
cp "/tests/io/configs/expected/types.config" "test/io/configs/expected/types.config"
mkdir -p "test/io/configs"
cp "/tests/io/configs/no-defaults-env.yaml" "test/io/configs/no-defaults-env.yaml"
mkdir -p "test/io/configs"
cp "/tests/io/configs/no-defaults.config" "test/io/configs/no-defaults.config"
mkdir -p "test/io"
cp "/tests/io/db_config.sql" "test/io/db_config.sql"
mkdir -p "test/spec/Feature/OpenApi"
cp "/tests/spec/Feature/OpenApi/OpenApiSpec.hs" "test/spec/Feature/OpenApi/OpenApiSpec.hs"
mkdir -p "test/spec/Feature/OpenApi"
cp "/tests/spec/Feature/OpenApi/SecurityOpenApiSpec.hs" "test/spec/Feature/OpenApi/SecurityOpenApiSpec.hs"
mkdir -p "test/spec"
cp "/tests/spec/Main.hs" "test/spec/Main.hs"
mkdir -p "test/spec"
cp "/tests/spec/SpecHelper.hs" "test/spec/SpecHelper.hs"

test_status=0

echo "Verifying fix for OpenAPI security definitions (PR #2363)..."
echo ""
echo "NOTE: This PR adds openapi-security-active configuration parameter."
echo "We verify that the source code has the feature and test files are updated."
echo ""

echo "Checking source code has configOpenApiSecurityActive..."
if [ -f "src/PostgREST/Config.hs" ] && grep -q "configOpenApiSecurityActive" "src/PostgREST/Config.hs"; then
    echo "✓ Config.hs has configOpenApiSecurityActive"
else
    echo "✗ Config.hs missing configOpenApiSecurityActive - fix not applied!"
    test_status=1
fi

echo "Checking OpenAPI.hs has security definitions..."
if [ -f "src/PostgREST/OpenAPI.hs" ] && grep -q "makeSecurityDefinitions" "src/PostgREST/OpenAPI.hs"; then
    echo "✓ OpenAPI.hs has makeSecurityDefinitions function"
else
    echo "✗ OpenAPI.hs missing makeSecurityDefinitions - fix not applied!"
    test_status=1
fi

echo "Checking CHANGELOG mentions the feature..."
if [ -f "CHANGELOG.md" ] && grep -q "#1082" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions #1082"
else
    echo "✗ CHANGELOG.md missing #1082 entry"
    test_status=1
fi

echo ""
echo "Now checking that HEAD test files were copied correctly..."
echo ""

echo "Checking test/io/configs/expected/aliases.config was updated..."
if [ -f "test/io/configs/expected/aliases.config" ] && [ -s "test/io/configs/expected/aliases.config" ]; then
    if grep -q "openapi-security-active" "test/io/configs/expected/aliases.config"; then
        echo "✓ aliases.config has openapi-security-active parameter"
    else
        echo "✗ aliases.config missing openapi-security-active parameter"
        test_status=1
    fi
else
    echo "✗ aliases.config missing or empty"
    test_status=1
fi

echo "Checking test/io/configs/expected/boolean-numeric.config was updated..."
if [ -f "test/io/configs/expected/boolean-numeric.config" ] && [ -s "test/io/configs/expected/boolean-numeric.config" ]; then
    if grep -q "openapi-security-active" "test/io/configs/expected/boolean-numeric.config"; then
        echo "✓ boolean-numeric.config has openapi-security-active parameter"
    else
        echo "✗ boolean-numeric.config missing openapi-security-active parameter"
        test_status=1
    fi
else
    echo "✗ boolean-numeric.config missing or empty"
    test_status=1
fi

echo "Checking test/io/configs/expected/boolean-string.config was updated..."
if [ -f "test/io/configs/expected/boolean-string.config" ] && [ -s "test/io/configs/expected/boolean-string.config" ]; then
    if grep -q "openapi-security-active" "test/io/configs/expected/boolean-string.config"; then
        echo "✓ boolean-string.config has openapi-security-active parameter"
    else
        echo "✗ boolean-string.config missing openapi-security-active parameter"
        test_status=1
    fi
else
    echo "✗ boolean-string.config missing or empty"
    test_status=1
fi

echo "Checking test/io/configs/expected/defaults.config was updated..."
if [ -f "test/io/configs/expected/defaults.config" ] && [ -s "test/io/configs/expected/defaults.config" ]; then
    if grep -q "openapi-security-active" "test/io/configs/expected/defaults.config"; then
        echo "✓ defaults.config has openapi-security-active parameter"
    else
        echo "✗ defaults.config missing openapi-security-active parameter"
        test_status=1
    fi
else
    echo "✗ defaults.config missing or empty"
    test_status=1
fi

echo "Checking test/io/configs/expected/no-defaults-with-db-other-authenticator.config was updated..."
if [ -f "test/io/configs/expected/no-defaults-with-db-other-authenticator.config" ] && [ -s "test/io/configs/expected/no-defaults-with-db-other-authenticator.config" ]; then
    if grep -q "openapi-security-active" "test/io/configs/expected/no-defaults-with-db-other-authenticator.config"; then
        echo "✓ no-defaults-with-db-other-authenticator.config has openapi-security-active parameter"
    else
        echo "✗ no-defaults-with-db-other-authenticator.config missing openapi-security-active parameter"
        test_status=1
    fi
else
    echo "✗ no-defaults-with-db-other-authenticator.config missing or empty"
    test_status=1
fi

echo "Checking test/io/configs/expected/no-defaults-with-db.config was updated..."
if [ -f "test/io/configs/expected/no-defaults-with-db.config" ] && [ -s "test/io/configs/expected/no-defaults-with-db.config" ]; then
    if grep -q "openapi-security-active" "test/io/configs/expected/no-defaults-with-db.config"; then
        echo "✓ no-defaults-with-db.config has openapi-security-active parameter"
    else
        echo "✗ no-defaults-with-db.config missing openapi-security-active parameter"
        test_status=1
    fi
else
    echo "✗ no-defaults-with-db.config missing or empty"
    test_status=1
fi

echo "Checking test/io/configs/expected/no-defaults.config was updated..."
if [ -f "test/io/configs/expected/no-defaults.config" ] && [ -s "test/io/configs/expected/no-defaults.config" ]; then
    if grep -q "openapi-security-active" "test/io/configs/expected/no-defaults.config"; then
        echo "✓ no-defaults.config has openapi-security-active parameter"
    else
        echo "✗ no-defaults.config missing openapi-security-active parameter"
        test_status=1
    fi
else
    echo "✗ no-defaults.config missing or empty"
    test_status=1
fi

echo "Checking test/io/configs/expected/types.config was updated..."
if [ -f "test/io/configs/expected/types.config" ] && [ -s "test/io/configs/expected/types.config" ]; then
    if grep -q "openapi-security-active" "test/io/configs/expected/types.config"; then
        echo "✓ types.config has openapi-security-active parameter"
    else
        echo "✗ types.config missing openapi-security-active parameter"
        test_status=1
    fi
else
    echo "✗ types.config missing or empty"
    test_status=1
fi

echo "Checking test/io/configs/no-defaults-env.yaml was updated..."
if [ -f "test/io/configs/no-defaults-env.yaml" ] && [ -s "test/io/configs/no-defaults-env.yaml" ]; then
    if grep -q "OPENAPI_SECURITY_ACTIVE" "test/io/configs/no-defaults-env.yaml"; then
        echo "✓ no-defaults-env.yaml has PGRST_OPENAPI_SECURITY_ACTIVE parameter"
    else
        echo "✗ no-defaults-env.yaml missing PGRST_OPENAPI_SECURITY_ACTIVE parameter"
        test_status=1
    fi
else
    echo "✗ no-defaults-env.yaml missing or empty"
    test_status=1
fi

echo "Checking test/io/configs/no-defaults.config was updated..."
if [ -f "test/io/configs/no-defaults.config" ] && [ -s "test/io/configs/no-defaults.config" ]; then
    if grep -q "openapi-security-active" "test/io/configs/no-defaults.config"; then
        echo "✓ no-defaults.config has openapi-security-active parameter"
    else
        echo "✗ no-defaults.config missing openapi-security-active parameter"
        test_status=1
    fi
else
    echo "✗ no-defaults.config missing or empty"
    test_status=1
fi

echo "Checking test/io/db_config.sql was updated..."
if [ -f "test/io/db_config.sql" ] && [ -s "test/io/db_config.sql" ]; then
    if grep -q "openapi_security_active" "test/io/db_config.sql"; then
        echo "✓ db_config.sql has openapi_security_active setting"
    else
        echo "✗ db_config.sql missing openapi_security_active setting"
        test_status=1
    fi
else
    echo "✗ db_config.sql missing or empty"
    test_status=1
fi

echo "Checking test/spec/Feature/OpenApi/OpenApiSpec.hs was updated..."
if [ -f "test/spec/Feature/OpenApi/OpenApiSpec.hs" ] && [ -s "test/spec/Feature/OpenApi/OpenApiSpec.hs" ]; then
    if grep -q "Security" "test/spec/Feature/OpenApi/OpenApiSpec.hs" && \
       grep -q "security definitions" "test/spec/Feature/OpenApi/OpenApiSpec.hs"; then
        echo "✓ OpenApiSpec.hs has Security test"
    else
        echo "✗ OpenApiSpec.hs missing Security test"
        test_status=1
    fi
else
    echo "✗ OpenApiSpec.hs missing or empty"
    test_status=1
fi

echo "Checking test/spec/Feature/OpenApi/SecurityOpenApiSpec.hs was created..."
if [ -f "test/spec/Feature/OpenApi/SecurityOpenApiSpec.hs" ] && [ -s "test/spec/Feature/OpenApi/SecurityOpenApiSpec.hs" ]; then
    if grep -q "Security active" "test/spec/Feature/OpenApi/SecurityOpenApiSpec.hs"; then
        echo "✓ SecurityOpenApiSpec.hs exists with Security active tests"
    else
        echo "✗ SecurityOpenApiSpec.hs missing Security active tests"
        test_status=1
    fi
else
    echo "✗ SecurityOpenApiSpec.hs missing or empty"
    test_status=1
fi

echo "Checking test/spec/Main.hs was updated..."
if [ -f "test/spec/Main.hs" ] && [ -s "test/spec/Main.hs" ]; then
    if grep -q "Feature.OpenApi.SecurityOpenApiSpec" "test/spec/Main.hs" && \
       grep -q "securityOpenApi" "test/spec/Main.hs"; then
        echo "✓ Main.hs includes SecurityOpenApiSpec"
    else
        echo "✗ Main.hs missing SecurityOpenApiSpec references"
        test_status=1
    fi
else
    echo "✗ Main.hs missing or empty"
    test_status=1
fi

echo "Checking test/spec/SpecHelper.hs was updated..."
if [ -f "test/spec/SpecHelper.hs" ] && [ -s "test/spec/SpecHelper.hs" ]; then
    if grep -q "configOpenApiSecurityActive" "test/spec/SpecHelper.hs" && \
       grep -q "testSecurityOpenApiCfg" "test/spec/SpecHelper.hs"; then
        echo "✓ SpecHelper.hs has configOpenApiSecurityActive and testSecurityOpenApiCfg"
    else
        echo "✗ SpecHelper.hs missing configOpenApiSecurityActive or testSecurityOpenApiCfg"
        test_status=1
    fi
else
    echo "✗ SpecHelper.hs missing or empty"
    test_status=1
fi

echo ""
if [ $test_status -eq 0 ]; then
    echo "✓ All checks passed - HEAD test files copied successfully"
    echo 1 > /logs/verifier/reward.txt
else
    echo "✗ Some checks failed"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
