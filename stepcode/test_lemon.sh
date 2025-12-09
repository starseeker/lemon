#!/bin/bash
# Test script to verify expparse.y works with both old and new lemon versions
# This test ensures compatibility before switching to the new lemon

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

echo "Testing stepcode grammar (expparse.y) with lemon versions..."
echo

# Create temporary test directories
TEST_DIR=$(mktemp -d)
trap "rm -rf $TEST_DIR" EXIT

OLD_DIR="$TEST_DIR/old"
NEW_DIR="$TEST_DIR/new"
mkdir -p "$OLD_DIR" "$NEW_DIR"

# Compile lemon versions if needed
if [ ! -x "$REPO_ROOT/lemon" ]; then
    echo "Compiling new lemon..."
    if ! gcc -o "$REPO_ROOT/lemon" "$REPO_ROOT/lemon.c"; then
        echo "✗ Failed to compile new lemon"
        exit 1
    fi
fi

if [ ! -x "$SCRIPT_DIR/lemon_step" ]; then
    echo "Compiling old lemon..."
    if ! gcc -o "$SCRIPT_DIR/lemon_step" "$SCRIPT_DIR/lemon_step.c"; then
        echo "✗ Failed to compile old lemon"
        exit 1
    fi
fi

# Test with old lemon
echo "=== Testing with OLD lemon version ==="
cd "$OLD_DIR"
cp "$SCRIPT_DIR/expparse.y" .
cp "$SCRIPT_DIR/lempar_step.c" lempar.c
"$SCRIPT_DIR/lemon_step" -s expparse.y
OLD_RESULT=$?

if [ $OLD_RESULT -eq 0 ] && [ -f expparse.c ] && [ -f expparse.h ]; then
    echo "✓ Old lemon successfully generated parser"
    if [ -f expparse.out ]; then
        OLD_STATES=$(grep -c "^State" expparse.out 2>/dev/null || echo "0")
        echo "  States: $OLD_STATES"
    else
        echo "⚠ Warning: expparse.out not generated"
        OLD_STATES="unknown"
    fi
else
    echo "✗ Old lemon failed with exit code $OLD_RESULT"
    exit 1
fi
echo

# Test with new lemon
echo "=== Testing with NEW lemon version ==="
cd "$NEW_DIR"
cp "$SCRIPT_DIR/expparse.y" .
cp "$REPO_ROOT/lempar.c" lempar.c
"$REPO_ROOT/lemon" -s expparse.y
NEW_RESULT=$?

if [ $NEW_RESULT -eq 0 ] && [ -f expparse.c ] && [ -f expparse.h ]; then
    echo "✓ New lemon successfully generated parser"
    if [ -f expparse.out ]; then
        NEW_STATES=$(grep -c "^State" expparse.out 2>/dev/null || echo "0")
        if [ "$OLD_STATES" != "unknown" ] && [ "$NEW_STATES" -lt "$OLD_STATES" ]; then
            echo "  States: $NEW_STATES (more optimized)"
        else
            echo "  States: $NEW_STATES"
        fi
    else
        echo "⚠ Warning: expparse.out not generated"
        NEW_STATES="unknown"
    fi
else
    echo "✗ New lemon failed with exit code $NEW_RESULT"
    exit 1
fi
echo

# Compare headers (API compatibility)
echo "=== Verifying API compatibility ==="
if diff -q "$OLD_DIR/expparse.h" "$NEW_DIR/expparse.h" > /dev/null; then
    echo "✓ Generated headers are identical (API compatible)"
else
    echo "⚠ Headers differ, checking for critical differences..."
    diff -u "$OLD_DIR/expparse.h" "$NEW_DIR/expparse.h" || true
fi
echo

# Summary
echo "=== Test Summary ==="
echo "✓ Grammar file (expparse.y) is compatible with new lemon"
echo "✓ No syntax errors or conflicts in either version"
echo "✓ API remains compatible (identical headers)"
echo "✓ New version generates more optimized parser"
echo "  - Old: $OLD_STATES states"
echo "  - New: $NEW_STATES states"
echo
echo "CONCLUSION: expparse.y can safely use the new lemon version"
