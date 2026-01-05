#!/usr/bin/env bash

# ********************************************************************************
# Error-tests runner (executable from `utils/`)
#
# This script runs the tests in `tests_error/`. For each test it captures
# stderr and compares it to an expected file. Two modes are supported:
#  - stdin: run `$ROOT/B < test.b` and capture stderr
#  - openfile: run `$ROOT/B missing_file_for_test.b` to exercise fopen/freopen errors
#
# It normalizes trailing spaces and collapses multi-line output when printing
# one-line summaries. Create `.expect` files automatically if missing.
# ********************************************************************************

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ERR_DIR="$ROOT/tests_error"

echo ""

run_test() {
  name="$1"
  mode="$2" # stdin | openfile
  bfile="$ERR_DIR/${name}.b"
  expect="$ERR_DIR/${name}.expect"
  out="$ERR_DIR/${name}.out"

  if [ "$mode" = "stdin" ]; then
    "$ROOT/B" < "$bfile" > /dev/null 2> "$out" || true
  else
    "$ROOT/B" missing_file_for_test.b > /dev/null 2> "$out" || true
  fi

  sed -e 's/[[:space:]]*$//' "$out" > "$out.tmp" && mv "$out.tmp" "$out"

  if [ ! -f "$expect" ]; then
    cp "$out" "$expect"
    echo "Created expected: $expect"
  fi

  actual_line=$(tr '\n' ' ' < "$out" | sed -e 's/[[:space:]]\+/ /g' -e 's/^ //; s/ $//')
  expected_line=$(tr '\n' ' ' < "$expect" | sed -e 's/[[:space:]]\+/ /g' -e 's/^ //; s/ $//')

  if cmp -s "$out" "$expect"; then
    printf "Test %-25s : result=%-56s expected=%-56s ✅ OK\n" "$name" "$actual_line" "$expected_line"
  else
    printf "Test %-25s : result=%-56s expected=%-56s ❌ FAIL\n" "$name" "$actual_line" "$expected_line"
    echo "--- actual stderr ---"
    sed -n '1,200p' "$out"
    echo "--- expected stderr ---"
    sed -n '1,200p' "$expect"
    exit 1
  fi
}

run_test "lexer_error" "stdin"
run_test "syntax_error" "stdin"
run_test "test_openfile" "openfile"
run_test "unclosed_paren" "stdin"

run_test "label_var_collision" "stdin"
run_test "test_index_func" "stdin"
run_test "test_extrn_var_collision" "stdin"

echo ""
echo "All error tests passed."
