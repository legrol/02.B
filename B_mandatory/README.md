# B_mandatory — grammar and lexer

Contents

- `B.l` — lexer (Flex) that tokenizes B source.
- `B.y` — grammar (Bison) with syntax-directed semantic actions that emit
	NASM assembly directly (no AST is built).

Instructions

- Do not commit generated files (`parser.tab.c`, `lex.yy.c`). The `Makefile`
	runs `bison` and `flex` automatically.
- To modify the grammar or lexer edit `B.y` / `B.l` and run `make`.

Notes

- This folder contains the mandatory assignment files. A `B_bonus/`
	directory exists for optional extensions. The current compiler emits
	helper code (`print_eax`) by default and uses a simple `ARG0`/`ARG1`
	convention for passing values to library helpers (bonus helpers read these
	globals and return results in `eax`).
