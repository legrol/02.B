/* *************************************************************************** */
/*                                                                             */
/*                                                        :::      ::::::::    */
/*    B.y                                                :+:      :+:    :+:   */
/*                                                     +:+ +:+         +:+     */
/*    By: rdel-olm <rdel-olm@student.42malaga.com>   +#+  +:+       +#+        */
/*                                                 +#+#+#+#+#+   +#+           */
/*    Created: 2025/12/26 22:54:03 by rdel-olm          #+#    #+#             */
/*    Updated: 2026/01/01 23:00:00 by rdel-olm         ###   ########.fr       */
/*                                                                             */
/* *************************************************************************** */

/* ******************** */
/* Syntax analyzer      */
/* Bison – parser       */
/* ******************** */

/*
===============================================================================
B.y — Syntax Analyzer (Bison)

This file defines the grammar and semantic actions for the B language using
Bison. Semantic actions perform syntax-directed translation and emit NASM
assembly directly via the emission helpers (no AST is used).

Main responsibilities:
    - Define the grammar of the B language (with the allowed extensions).
    - Perform syntax-directed translation: semantic actions emit assembly text.
    - Manage labels and symbol declarations via helper functions in
      `src/symbols.c` and `src/emit.c`.
    - Support function capture/re-emission so function bodies are emitted after
      `prog_main` (functions are represented as pointers in `.data`).

Implementation notes:
    - The parser uses `%union` to pass string values (identifiers, numbers,
      strings) through `yylval`.
    - The lexer (`B.l`) returns tokens declared here.
    - Semantic actions intentionally emit NASM (Intel) assembly directly.
    - No AST is created; all translation is syntax-directed in the actions.

===============================================================================
*/

%{
#include "../includes/B.h"
#include "../includes/emit.h"
%}

%union { 
  char *str; 
}

%debug

%token <str> IDENT NUMBER STRING
%token EXTRN
%token IF ELSE THEN FUNCTION ENDFUNCTION RETURN
%token PLUS STAR

%left PLUS
%left STAR
%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%
program
    : statements
    ;

statements
    : /* empty */
    | statements statement
    ;

/* ******************************************************* */
/* headers and helpers to avoid anonymous mid-rule actions */
/* ******************************************************* */
header_with_else
    : /* empty */
      {
        char *l_else = new_label();
        char *l_end  = new_label();
        emit("\ttest eax, eax\n");
        emit("\tjz %s\n", l_else);
        push_label(l_end);
        push_label(l_else);
      }
    ;

header_noelse
    : /* empty */
      {
        char *l_end = new_label();
        emit("\ttest eax, eax\n");
        emit("\tjz %s\n", l_end);
        push_label(l_end);
      }
    ;

after_then
    : /* empty */
      {
        /* ************************************************* */
        /* emit jump to end and else label after then-branch */
        /* ************************************************* */
        char *l_else = pop_label();
        char *l_end = peek_label();
        emit("\tjmp %s\n", l_end);
        emit("%s:\n", l_else);
      }
    ;

/* ************************************************************************ */
/* Simplified: require THEN to be followed by a single assignment statement
   (assignment ';') to avoid ambiguity in LALR(1) parsing. This keeps syntax
   minimally invasive and fixes the dangling-else for common tests.         */
/* ************************************************************************ */
if_header
    : /* empty */
      {
        char *l_else = new_label();
        char *l_end  = new_label();
        emit("\ttest eax, eax\n");
        emit("\tjz %s\n", l_else);
        push_label(l_end);
        push_label(l_else);
      }
    ;

statement
  : assignment ';'
  | RETURN expression ';'
  | IDENT ':'
    {
      /* *********************************************** */
      /* label definition: record and emit label in text */
      /* *********************************************** */
      declare_label($1);
      emit("%s:\n", $1);
    }
  | IF '(' expression ')' THEN if_header assignment ';' after_then ELSE assignment ';'
    {
      char *l_end = pop_label();
      emit("%s:\n", l_end);
    }
  | IF '(' expression ')' THEN if_header assignment ';'
    {
      char *l_end = pop_label();
      emit("%s:\n", l_end);
    }
  | function_def
  | EXTRN IDENT ';'
    {
      /* *********************************** */
      /* declare external code label (extrn) */
      /* *********************************** */
      declare_label($2);
    }
  ;

function_def
  : FUNCTION IDENT
    {
      /* **************************************************************** */
      /* declare symbol as function and reserve a code label for the body */
      /* **************************************************************** */
      char *lbl = new_label();
      char *code_lbl = lbl[0] == '.' ? lbl + 1 : lbl;
      declare_func($2, code_lbl);
      /* **************************************************************** */
      /* begin capturing the emitted code for the function body so it
         can be emitted after prog_main to avoid placing the body at
         the start of prog_main.                                          */
      /* **************************************************************** */
      emit_begin_capture();
      emit("%s:\n", code_lbl);
      emit("\tpush ebp\n\tmov ebp, esp\n");
    }
    statements ENDFUNCTION
    {
      emit("\tmov esp, ebp\n\tpop ebp\n\tret\n");
      {
        char *body = emit_end_capture();
        if (body)
        {
          set_function_body($2, body);
          free(body);
        }
      }
    }
  ;

assignment
    : IDENT '=' expression
      {
        /* ******************************************************* */
        /* assignments declare variables (storage in .data)        */
        /* ******************************************************* */
        declare_var($1);
        emit("\tmov dword [%s], eax\n", $1);
      }
    ;

expression
    : term
    | expression PLUS
      {
        emit("\tpush eax\n");
      } term
      {
        emit("\tpop ebx\n");
        emit("\tadd eax, ebx\n");
      }
    ;

term
    : factor
    | term STAR
      {
        emit("\tpush eax\n");
      } factor
      {
        emit("\tpop ebx\n");
        emit("\timul eax, ebx\n");
      }
    ;

factor
    : NUMBER
      {
        emit("\tmov eax, %s\n", $1);
      }
    | STRING
      {
        /* ******************************************************* */
        /* string literal: intern and return its address in eax    */
        /* ******************************************************* */
        const char *lbl = intern_string($1);
        emit("\tmov eax, %s\n", lbl);
        free($1);
      }
    | IDENT '(' ')'
      {
      /* ***************************************************************** */
      /* Calls: two modes
         - if IDENT is a variable: load dword [IDENT] and call via pointer
         - otherwise (label/extern/function): emit direct call to label    */
      /* ***************************************************************** */
      if (get_symbol_type($1) == SYM_VAR || get_symbol_type($1) == SYM_FUNC)
      {
        emit("\tmov eax, dword [%s]\n", $1);
        emit("\tcall eax\n");
      }
      else
      {
        /* ************************** */
        /* direct call to code symbol */
        /* ************************** */
        declare_label($1);
        emit("\tcall %s\n", $1);
      }
      }
    | IDENT '[' expression ']'
      {
        /* ************************************************************* */
        /* array indexing: for i386 byte addressing, scale index by 4
           Use the address (label) of the identifier as the base; do not
           dereference the variable slot — indexing operates on memory
           laid out starting at the symbol's address.                    */
        /* ************************************************************* */
        if (get_symbol_type($1) == SYM_FUNC)
        {
            fprintf(stderr, "semantic error: cannot index function '%s'\n", $1);
            exit(1);
        }
        /* ************************************************************* */
        /* ensure symbol exists and load its address into ebx.
           If it's a variable we must NOT call declare_label (that would
           error due to namespace exclusivity). For undeclared names the
           default is treated as label, so declare it.                   */
        /* ************************************************************* */
        if (get_symbol_type($1) == SYM_VAR)
        {
          /* ******************************************** */
          /* variable holds a pointer (dword) to the base */
          /* ******************************************** */
          emit("\tmov ebx, dword [%s]\n", $1);
        }
        else
        {
          /* ******************************* */
          /* label/address: take its address */
          /* ******************************* */
          declare_label($1);
          emit("\tmov ebx, %s\n", $1);
        }
        /* ************************************************* */
        /* index is in eax; multiply by 4 (4 bytes per word) */
        /* ************************************************* */
        emit("\tshl eax, 2\n");
        emit("\tadd ebx, eax\n");
        emit("\tmov eax, dword [ebx]\n");
      }
    | IDENT
      {
        /* *************************************************************** */
        /* per subject: undeclared references are labels; load differently
           If the symbol is a variable, load its contents; if it's a label,
           load the label address into eax.                                */
        /* *************************************************************** */
        if (get_symbol_type($1) == SYM_VAR)
        {
            emit("\tmov eax, dword [%s]\n", $1);
        }
        else
        {
            /* **************************************** */
            /* ensure label is declared in symbol table */
            /* **************************************** */
            declare_label($1);
            emit("\tmov eax, %s\n", $1);
        }
      }
    | '&' IDENT
      {
        /* *************************************************************** */
        /* address-of operator: load the address of IDENT into eax. Do not
           call declare_label on existing variables (would raise semantic
           collision); for undeclared names, declare them as labels.       */
        /* *************************************************************** */
        if (get_symbol_type($2) == SYM_VAR)
        {
            emit("\tmov eax, %s\n", $2);
        }
        else
        {
            declare_label($2);
            emit("\tmov eax, %s\n", $2);
        }
      }
    | '!' factor
      {
        /* ***************************************** */
        /* logical NOT: set eax = (eax == 0) ? 1 : 0 */
        /* ***************************************** */
        emit("\ttest eax, eax\n");
        emit("\tsete al\n");
        emit("\tmovzx eax, al\n");
      }
    | '(' expression ')'
    ;

/* ******************************************************************* */
/* Helper empty productions to implement if/else code emission without
   using mid-rule actions that break the dangling-else resolution.     */
/* matched/unmatched folded into `statement` above                     */
/* ******************************************************************* */
%%

int yyerror(const char *s)
{
  if (s && *s)
  {
    fprintf(stderr, "%s\n", s);
  }
  else
  {
    fprintf(stderr, "syntax error\n");
  }
  return 1;
}
