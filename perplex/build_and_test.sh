#!/bin/bash
# Build and test perplex with modern lemon and RE2C

set -e  # Exit on error

echo "================================================"
echo "Perplex Build and Test with Modern Lemon + RE2C"
echo "================================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"

# Check for required tools
echo "=== Checking Requirements ==="

if ! command -v gcc &> /dev/null; then
    echo -e "${RED}✗ gcc not found${NC}"
    exit 1
fi
echo -e "${GREEN}✓ gcc found${NC}"

if ! command -v g++ &> /dev/null; then
    echo -e "${RED}✗ g++ not found${NC}"
    exit 1
fi
echo -e "${GREEN}✓ g++ found${NC}"

if ! command -v re2c &> /dev/null; then
    echo -e "${YELLOW}⚠ re2c not found - install with: sudo apt install re2c${NC}"
    exit 1
fi
echo -e "${GREEN}✓ re2c found ($(re2c --version | head -1))${NC}"

echo ""

# Build lemon if needed
echo "=== Building Lemon ==="
if [ ! -f "$PARENT_DIR/lemon" ]; then
    echo "Compiling lemon..."
    cd "$PARENT_DIR"
    gcc -o lemon lemon.c
    if [ $? -ne 0 ]; then
        echo -e "${RED}✗ Failed to compile lemon${NC}"
        exit 1
    fi
fi
echo -e "${GREEN}✓ Lemon ready${NC}"
echo ""

# Generate parser with lemon
echo "=== Generating Parser with Lemon ==="
cd "$PARENT_DIR"
./lemon perplex/parser.y
if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Failed to generate parser${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Parser generated (parser.c, parser.h)${NC}"

# Copy to expected names
cd perplex
cp parser.h perplex_parser.h
cp parser.c perplex_parser.c
echo -e "${GREEN}✓ Parser files copied to perplex_parser.*${NC}"
echo ""

# Generate scanner with RE2C
echo "=== Generating Scanner with RE2C ==="
re2c -c -o perplex_scanner.c scanner.re
if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Failed to generate scanner${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Scanner generated (perplex_scanner.c)${NC}"
echo ""

# Compile C files
echo "=== Compiling C Files ==="
gcc -c perplex_scanner.c -I.
if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Failed to compile scanner${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Scanner compiled${NC}"

gcc -c perplex_parser.c -I.
if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Failed to compile parser${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Parser compiled${NC}"
echo ""

# Compile C++ files
echo "=== Compiling C++ Files ==="
g++ -c perplex.cpp -I.
if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Failed to compile perplex.cpp${NC}"
    exit 1
fi
echo -e "${GREEN}✓ perplex.cpp compiled${NC}"

g++ -c mbo_getopt.cpp -I.
if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Failed to compile mbo_getopt.cpp${NC}"
    exit 1
fi
echo -e "${GREEN}✓ mbo_getopt.cpp compiled${NC}"
echo ""

# Link
echo "=== Linking Perplex ==="
g++ -o perplex perplex.o mbo_getopt.o perplex_parser.o perplex_scanner.o
if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Failed to link perplex${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Perplex executable created${NC}"
echo ""

# Test perplex
echo "=== Testing Perplex ==="
./perplex --version > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Perplex executable doesn't work${NC}"
    exit 1
fi

VERSION=$(./perplex --version 2>&1)
echo -e "${GREEN}✓ Perplex works (version: $VERSION)${NC}"

# Test with sample input
if [ -f test_input.perplex ]; then
    echo "Testing with sample input..."
    ./perplex -t perplex_template.c -o test_output.c test_input.perplex
    if [ $? -eq 0 ] && [ -f test_output.c ]; then
        echo -e "${GREEN}✓ Successfully generated scanner from test input${NC}"
        OUTPUT_SIZE=$(wc -l < test_output.c)
        echo "  Generated scanner: $OUTPUT_SIZE lines"
    else
        echo -e "${YELLOW}⚠ Could not test with sample input${NC}"
    fi
fi
echo ""

# Summary
echo "==================================================="
echo -e "${GREEN}SUCCESS! Perplex built and tested successfully!${NC}"
echo "==================================================="
echo ""
echo "Components built:"
echo "  - Lemon parser generator"
echo "  - Perplex parser (from parser.y using lemon)"
echo "  - Perplex scanner (from scanner.re using re2c)"
echo "  - Perplex executable"
echo ""
echo "Next steps:"
echo "  1. Use perplex to generate scanners: ./perplex input.perplex"
echo "  2. Run grammar test: ./test_lemon.sh"
echo "  3. See PERPLEX_INTEGRATION.md for details"
echo ""
exit 0
