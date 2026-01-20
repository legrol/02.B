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

/* ************************************************** */
/* helper structures for switch/case capture handling */
/* ************************************************** */
struct case_node {
  char *lbl;
  char *body;               /* captured body (malloc'd) */
  struct case_node *next;
  char *value;              /* numeric literal as string */
};

struct switch_holder {
  struct case_node *head;
  struct case_node *tail;
  char *default_lbl;
  char *default_body;       /* malloc'd body */
  char *end_lbl;
  char *last_temp_lbl;
};

static struct switch_holder *current_switch = NULL;

%}

%union { 
  char *str; 
  void *ptr;
}

%debug

%token <str> IDENT NUMBER STRING FLOAT
%token EXTRN
%token IF ELSE THEN FUNCTION ENDFUNCTION RETURN
%token SWITCH CASE DEFAULT BREAK GOTO
%token PLUS STAR MINUS DIV

%token INTKW

 

%left PLUS MINUS
%left STAR DIV
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

case_list
    : /* empty */
    | case_list case_entry
    ;

/* ********************************************************************** */
/* Floating-point expressions (x87)                                        */
/* fexpr: floating expression producing a value on the x87 register stack  */
/* ffactor: float literal or parenthesized float expression                */
/* ********************************************************************** */
fexpr
    : fterm
    | fexpr PLUS fterm
      {
        emit("\tfaddp\n");
      }
    | fexpr MINUS fterm
      {
        emit("\tfsubp\n");
      }
    ;

fterm
    : ffactor
    | fterm STAR ffactor
      {
        emit("\tfmulp\n");
      }
    | fterm DIV ffactor
      {
        emit("\tfdivp\n");
      }
    ;

ffactor
    : FLOAT
      {
        const char *lbl = intern_float($1);
        emit("\tfld qword [%s]\n", lbl);
        free($1);
      }
    | NUMBER
      {
        /* ************************************************************** */
        /* convert integer literal to float via temporary dword then fild */
        /* ************************************************************** */
        declare_var("__flt_tmp");
        emit("\tmov dword [__flt_tmp], %s\n", $1);
        emit("\tfild dword [__flt_tmp]\n");
      }
    | IDENT
      {
        /* **************************************************************** */
        /* if IDENT is a variable, load it as integer then convert to float */
        /* **************************************************************** */
        if (get_symbol_type($1) == SYM_VAR)
        {
            emit("\tfild dword [%s]\n", $1);
        }
        else
        {
            fprintf(stderr, "semantic error: cannot use label '%s' as numeric\n", $1);
            exit(1);
        }
      }
    | '(' fexpr ')'
      { /* nothing: fexpr already emitted code that leaves value on x87 */ }
    ;


case_entry
    : CASE NUMBER ':'
      {
        /* *************************************************** */
        /* create label for this case and emit comparison jump */
        /* *************************************************** */
        char *lbl = new_label();
        emit("\tcmp eax, %s\n", $2);
        emit("\tje %s\n", lbl);
        /* ********************************************************** */
        /* store label temporarily in the switch holder for later use */
        /* ********************************************************** */
        if (current_switch)
        {
          current_switch->last_temp_lbl = strdup(lbl);
        }
        /* ************************************************** */
        /* capture the body emitted by following `statements` */
        /* ************************************************** */
        emit_begin_capture();
        emit("%s:\n", current_switch ? current_switch->last_temp_lbl : lbl);
        free(lbl);
      }
      statements
      {
        /* ***************************** */
        /* finish capture and store node */
        /* ***************************** */
        char *body = emit_end_capture();
        struct case_node *n = malloc(sizeof(*n));
        if (!n) { fprintf(stderr, "out of memory\n"); exit(1); }
        /* *************************************** */
        /* copy the temporary label stored earlier */
        /* *************************************** */
        n->lbl = current_switch && current_switch->last_temp_lbl ? strdup(current_switch->last_temp_lbl) : strdup(".");
        if (current_switch && current_switch->last_temp_lbl) { free(current_switch->last_temp_lbl); current_switch->last_temp_lbl = NULL; }
        /* **************************************************************** */
        /* The captured body contains the label at the start; keep it as-is */
        /* **************************************************************** */
        n->body = body;
        n->value = strdup($2);
        n->next = NULL;
        if (!current_switch->head) current_switch->head = current_switch->tail = n;
        else { current_switch->tail->next = n; current_switch->tail = n; }
      }
    | DEFAULT ':'
      {
        /* ******************** */
        /* capture default body */
        /* ******************** */
        char *lbl = new_label();
        current_switch->default_lbl = strdup(lbl);
        emit_begin_capture();
        emit("%s:\n", lbl);
        free(lbl);
      }
      statements
      {
        char *body = emit_end_capture();
        current_switch->default_body = body;
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
  | GOTO IDENT ';'
    {
      /* ************************************ */
      /* jump to label (declare if necessary) */
      /* ************************************ */
      declare_label($2);
      emit("\tjmp %s\n", $2);
    }
  | BREAK ';'
    {
      /* ********************************************************** */
      /* break: jump to the nearest enclosing switch/loop end label */
      /* ********************************************************** */
      char *l_end = peek_label();
      if (!l_end)
      {
        fprintf(stderr, "semantic error: 'break' not inside a switch/loop\n");
        exit(1);
      }
      emit("\tjmp %s\n", l_end);
    }
  | SWITCH '(' expression ')' '{' 
      {
        /* ************************************************ */
        /* start a new switch holder and push its end label */
        /* ************************************************ */
        current_switch = malloc(sizeof(*current_switch));
        if (!current_switch) { fprintf(stderr, "out of memory\n"); exit(1); }
        current_switch->head = current_switch->tail = NULL;
        current_switch->default_lbl = NULL;
        current_switch->default_body = NULL;
        current_switch->end_lbl = new_label();
        push_label(current_switch->end_lbl);
      }
      case_list '}'
      {
        /* ********************************************************* */
        /* after parsing cases: emit fallback jump to default or end */
        /* ********************************************************* */
        if (current_switch->default_lbl)
        {
          emit("\tjmp %s\n", current_switch->default_lbl);
        }
        else
        {
          emit("\tjmp %s\n", current_switch->end_lbl);
        }
        /* ********************************* */
        /* emit the captured bodies in order */
        /* ********************************* */
        struct case_node *it = current_switch->head;
        while (it)
        {
          emit("%s", it->body);
          struct case_node *tmp = it;
          it = it->next;
          free(tmp->body);
          free(tmp->lbl);
          free(tmp->value);
          free(tmp);
        }
        /* ************ */
        /* default body */
        /* ************ */
        if (current_switch->default_body)
        {
          emit("%s", current_switch->default_body);
          free(current_switch->default_body);
          free(current_switch->default_lbl);
        }
        /* *************************** */
        /* emit end label and clean up */
        /* *************************** */
        emit("%s:\n", current_switch->end_lbl);
        pop_label();
        free(current_switch->end_lbl);
        free(current_switch);
        current_switch = NULL;
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
    | expression MINUS
      {
        emit("\tpush eax\n");
      } term
      {
        emit("\tpop ebx\n");
        /* ***************************************************************** */
        /* compute (left - right): left was pushed into ebx, right is in eax */
        /* ***************************************************************** */
        emit("\tsub ebx, eax\n");
        emit("\tmov eax, ebx\n");
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
    | term DIV
      {
        emit("\tpush eax\n");
      } factor
      {
        emit("\tpop ebx\n");
        /* ******************************************************** */
        /* perform signed division: ebx (left) / eax (right) -> eax */
        /* ******************************************************** */
        emit("\tmov ecx, eax\n");
        emit("\tmov eax, ebx\n");
        emit("\tcdq\n");
        emit("\tidiv ecx\n");
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
        /* ************************************** */
        /* zero-argument call (existing behavior) */
        /* ************************************** */
        if (get_symbol_type($1) == SYM_VAR || get_symbol_type($1) == SYM_FUNC)
        {
          emit("\tmov eax, dword [%s]\n", $1);
          emit("\tcall eax\n");
        }
        else
        {
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
    | '(' INTKW ')' fexpr
      {
        /* ************************************************************************** */
        /* cast float -> int: pop float into integer memory via FPU and load into eax */
        /* ************************************************************************** */
        declare_var("__flt_tmp");
        /* *********************************************************** */
        /* set FPU rounding mode to truncate (round toward zero) by
          saving control word, modifying RC bits, loading modified CW,
          performing fistp, then restoring old CW                      */
        /* *********************************************************** */
        emit("\tsub esp, 4\n");
        emit("\tfnstcw word [esp]\n");
        emit("\tmov ax, word [esp]\n");
        emit("\tand ax, 0xF3FF\n");
        emit("\tor ax, 0x0C00\n");
        emit("\tmov word [esp+2], ax\n");
        emit("\tfldcw word [esp+2]\n");
        emit("\tfistp dword [__flt_tmp]\n");
        emit("\tfldcw word [esp]\n");
        emit("\tadd esp, 4\n");
        emit("\tmov eax, dword [__flt_tmp]\n");
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
