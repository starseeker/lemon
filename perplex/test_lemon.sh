#!/bin/bash
# Test script to verify perplex parser.y works with modern lemon

echo "Testing perplex grammar (parser.y) with lemon..."
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"

# Check if lemon exists in parent directory
if [ ! -f "$PARENT_DIR/lemon" ]; then
    echo "Compiling lemon..."
    cd "$PARENT_DIR"
    gcc -o lemon lemon.c
    if [ $? -ne 0 ]; then
        echo -e "${RED}✗ Failed to compile lemon${NC}"
        exit 1
    fi
fi

# Generate parser with modern lemon
echo "=== Testing with modern lemon version ==="
cd "$PARENT_DIR"
./lemon perplex/parser.y 2>&1 | tee /tmp/perplex_lemon.log

# Check if generation succeeded
if [ ! -f "perplex/parser.c" ] || [ ! -f "perplex/parser.h" ]; then
    echo -e "${RED}✗ Failed to generate parser${NC}"
    exit 1
fi

# Extract statistics
echo "Parser statistics:"
if [ -f "perplex/parser.out" ]; then
    grep -E "terminal symbols|non-terminal symbols|rules|states|conflicts" perplex/parser.out | sed 's/^/  /'
fi

# Check for conflicts
CONFLICTS=$(grep "conflicts" perplex/parser.out 2>/dev/null | grep -o "[0-9]*" | tail -1)
if [ "$CONFLICTS" = "0" ] || [ -z "$CONFLICTS" ]; then
    echo -e "${GREEN}✓ Modern lemon successfully generated parser (0 conflicts)${NC}"
else
    echo -e "${RED}✗ Parser has $CONFLICTS conflicts${NC}"
    exit 1
fi

# Get number of states
STATES=$(grep "states\." perplex/parser.out 2>/dev/null | grep -o "[0-9]*" | head -1)
if [ -n "$STATES" ]; then
    echo "  States: $STATES"
fi

# Verify critical functions exist in generated parser
echo ""
echo "=== Verifying generated parser API ==="
MISSING_FUNCTIONS=""

if ! grep -q "^void ParseAlloc" perplex/parser.c && ! grep -q "^void \*ParseAlloc" perplex/parser.c; then
    MISSING_FUNCTIONS="$MISSING_FUNCTIONS ParseAlloc"
fi

if ! grep -q "^void ParseFree" perplex/parser.c; then
    MISSING_FUNCTIONS="$MISSING_FUNCTIONS ParseFree"
fi

if ! grep -q "^void Parse(" perplex/parser.c; then
    MISSING_FUNCTIONS="$MISSING_FUNCTIONS Parse"
fi

if [ -n "$MISSING_FUNCTIONS" ]; then
    echo -e "${RED}✗ Missing required functions:$MISSING_FUNCTIONS${NC}"
    exit 1
else
    echo -e "${GREEN}✓ All required parser functions present${NC}"
fi

# Verify token definitions in header
echo ""
echo "=== Verifying token definitions ==="
TOKEN_COUNT=$(grep -c "^#define TOKEN_" perplex/parser.h)
if [ "$TOKEN_COUNT" -gt 0 ]; then
    echo -e "${GREEN}✓ Token definitions generated ($TOKEN_COUNT tokens)${NC}"
    echo "  Sample tokens:"
    grep "^#define TOKEN_" perplex/parser.h | head -5 | sed 's/^/    /'
else
    echo -e "${RED}✗ No token definitions found${NC}"
    exit 1
fi

# Verify extra_argument is properly handled
echo ""
echo "=== Verifying extra_argument handling ==="
if grep -q "ParseARG_PDECL" perplex/parser.c && grep -q "appData_t \*appData" perplex/parser.c; then
    echo -e "${GREEN}✓ Extra argument (appData_t *appData) properly handled${NC}"
else
    echo -e "${RED}✗ Extra argument handling issue${NC}"
    exit 1
fi

# Verify token_type usage
echo ""
echo "=== Verifying token type handling ==="
if grep -q "YYSTYPE\|ParseTOKENTYPE" perplex/parser.c; then
    echo -e "${GREEN}✓ Token type (YYSTYPE) properly handled${NC}"
else
    echo -e "${RED}✗ Token type handling issue${NC}"
    exit 1
fi

# Final summary
echo ""
echo "=== Test Summary ==="
echo -e "${GREEN}✓ Grammar file (parser.y) is compatible with modern lemon${NC}"
echo -e "${GREEN}✓ No syntax errors or conflicts${NC}"
echo -e "${GREEN}✓ All required parser functions generated${NC}"
echo -e "${GREEN}✓ Token definitions properly generated${NC}"
echo -e "${GREEN}✓ Extra argument handling correct${NC}"
echo ""
echo "CONCLUSION: parser.y can safely use the modern lemon version"

exit 0
