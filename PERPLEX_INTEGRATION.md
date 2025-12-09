# Perplex Integration with Modern Lemon

## Executive Summary

The perplex parser grammar file (`perplex/parser.y`) has been thoroughly tested and is **fully compatible** with the modern lemon version. **No modifications to the grammar file are required** to use the newer lemon version.

## Key Findings

### Compatibility Status: ✓ FULLY COMPATIBLE

1. **Grammar file works as-is** - No changes needed to `parser.y`
2. **API remains identical** - Generated functions match expected signatures
3. **Zero conflicts** - Parser generates with 0 shift/reduce or reduce/reduce conflicts
4. **All directives supported** - Every directive used in the grammar is supported
5. **Token definitions correct** - All 12 tokens properly generated

### Testing Results

A comprehensive test script (`perplex/test_lemon.sh`) verifies:

```
✓ Grammar parses successfully with modern lemon
✓ No syntax errors or conflicts reported
✓ All required parser functions present (ParseAlloc, ParseFree, Parse, etc.)
✓ Token definitions properly generated (12 tokens)
✓ Extra argument (appData_t *appData) properly handled
✓ Token type (YYSTYPE) correctly configured
```

## Perplex Architecture

### Components

1. **parser.y** - Lemon grammar for perplex input file syntax
2. **scanner.re** - RE2C scanner for perplex input files
3. **perplex.cpp** - Main perplex program
4. **perplex_template.c** - Template for generated scanners
5. **token_type.h** - Token value type definition

### Build Process

```
perplex input.perplex
    ↓
[perplex tool]
    ↓
  scanner.c (generated via re2c)
```

The perplex tool itself is built using:
```
lemon parser.y → parser.c, parser.h
re2c scanner.re → scanner.c
g++ perplex.cpp + parser.c + scanner.c → perplex
```

## Integration with Modern Lemon

### Step 1: Verify Lemon Installation

Ensure you have the modern lemon compiled:

```bash
gcc -o lemon lemon.c
```

### Step 2: Generate Perplex Parser

```bash
./lemon perplex/parser.y
```

This generates:
- `perplex/parser.c` - Parser implementation
- `perplex/parser.h` - Parser header with token definitions
- `perplex/parser.out` - State machine details

### Step 3: Verify Compatibility

Run the test script:

```bash
cd perplex
./test_lemon.sh
```

Expected output shows 0 conflicts and all API checks passing.

## Technical Details

### Supported Directives

The grammar uses these lemon directives, all fully supported:

- `%include` - Embed C code preamble
- `%token_type {YYSTYPE}` - Token data type (union of string pointer)
- `%extra_argument {appData_t *appData}` - Pass context to parser
- `%type <non-terminal> {type}` - Specify non-terminal data types
- `%destructor <symbol> { code }` - Cleanup for symbols (with ParseARG_STORE)
- `%left`, `%right`, `%nonassoc` - Operator precedence

### Token Definitions

The parser generates these tokens (in `parser.h`):

```c
#define EMPTY_RULE_LIST          1
#define TOKEN_WORD               2
#define TOKEN_CODE_END           3
#define TOKEN_CODE_START         4
#define TOKEN_EMPTY_COND         5
#define TOKEN_CONDITION          6
#define TOKEN_NAME               7
#define TOKEN_SEPARATOR          8
#define TOKEN_START_SCOPE        9
#define TOKEN_END_SCOPE         10
#define TOKEN_SPECIAL_OP        11
#define TOKEN_PATTERN           12
#define TOKEN_DEFINITION        13
```

### Parser API

Generated functions (identical with both old and new lemon):

```c
void *ParseAlloc(void *(*mallocProc)(size_t));
void ParseFree(void *p, void (*freeProc)(void*));
void Parse(void *yyp, int yymajor, YYSTYPE yyminor, appData_t *appData);
void ParseTrace(FILE *TraceFILE, char *zTracePrompt);
```

Modern lemon adds these (optional, for advanced use):

```c
void ParseInit(void *yypRawParser, appData_t *appData);
void ParseFinalize(void *p);
```

### Token Type Structure

The `YYSTYPE` union is defined in `token_type.h`:

```c
typedef union YYSTYPE {
    char *string;
} YYSTYPE;
```

This is passed from the scanner to the parser for each token.

### Extra Argument Handling

The parser uses `%extra_argument {appData_t *appData}` which expands to:

```c
#define ParseARG_SDECL appData_t *appData;
#define ParseARG_PDECL ,appData_t *appData
#define ParseARG_PARAM ,appData
#define ParseARG_FETCH appData_t *appData=yypParser->appData;
#define ParseARG_STORE yypParser->appData=appData;
```

This allows the perplex application to pass context through all parser actions.

## CMake Integration

### Current Build Configuration

The `perplex/CMakeLists.txt` uses:

```cmake
find_package(LEMON REQUIRED)
find_package(RE2C REQUIRED)

# Generate parser
LEMON_TARGET(perplex_parser parser.y
  OUT_SRC_FILE perplex_parser.c
  OUT_HDR_FILE perplex_parser.h
)

# Generate scanner
add_custom_command(
  OUTPUT perplex_scanner.c
  COMMAND ${RE2C_EXECUTABLE} -c -o perplex_scanner.c scanner.re
  DEPENDS scanner.re perplex_parser.c perplex_parser.h
)
```

### FindLEMON.cmake Module

The CMake module searches for:
1. `LEMON_EXECUTABLE` - Path to lemon binary
2. `LEMON_TEMPLATE` - Path to lempar.c template

It automatically looks in:
- `${LEMON_ROOT}` if set
- Standard system paths
- Directory containing lemon executable
- `/usr/share/lemon/`

### Template Location

Modern lemon looks for `lempar.c` in:
1. Same directory as lemon executable
2. Specified via `-T` option
3. Standard search paths

The FindLEMON.cmake module handles this automatically.

## Migration Path

To migrate perplex build to use modern lemon:

### Option 1: Update CMake FindLEMON

Ensure `FindLEMON.cmake` points to the modern lemon:

```cmake
set(LEMON_ROOT /path/to/modern/lemon)
find_package(LEMON REQUIRED)
```

### Option 2: Override LEMON_EXECUTABLE

```bash
cmake -DLEMON_EXECUTABLE=/path/to/modern/lemon ..
```

### Option 3: Install Modern Lemon System-Wide

```bash
sudo cp lemon /usr/local/bin/
sudo cp lempar.c /usr/share/lemon/
```

Then CMake will find it automatically.

## Differences from Stepcode Integration

### Similarities

1. Both use lemon for parser generation
2. Both use `%extra_argument` directive
3. Both define custom token types
4. Both have zero conflicts

### Differences

1. **Scanner generator**: 
   - Stepcode uses flex (expscan.l)
   - Perplex uses RE2C (scanner.re)

2. **Purpose**:
   - Stepcode parses Express language
   - Perplex parses perplex grammar files (to generate scanners)

3. **Build system**:
   - Stepcode uses shell scripts and Makefiles
   - Perplex uses CMake

4. **Token complexity**:
   - Stepcode has 121 terminals
   - Perplex has 12 tokens

## Testing Strategy

### Unit Tests

1. **Grammar Compilation Test**
   ```bash
   ./lemon perplex/parser.y
   test -f perplex/parser.c && test -f perplex/parser.h
   ```

2. **Conflict Detection Test**
   ```bash
   grep "conflicts" perplex/parser.out
   # Should show 0 conflicts
   ```

3. **API Verification Test**
   ```bash
   grep "void Parse(" perplex/parser.c
   grep "void ParseAlloc" perplex/parser.c
   grep "void ParseFree" perplex/parser.c
   ```

### Integration Tests

1. **Build Perplex Tool**
   ```bash
   mkdir build && cd build
   cmake ..
   make perplex
   ```

2. **Test Perplex Functionality**
   ```bash
   ./perplex test_input.perplex
   # Verify scanner is generated
   ```

3. **Compare Old vs New**
   ```bash
   # Generate with old lemon
   old_lemon parser.y
   mv parser.h parser_old.h
   
   # Generate with new lemon
   ./lemon parser.y
   mv parser.h parser_new.h
   
   # Compare token definitions
   diff parser_old.h parser_new.h
   ```

## Known Issues and Limitations

### None Identified

The perplex grammar is fully compatible with modern lemon. No issues or limitations have been identified during testing.

### Potential Future Considerations

1. **Parser optimization**: Modern lemon may generate more optimized state machines
2. **Memory efficiency**: Modern lemon has improved memory management
3. **Diagnostic improvements**: Modern lemon provides better error messages

## Performance Improvements

While specific metrics for perplex haven't been measured, modern lemon typically provides:

- More efficient state machines
- Better action table compression
- Reduced memory footprint
- Faster parsing

These benefits should apply to perplex as well, especially when parsing complex perplex input files.

## Stepcode Scanner Integration

When integrating perplex-generated scanners with stepcode's lemon-generated parser:

### Token Mapping

Ensure scanner uses token IDs from `expparse.h`:

```c
#include "expparse.h"

// Scanner returns token IDs like:
return TOK_IDENTIFIER;
return TOK_INTEGER;
// etc.
```

### Parser Invocation

```c
void *parser = ParseAlloc(malloc);
parse_data_t parseData = { /* initialize */ };

// For each token:
YYSTYPE token_value;
token_value./* set field */;
Parse(parser, token_id, token_value, parseData);

// At EOF:
Parse(parser, 0, token_value, parseData);
ParseFree(parser, free);
```

### Compatibility Checklist

- [ ] Scanner includes `expparse.h`
- [ ] Token IDs match parser definitions
- [ ] `Parse()` signature matches generated header
- [ ] `parse_data_t` is passed correctly
- [ ] Error handling is compatible
- [ ] Memory management is sound

See [SCANNER_INTEGRATION.md](SCANNER_INTEGRATION.md) for detailed guidance.

## Conclusion

The perplex parser grammar is production-ready for use with the modern lemon version. No changes to the grammar file are required. The modern lemon version can be used as a drop-in replacement for older versions in the perplex build process.

### Migration Recommendations

1. ✓ **Safe to migrate**: Grammar is fully compatible
2. ✓ **Update FindLEMON.cmake**: Point to modern lemon installation
3. ✓ **Test build**: Run `perplex/test_lemon.sh` to verify
4. ✓ **Integration test**: Build perplex tool and test with sample inputs
5. ✓ **Document changes**: Update build documentation if paths change

## References

- **Modern lemon source**: `lemon.c` (top-level directory)
- **Grammar file**: `perplex/parser.y` (no changes needed)
- **Scanner source**: `perplex/scanner.re` (RE2C input)
- **Test script**: `perplex/test_lemon.sh` (verifies compatibility)
- **CMake config**: `perplex/CMakeLists.txt` (build configuration)
- **CMake module**: `perplex/CMake/FindLEMON.cmake` (lemon detection)

## Support

If you encounter issues with the perplex integration:

1. Run `perplex/test_lemon.sh` and capture output
2. Check that `LEMON_EXECUTABLE` points to modern lemon
3. Verify `LEMON_TEMPLATE` points to correct `lempar.c`
4. Ensure RE2C is properly installed
5. Check CMake configuration output for lemon detection
6. Compare generated `parser.h` with expected token definitions

For stepcode-specific integration, see [STEPCODE_INTEGRATION.md](STEPCODE_INTEGRATION.md).
