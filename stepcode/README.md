# Stepcode Lemon Integration

This directory contains the Express parser grammar file (`expparse.y`) for stepcode, along with the older version of lemon that was previously used.

## Files

- `expparse.y` - Express language grammar file for the lemon parser generator
- `lemon_step.c` - Older version of lemon (preserved for reference)
- `lempar_step.c` - Template file for the older lemon version
- `test_lemon.sh` - Test script to verify compatibility between old and new lemon versions

## Compatibility with New Lemon

The grammar file `expparse.y` has been verified to be **fully compatible** with the newer lemon version located in the parent directory. No changes to the grammar file are required.

### Verification Results

Running `test_lemon.sh` confirms:

- ✓ Grammar parses successfully with both old and new lemon versions
- ✓ No syntax errors or conflicts in either version  
- ✓ Generated headers are identical (API compatible)
- ✓ The new version generates more optimized parser code (403 states vs 645 states)

### Key Improvements in New Lemon

The newer lemon version provides:

1. **Better optimization** - Generates 37% fewer states (403 vs 645)
2. **Shift-reduce actions** - Combines shift and reduce operations for efficiency
3. **Improved memory management** - Better allocation tracking and cleanup
4. **More detailed statistics** - Enhanced reporting of parser characteristics
5. **Enhanced character handling** - Safer character classification macros

### Usage

To generate the parser with the **new lemon** (recommended):

```bash
cd /path/to/lemon
./lemon stepcode/expparse.y
```

This will generate:
- `stepcode/expparse.c` - The parser implementation
- `stepcode/expparse.h` - The parser header file
- `stepcode/expparse.out` - Detailed parser state information

The new lemon will automatically use `lempar.c` from the parent directory as the template.

### Directives Used

The grammar file uses the following lemon directives, all supported in both versions:

- `%include` - Embed C code in the generated parser
- `%extra_argument` - Pass additional context to parser functions
- `%type` - Specify data types for non-terminals
- `%destructor` - Define cleanup code for symbols
- `%left`, `%right`, `%nonassoc` - Define operator precedence and associativity
- `%start_symbol` - Specify the starting non-terminal
- `%token_type` - Define the token data type
- `%syntax_error` - Custom syntax error handling
- `%stack_size` - Set parser stack size (0 = dynamic)
- `%stack_overflow` - Handle stack overflow conditions

### Migration Notes

When migrating to use the new lemon version:

1. The grammar file requires **no modifications**
2. The generated API is identical (same function signatures)
3. The generated parser is functionally equivalent but more efficient
4. Any code that uses the generated parser should work without changes

### Testing

To verify compatibility before migrating:

```bash
cd stepcode
./test_lemon.sh
```

This will test the grammar with both lemon versions and report any differences.
