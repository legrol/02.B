# tests_bonus — bonus tests for the B compiler

This directory contains optional tests that exercise the project's bonus
features and the small runtime library located at `B_bonus/lib`.

Purpose
- Validate optional helpers and behaviors that are not required for the core
  assignment but are useful demonstrations (e.g. `b_print`, `b_time`, `b_ipow`).

Expectation file formats
- Each test is a pair: `XXX.b` (B source) and `XXX.expect` (expected output).
- The test runner supports three kinds of expectations:
  - Integer: a plain integer (e.g. `1024`) — the test runner compares the
    program's printed numeric result against this value.
  - `IS_NUMERIC`: the test asserts that the program prints a positive
    integer (used for `b_time` where the exact value varies).
  - Exact string: any other content in the `.expect` file is treated as a
    literal stdout comparison (useful for `b_print` which prints strings).

Notes on how tests are executed
- Run the whole bonus suite (the runner will build the library automatically):

  ```sh
  make test-bonus-lib
  ```

- The runner builds `B_bonus/lib/libb.a` (32-bit archive) and links it with
  each compiled test program. Make sure you have a 32-bit toolchain
  (`nasm`, `ld -m elf_i386`), and access to the `as` assembler.

Calling convention for bonus helpers
- To keep the compiler small we use a simple data-based convention for
  passing arguments to bonus helpers: tests store arguments into global data
  labels `ARG0`, `ARG1`, ... and call zero-argument library functions. For
  example:

  ```b
  ARG0 = 2; ARG1 = 10;
  return b_ipow();
  ```

- Library helpers are free to read those globals and return results in `eax`.

Suppressing `print_eax` in emitted programs
- The compiler by default appends a small helper that prints the final `eax`
  value. The test runner knows how to handle that, but if you want to
  suppress `print_eax` when generating assembly manually, run the compiler
  with `NO_PRINT=1` in the environment:

  ```sh
  NO_PRINT=1 ./B < test.b > out.asm
  ```

Adding new bonus tests
- Create `tests_bonus/<name>.b` and `tests_bonus/<name>.expect`.
- If the test needs the bonus library the runner will build and link it
  automatically. If you create new helpers in `B_bonus/lib`, add the
  implementation and run `make -C B_bonus/lib` (the test runner does this
  step for you when running `make test-bonus-lib`).

Troubleshooting
- If the runner fails to link, ensure `libb.a` exists and that your system
  supports 32-bit linking and the `as --32` assembler is available.

Enjoy experimenting with the bonus helpers — they are deliberately small and
designed to be easy to extend.
