
# B Project — small B compiler (NASM backend)

Overview
- This repository contains a compact B compiler (a small, teaching-oriented
  subset of B) implemented using Flex/Bison and an Intel/NASM backend that
  emits 32-bit i386 assembly.

Build requirements
- Tools: `gcc` (with multilib support), `make`, `flex`, `bison`, `nasm`, `ld`.
  You need a 32-bit i386 toolchain (or multilib) to assemble and link test
  programs and the optional bonus library.

Build
1. `make re` — clean and build the compiler `B` (this invokes `bison` and
   `flex` to generate the parser/lexer sources).

Running and testing
- To compile a B program manually:
  1. `./B < prog.b > out.asm`
  2. `nasm -felf32 out.asm -o out.o`
  3. `ld -m elf_i386 brt0.o out.o -o final`
  4. `./final`

- Test targets provided:
  - `make test` — run the core test suite under `tests/`. The runner compiles
    each `*.b`, assembles with `nasm`, links with `brt0.o` and compares the
    program result against `*.expect`.
  - `make test-errors` — run negative tests under `tests_error/` and compare
    `stderr` messages with expectations.
  - `make test-bonus-lib` — run the bonus tests while building and linking
    the bonus static library `B_bonus/lib/libb.a` (see below).

Bonus library
- The repository includes an optional bonus library in `B_bonus/lib`. It
  provides small helper routines implemented in C or assembly and built as a
  32-bit static archive `libb.a`. Example functions included are:
  - `get_ten()` — returns `10` (simple demo).
  - `b_print()` — zero-argument helper that reads the string pointer from the
    global `ARG0` variable and prints it (the library exposes a simple
    convention to avoid changing the compiler's call ABI).
  - `b_time()` — returns current epoch seconds (uses a direct syscall in the
    library implementation to avoid linking to libc).
  - `b_ipow()` — integer power routine (reads `ARG0` and `ARG1` from `.data`).

  Build the bonus library and run bonus tests with:

  ```sh
  make test-bonus-lib
  # or build manually:
  make -C B_bonus/lib
  # then link with the produced libb.a when creating a final executable
  ld -m elf_i386 brt0.o out.o B_bonus/lib/libb.a -o final
  ```

Notes about call conventions and helpers
- To keep the compiler grammar small we currently use a tiny convention for
  passing arguments to bonus helpers: programs write values into global data
  labels `ARG0`, `ARG1`, ... and call zero-argument library functions that
  read those globals. For example:

  ```b
  ARG0 = "Hello";  # store string pointer
  return b_print();  # b_print reads ARG0 and prints it
  ```

- By default the compiler emits a small `print_eax` helper at the end of each
  generated program which prints the final `eax` result. To suppress that
  emission set `NO_PRINT=1` in the environment when running `./B`.

Implementation notes / troubleshooting
- The compiler emits NASM/Intel syntax; tests assemble with `nasm -felf32` and
  link with `ld -m elf_i386`. The project includes small scripts and targets
  that automate these steps (see `utils/` and `tests_bonus/`).

Quick tips
- `brt0.o` must be present in the repository root for linking.
- If you need to inspect emitted assembly for a test, run:

  ```sh
  ./B < tests/some_test.b > out.asm
  sed -n '1,200p' out.asm
  ```

