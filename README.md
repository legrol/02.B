# B Project — small B compiler (NASM backend)

Overview
- This repository contains a compact B compiler (Thompson's B subset) written
  with Flex/Bison and a NASM (Intel) assembly backend for i386.

Build requirements
- Tools: `gcc`, `make`, `flex`, `bison`, `nasm`, `ld` (32-bit i386 toolchain).

Build
1. `make re` — clean and build the compiler `B` (this invokes `bison` and
   `flex` to generate the parser/lexer sources).

Running and testing
- To compile a B program:
  1. `./B < prog.b > out.asm`
  2. `nasm -felf32 out.asm -o out.o`
  3. `ld -m elf_i386 brt0.o out.o -o final`
  4. `./final`

- Integration tests:
  - `make test` — build each `tests/*.b`, assemble with `nasm`, link with
    `brt0.o` and compare the program exit value with `tests/*.expect`.
  - `make test-errors` — run error tests in `tests_error/` and compare
    `stderr` against `*.expect`.

Notes about the evaluation environment
- The compiler emits NASM/Intel syntax. The provided `compile()` in some
  evaluation scripts calls `gcc -c -m32 -x assembler`, which invokes GNU
  assembler (gas) and does not accept NASM directives and syntax. To help
  evaluation we provide two convenience helpers that assemble NASM output:
  - `./compile_nasm.sh file.b` — assembles with `nasm -felf32` and links with
    `brt0.o` to produce an executable.
  - `make eval_compile ARGS="file1.b file2.b"` — equivalent Make target.

Quick notes
- `brt0.o` must be present in the repository root for linking.
- To suppress the `print_eax` helper emission set the environment variable
  `NO_PRINT=1` before running `./B`.
