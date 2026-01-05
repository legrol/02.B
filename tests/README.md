# tests — functional test cases

Structure

- Each test is a pair: `*.b` (input source) and `*.expect` (expected integer exit value).

Usage

- Run `make test` from the project root. The test runner compiles each `*.b`
	with `./B`, assembles the produced `out.asm` using `nasm -felf32`, links
	with `brt0.o`, runs the executable, and compares the resulting `eax`
	value with `*.expect`.

Bonus tests

- Bonus tests are located under `tests_bonus/`. Use `make test-bonus-lib` to
	build the bonus library and run the bonus test suite. The test runner for
	bonus tests supports three expectation modes:
	- integer expectations (exact numeric comparison),
	- `IS_NUMERIC` (asserts the program prints a positive integer), and
	- exact string expectations (used for textual output). The runner handles
		the library build and linking automatically.

Format

- Test sources `*.b` are small B programs. The compiler produces code that
	returns a result in `eax` which the test harness compares to `*.expect`.
