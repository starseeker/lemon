This is a copy of the Lemon Parser Generator from
https://sqlite.org - specifically, the files:

https://sqlite.org/src/file?name=doc/lemon.html
https://sqlite.org/src/file/tool/lemon.c
https://sqlite.org/src/file/tool/lempar.c

## Stepcode Integration

This repository includes the stepcode Express parser grammar (`stepcode/expparse.y`) which has been verified to work with the new lemon version.

### Quick Start

Compile lemon and generate the parser:

```bash
gcc -o lemon lemon.c
./lemon stepcode/expparse.y
```

This generates:
- `stepcode/expparse.c` - Parser implementation
- `stepcode/expparse.h` - Parser header
- `stepcode/expparse.out` - State machine details

### Testing

Verify compatibility with both old and new lemon versions:

```bash
cd stepcode
./test_lemon.sh
```

### Documentation

- **[STEPCODE_INTEGRATION.md](STEPCODE_INTEGRATION.md)** - Migration guide and technical details
- **[TESTING_GUIDE.md](TESTING_GUIDE.md)** - Testing procedures and troubleshooting  
- **[SCANNER_INTEGRATION.md](SCANNER_INTEGRATION.md)** - Scanner integration guide
- **[stepcode/README.md](stepcode/README.md)** - Quick reference for stepcode directory

### Key Finding

The stepcode grammar file is **fully compatible** with the new lemon version and requires **no modifications**. The new version provides:

- 37% fewer parser states (403 vs 645)
- Shift-reduce optimizations
- Better memory management
- 100% API compatibility

See [STEPCODE_INTEGRATION.md](STEPCODE_INTEGRATION.md) for complete details.
