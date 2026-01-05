# B Bonus Library

This directory holds a small standard library for the B bonus features.

Layout:

- `Makefile` — builds a static archive `libb.a` from `.c` sources (uses `-m32`).
- `print.c` — example function `int print(int)` that prints an integer and returns it.

How to build:

```markdown
# B Bonus Library

This directory holds a small standard library for the B bonus features.

Contents

- `Makefile` — builds `libb.a` (32-bit objects) using `gcc -m32` and `ar`.
- Several helpers implemented in C or assembly. The repository includes a
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

This produces `libb.a`. The library is built with flags that avoid depending
on libc for small syscalls and helper functions (see `Makefile` for details).

Linking

Link `libb.a` when producing a final executable:

```sh
ld -m elf_i386 brt0.o out.o B_bonus/lib/libb.a -o final
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

- If you prefer to write library functions with conventional C arguments you
	can edit the compiler to emit proper call-site argument passing, but that
	requires grammar/codegen changes.

Adding functions

1. Add a `.c` or `.s` file implementing the helper.
2. Run `make` to rebuild `libb.a` (the test runner rebuilds it automatically
	 when needed).

```
