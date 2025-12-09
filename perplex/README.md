Perplex is a scanner-generator that works with RE2C.

## Lemon Integration

The perplex parser (`parser.y`) has been verified to be **fully compatible** with the modern lemon version.

### Testing

To verify compatibility:

```bash
./test_lemon.sh
```

Expected results:
- ✓ 0 conflicts
- ✓ All required parser functions generated
- ✓ 12 tokens properly defined
- ✓ Extra argument handling correct

### Building with Modern Lemon

#### Quick Build (Manual)

Build perplex directly using the provided script:

```bash
# Requires: gcc, g++, and re2c
# Install re2c on Ubuntu: sudo apt install re2c

cd perplex
./build_and_test.sh
```

This will:
1. Compile modern lemon
2. Generate parser with lemon
3. Generate scanner with re2c
4. Compile and link perplex
5. Test the executable

#### CMake Build

The perplex build system uses CMake with `FindLEMON.cmake` to locate lemon. Ensure the modern lemon is installed:

```bash
# In the repository root:
gcc -o lemon lemon.c
sudo cp lemon /usr/local/bin/
sudo cp lempar.c /usr/share/lemon/

# Then build perplex:
cd perplex
mkdir build && cd build
cmake ..
make
```

### Documentation

See [PERPLEX_INTEGRATION.md](../PERPLEX_INTEGRATION.md) in the repository root for complete technical details on the lemon integration.
