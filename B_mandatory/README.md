# B_mandatory — grammar and lexer

Contents

- `B.l` — lexer (Flex) that tokenizes B source.
- `B.y` — grammar (Bison) with syntax-directed semantic actions that emit NASM assembly directly (no AST is built).

Instructions

- Do not commit generated files (`parser.tab.c`, `lex.yy.c`). The `Makefile` runs `bison` and `flex` automatically.
- To modify the grammar or lexer edit `B.y` / `B.l` and run `make`.

Notes

- This folder contains the mandatory assignment files. A `B_bonus/` directory exists for optional extensions.
