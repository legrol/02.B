#!/usr/bin/env bash
set -euo pipefail

USE_BONUS_LIB=${1:-0}
BONUS_LIB="B_bonus/lib/libb.a"

echo
echo "Running tests..."

fail=0

if [ "$USE_BONUS_LIB" = "1" ]; then
  if [ ! -f "$BONUS_LIB" ]; then
    make --no-print-directory -s -C B_bonus/lib
  fi
  BONUS_LINK="$BONUS_LIB"
else
  BONUS_LINK=""
fi

mkdir -p obj

for f in tests/*.b; do
  tname=$(basename "$f" .b)
  exp_file=tests/$tname.expect
  if [ ! -f "$exp_file" ]; then
    printf "%-25s MISSING .expect\n" "$tname"
    fail=1
    continue
  fi

  ./B < "$f" > out.asm
  nasm -felf32 out.asm -o obj/out.o

  if [ -n "$BONUS_LINK" ]; then
    ld -m elf_i386 brt0.o obj/out.o "$BONUS_LINK" -o final
  else
    ld -m elf_i386 brt0.o obj/out.o -o final
  fi

  out=$(./final || true)
  exp=$(cat "$exp_file")

  if [ "$out" -eq "$exp" ]; then
    printf "Test %-20s : result=%-5s expected=%-5s OK ✅\n" "$tname" "$out" "$exp"
  else
    printf "Test %-20s : result=%-5s expected=%-5s FAIL ❌\n" "$tname" "$out" "$exp"
    fail=1
  fi
done

if [ "$fail" != "0" ]; then
  exit 1
fi

echo
echo "All tests passed."
