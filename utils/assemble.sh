#!/usr/bin/env bash
set -euo pipefail

# Colors (disabled if NO_COLOR is set)
if [[ -n "${NO_COLOR:-}" ]]; then
  RED=""; GREEN=""; YELLOW=""; CYAN=""; RESET=""
else
  RED="\033[0;91m"; GREEN="\033[0;92m"; YELLOW="\033[0;93m"; CYAN="\033[0;96m"; RESET="\033[0m"
fi

# Usage: assemble.sh <input.b> <backend:nasm|gas> <use_bonus_lib:0|1>
INPUT=${1:-tests/test_add.b}
BACKEND=${2:-nasm}
USE_BONUS_LIB=${3:-0}
BONUS_LIB=B_bonus/lib/libb.a

echo
echo -e "${CYAN}Assembling (backend=${BACKEND})...${RESET}"

if [ ! -f brt0.o ]; then
  echo -e "${YELLOW}brt0.o missing; building it with make...${RESET}"
  make --no-print-directory -s brt0.o
fi

if [ "$USE_BONUS_LIB" = "1" ]; then
  # Always (re)build the bonus library to ensure symbols are present
  make --no-print-directory -s -C B_bonus/lib
  if [ ! -f "$BONUS_LIB" ]; then
    echo -e "${RED}Failed to build bonus library: $BONUS_LIB${RESET}" >&2
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
  echo -e "${GREEN}Built final using as+ld${RESET}"
elif [ "$BACKEND" = "nasm" ]; then
  ./B < "$INPUT" > out.asm
  mkdir -p obj
  nasm -felf32 out.asm -o obj/out.o
  if [ -n "$BONUS_LINK" ]; then
    ld -m elf_i386 obj/out.o brt0.o "$BONUS_LINK" -o final 2>/dev/null
  else
    ld -m elf_i386 obj/out.o brt0.o -o final 2>/dev/null
  fi
  echo -e "${GREEN}Built final using nasm+ld${RESET}"
else
  echo -e "${RED}Unknown BACKEND='${BACKEND}'. Use 'gas' or 'nasm'${RESET}" >&2
  exit 1
fi
