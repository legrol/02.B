#!/usr/bin/env bash
set -euo pipefail

# compile_nasm.sh — replicate the evaluator's compile() but use nasm
# Usage: ./compile_nasm.sh file1.b file2.b ...

if [ $# -eq 0 ]; then
  echo "Usage: $0 file1.b [file2.b ...]" >&2
  exit 2
fi

if [ ! -f brt0.o ]; then
  echo "brt0.o missing; building it with make..."
  make --no-print-directory -s brt0.o
fi

# If only one input, produce `final`. If multiple, produce one executable per input
if [ $# -eq 1 ]; then
  f="$1"
  S=$(mktemp)
  O=$(mktemp)
  ./B <"$f" >"$S"
  nasm -felf32 "$S" -o "$O"
  rm -f "$S"
  ld -m elf_i386 "$O" brt0.o -o final
  rm -f "$O"
  echo "Linked final"
else
  for f in "$@"; do
    base=$((basename "$f") 2>/dev/null || true)
    # fallback basename if above fails in sh
    if [ -z "$base" ]; then base=$(basename "$f"); fi
    out="final_$(basename "$f" .b)"
    S=$(mktemp)
    O=$(mktemp)
    ./B <"$f" >"$S"
    nasm -felf32 "$S" -o "$O"
    rm -f "$S"
    ld -m elf_i386 "$O" brt0.o -o "$out"
    rm -f "$O"
    echo "Linked $out"
  done
fi
