# src — implementation of the compiler

This folder contains the C implementation files used by the `B` compiler.

- `main.c`   — driver: invokes the parser, emits the `.data` / `.text`
	sections and coordinates emission of captured function bodies. It also
	emits `extern` and `global` directives for symbols referenced across
	objects so static libraries can call into program data (used by bonus
	library helpers).
- `emit.c`   — emission buffer and helpers (capture semantics with
	`emit_begin_capture`/`emit_end_capture`), label stack and local label
	generation utilities.
- `symbols.c`— typed symbol table (labels, variables, functions, strings),
	string interning, and management of captured function bodies; it also
	emits `.data` entries and marks variable/function labels `global` when
	appropriate to allow external objects to reference them (ARG0/ARG1).

Design notes

- Syntax-directed translation: Bison semantic actions call functions in
	`emit.c` and `symbols.c` to produce assembly directly; no AST is built.
- Functions are represented as `.data` slots that contain the code address
	(called by pointer), e.g. `f: dd L0`.

Build

Run `make re` from the project root to build the `B` compiler.
