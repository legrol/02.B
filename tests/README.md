# tests — functional test cases

Structure

- Each test is a pair: `*.b` (input source) and `*.expect` (expected integer exit value).

Usage

- Run `make test` from the project root. The test runner compiles each `*.b` with `./B`, assembles the produced `out.asm` using `nasm -felf32`, links with `brt0.o`, runs the executable, and compares the resulting `eax` value with `*.expect`.

Format

- Test sources `*.b` are small B programs. The compiler produces code that returns a result in `eax` which the test harness compares to `*.expect`.
