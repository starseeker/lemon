# Testing Guide for Lemon Integration

## Quick Test

To quickly verify the stepcode grammar works with the new lemon:

```bash
cd stepcode
./test_lemon.sh
```

Expected output:
```
✓ Both lemon versions successfully parse expparse.y
✓ No syntax errors or conflicts reported
✓ Generated headers are identical (API compatible)
✓ Grammar file is compatible with new lemon version
```

## Manual Testing

### Generate Parser with New Lemon

```bash
# Compile lemon if needed
gcc -o lemon lemon.c

# Generate parser
./lemon stepcode/expparse.y

# Verify outputs
ls -lh stepcode/expparse.c stepcode/expparse.h stepcode/expparse.out
```

### Compare with Old Lemon

```bash
# Compile old lemon
cd stepcode
gcc -o lemon_step lemon_step.c

# Generate with old version (for comparison)
cp lempar_step.c lempar.c
./lemon_step expparse.y

# Compare headers (should be identical)
# Replace NEW_DIR with actual path to new version output
diff expparse.h "$NEW_DIR/expparse.h"
```

## Testing with Additional Stepcode Files

When scanner (perplex/re2c) and integration files are added, perform these tests:

### 1. Scanner Integration Test

Verify the scanner works with the new parser:

```bash
# Assuming scanner generates tokens
# Check that token IDs match expparse.h
grep "#define TOK_" stepcode/expparse.h
# Compare with scanner token definitions
```

### 2. Parser API Test

Create a minimal test program:

```c
#include "stepcode/expparse.h"
#include <stdio.h>
#include <stdlib.h>

int main() {
    void *parser = ParseAlloc(malloc);
    if (!parser) {
        fprintf(stderr, "Failed to allocate parser\n");
        return 1;
    }
    
    // Test basic parsing (add actual token stream)
    // Parse(parser, TOK_IDENTIFIER, token_value, parseData);
    
    ParseFree(parser, free);
    printf("Parser API test passed\n");
    return 0;
}
```

Compile and run:

```bash
gcc -o test_parser test_parser.c stepcode/expparse.c -I.
./test_parser
```

### 3. Error Handling Test

Verify error callbacks work correctly:

```c
// Test that %syntax_error directive works
// Parse invalid input and verify error handler is called
```

### 4. Memory Leak Test

Use valgrind or similar to detect leaks:

```bash
valgrind --leak-check=full ./your_stepcode_app input.exp
```

### 5. Behavioral Comparison Test

Run the same Express files through both old and new parsers:

```bash
# Generate with old lemon
cd stepcode
./lemon_step expparse.y
gcc -o parser_old expparse.c scanner.c main.c
./parser_old test.exp > output_old.txt

# Generate with new lemon  
../lemon expparse.y
gcc -o parser_new expparse.c scanner.c main.c
./parser_new test.exp > output_new.txt

# Compare outputs
diff output_old.txt output_new.txt
```

## Expected Results

### All Tests Should Show

1. ✓ No compilation errors
2. ✓ No runtime errors  
3. ✓ Identical behavior between old and new parsers
4. ✓ No memory leaks
5. ✓ Same error messages for invalid input

### Acceptable Differences

- Parser state machine details (in .out file)
- Internal optimization differences
- Line numbers in generated code

### Unacceptable Differences

- Different parse results for valid input
- Missing error detection
- Memory leaks
- API incompatibilities

## Troubleshooting

### Issue: Compilation Errors

**Symptom**: Generated code doesn't compile

**Check**:
- Verify lemon was compiled correctly: `./lemon -x`
- Check lempar.c template is accessible
- Verify grammar directives are correct

### Issue: Runtime Errors

**Symptom**: Parser crashes or misbehaves

**Check**:
- Verify ParseAlloc/ParseFree are called correctly
- Check extra_argument is passed properly
- Validate token IDs match between scanner and parser

### Issue: Different Behavior

**Symptom**: New parser behaves differently than old

**Check**:
- Compare .out files for conflict differences
- Verify grammar rules are identical
- Check if scanner needs updates

## Automated Testing

For CI/CD integration:

```bash
#!/bin/bash
set -e

echo "Running lemon compatibility tests..."

# Test grammar compilation
./stepcode/test_lemon.sh

# If scanner files exist, test integration
if [ -f "stepcode/scanner.c" ]; then
    echo "Testing scanner integration..."
    # Add scanner tests here
fi

# If full stepcode app exists, run regression tests
if [ -f "stepcode/main.c" ]; then
    echo "Running stepcode regression tests..."
    # Add full app tests here
fi

echo "All tests passed!"
```

## Performance Testing

Compare parser performance:

```bash
# Test with large Express file
time ./parser_old large_model.exp
time ./parser_new large_model.exp

# The new parser should be faster due to fewer states
```

## Continuous Integration

Add to your CI pipeline:

```yaml
# Example GitHub Actions workflow
steps:
  - name: Compile lemon
    run: gcc -o lemon lemon.c
    
  - name: Generate parser
    run: ./lemon stepcode/expparse.y
    
  - name: Test parser generation
    run: |
      test -f stepcode/expparse.c || exit 1
      test -f stepcode/expparse.h || exit 1
      
  - name: Run compatibility tests
    run: ./stepcode/test_lemon.sh
```

## Reporting Issues

If you encounter problems:

1. Run `./stepcode/test_lemon.sh` and capture output
2. Compare generated .out files for state differences
3. Check for conflicts or errors in lemon output
4. Create minimal reproducing example
5. Include grammar excerpt that causes the issue

## Additional Resources

- See `STEPCODE_INTEGRATION.md` for migration details
- See `stepcode/README.md` for usage documentation  
- See `lemon.html` for lemon documentation
- SQLite lemon documentation: https://sqlite.org/lemon.html
