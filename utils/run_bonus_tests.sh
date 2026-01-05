#!/bin/sh
# ******************************************************************************************************** #
# run_bonus_tests.sh - run bonus tests from the repo root (executable from `utils/`)
# ******************************************************************************************************** #

set -u
fail=0

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TB_DIR="$ROOT/tests_bonus"

for f in "$TB_DIR"/*.b; do
  [ -e "$f" ] || continue
  tname=$(basename "$f" .b)
  exp_file="$TB_DIR/$tname.expect"

  if [ ! -f "$exp_file" ]; then
    printf "%-25s MISSING .expect\n" "$tname"
    fail=1
    continue
  fi

  exp=$(cat "$exp_file")
  "$ROOT/B" < "$f" > "$ROOT/out.asm"
  mkdir -p "$ROOT/obj"

  # If the emitted assembly references extern symbols, this test needs
  # the bonus library to resolve them. When not requested, skip it.
  if grep -q '^extern ' "$ROOT/out.asm"; then
    if [ "${USE_BONUS_LIB:-0}" != "1" ]; then
      printf "Bonus %-20s : SKIP (requires bonus lib)\n" "$tname"
      continue
    fi
  fi
  nasm -felf32 "$ROOT/out.asm" -o "$ROOT/obj/out.o"

  if [ "${USE_BONUS_LIB:-0}" = "1" ]; then
    BONUS_LIB=${BONUS_LIB:-$ROOT/B_bonus/lib/libb.a}
    make --no-print-directory -s -C "$ROOT/B_bonus/lib"
    if [ ! -f "$BONUS_LIB" ]; then
      echo "Failed to build bonus library: $BONUS_LIB"; exit 1;
    fi
    ld -m elf_i386 "$ROOT/brt0.o" "$ROOT/obj/out.o" "$BONUS_LIB" -o "$ROOT/final" 2>/dev/null
  else
    ld -m elf_i386 "$ROOT/brt0.o" "$ROOT/obj/out.o" -o "$ROOT/final" 2>/dev/null
  fi

  # run and compare according to expectation type
  if echo "$exp" | grep -qE '^[0-9]+$'; then
    out=$("$ROOT/final")
    if [ "$out" -eq "$exp" ]; then
      printf "Bonus %-20s : result=%-20s expected=%-10s OK ✅\n" "$tname" "$out" "$exp"
    else
      printf "Bonus %-20s : result=%-20s expected=%-10s FAIL ❌\n" "$tname" "$out" "$exp"
      fail=1
    fi

  elif [ "$exp" = "IS_NUMERIC" ]; then
    out=$("$ROOT/final")
    if echo "$out" | grep -qE '^[0-9]+$' && [ "$out" -gt 0 ]; then
      printf "Bonus %-20s : result=%-20s expected=%-10s OK ✅\n" "$tname" "$out" "$exp"
    else
      printf "Bonus %-20s : result=%-20s expected=%-10s FAIL ❌\n" "$tname" "$out" "$exp"
      fail=1
    fi

  else
    out=$("$ROOT/final")
    out=$(printf "%s\n" "$out" | sed -e '$ { /^[0-9][0-9]*$/d }')
    if [ "$out" = "$exp" ]; then
      printf "Bonus %-20s : result=%-20s expected=%-10s OK ✅\n" "$tname" "(str)" "(str)"
    else
      printf "Bonus %-20s : result=(%s) expected=(%s) FAIL ❌\n" "$tname" "$out" "$exp"
      fail=1
    fi
  fi

done

if [ "$fail" != "0" ]; then
  exit 1
fi

printf "\nAll bonus tests passed.\n\n"
