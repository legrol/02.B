# includes — public headers for the compiler

Contents

- `B.h`      — public declarations used by the parser and the runtime.
- `colors.h` — color and formatting macros used by the test runner and Makefile messages.
- `emit.h`   — declarations for the emission API used by the Bison semantic actions and the emitter implementation.

Purpose

This directory contains the header files that define the interfaces between the
front-end (parser/lexer) and the implementation in `src/`.

Notes

- Do not modify these headers lightly: many source files depend on the
  declarations they contain.
- If you add a new header here, update the `Makefile` include flags if needed
  and add a short README note explaining the new API.

Build

- The `Makefile` includes this directory via `-Iincludes` when compiling the
  `B` compiler.

Examples

- The Bison grammar (`B.y`) includes `B.h` to access token and helper
  declarations.

