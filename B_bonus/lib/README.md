# B Bonus Library

This directory holds a small standard library for the B bonus features.

Contents / Layout

- `Makefile` — builds `libb.a` (32-bit objects) using `as --32` and `ar`.
- Several helpers implemented in pure assembly. The repository includes a
  few example functions used by the project's bonus tests.

Provided helpers

- `get_ten()` — returns integer `10`.
- `b_print()` — zero-argument function: reads a pointer from the global data
  label `ARG0` and prints the pointed NUL-terminated string followed by a
  newline. Returns the printed length (not counting the newline).
- `b_time()` — zero-argument helper that returns the current time in seconds
  (implemented via a direct syscall to avoid linking to libc).
- `b_ipow()` — integer exponentiation helper (reads its operands from
  `ARG0` and `ARG1` globals and returns the result in `eax`).

Build

```sh
cd B_bonus/lib
make
```

This produces `libb.a`. The Makefile assembles objects with `as --32` and creates
the static archive. See `Makefile` for exact assembler flags.

Linking / Usage

- Link `libb.a` when producing a final executable:

```sh
ld -m elf_i386 brt0.o out.o B_bonus/lib/libb.a -o final
```

- Or let the project helper script build and link the library automatically:

```sh
make assemble INPUT=tests/test_b_ipow.b USE_BONUS_LIB=1
```

Notes

- Argument convention: to keep the compiler small we use a simple data-based
  calling convention for bonus helpers: write values into `ARG0`, `ARG1`,
  ... and call a zero-argument function in the library which reads those
  globals. Example in B:

```b
ARG0 = 2;      # base
ARG1 = 10;     # exponent
return b_ipow();
```

- The library is implemented in pure assembly to avoid depending on libc and
  to eliminate the need for 32-bit C development libraries (`gcc-multilib`).
  All helpers use direct syscalls where appropriate.

Adding new helpers

1. Add a `.s` file implementing the helper in AT&T syntax (32-bit i386).
2. Run `make` in this directory to rebuild `libb.a` (the test runner rebuilds it automatically when needed).
