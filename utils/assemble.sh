#!/usr/bin/env bash
set -euo pipefail

# Usage: assemble.sh <input.b> <backend:nasm|gas> <use_bonus_lib:0|1>
INPUT=${1:-tests/test_add.b}
BACKEND=${2:-nasm}
USE_BONUS_LIB=${3:-0}
BONUS_LIB=B_bonus/lib/libb.a

echo
echo "Assembling (backend=${BACKEND})..."

if [ "$USE_BONUS_LIB" = "1" ]; then
  # Always (re)build the bonus library to ensure symbols are present
  make --no-print-directory -s -C B_bonus/lib
  if [ ! -f "$BONUS_LIB" ]; then
    echo "Failed to build bonus library: $BONUS_LIB" >&2
    exit 1
  fi
  BONUS_LINK="$BONUS_LIB"
else
  BONUS_LINK=""
fi

if [ "$BACKEND" = "gas" ]; then
  ./B < "$INPUT" > out.asm
  mkdir -p obj
  as --32 out.asm -o obj/out.o
  if [ -n "$BONUS_LINK" ]; then
    ld -m elf_i386 obj/out.o brt0.o "$BONUS_LINK" -o final 2>/dev/null
  else
    ld -m elf_i386 obj/out.o brt0.o -o final 2>/dev/null
  fi
  echo "Built final using as+ld"
elif [ "$BACKEND" = "nasm" ]; then
  ./B < "$INPUT" > out.asm
  mkdir -p obj
  nasm -felf32 out.asm -o obj/out.o
  if [ -n "$BONUS_LINK" ]; then
    ld -m elf_i386 obj/out.o brt0.o "$BONUS_LINK" -o final 2>/dev/null
  else
    ld -m elf_i386 obj/out.o brt0.o -o final 2>/dev/null
  fi
  echo "Built final using nasm+ld"
else
  echo "Unknown BACKEND='${BACKEND}'. Use 'gas' or 'nasm'" >&2
  exit 1
fi
