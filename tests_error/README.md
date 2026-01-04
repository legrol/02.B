# tests_error — tests that should produce errors

Structure

- Each test is a `*.b` file in this directory. The test runner captures `stderr` and compares it against `*.expect` files.

Usage

- Run `make test-errors` from the project root to execute the error tests. The harness compiles the input with `./B` and verifies the produced diagnostics match `*.expect`.

Notes

- These tests are used to verify the compiler emits correct and stable error messages for invalid programs.
