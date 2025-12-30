/* *************************************************************************** */
/*                                                                             */
/*                                                        :::      ::::::::    */
/*    B.y                                                :+:      :+:    :+:   */
/*                                                     +:+ +:+         +:+     */
/*    By: rdel-olm <rdel-olm@student.42malaga.com>   +#+  +:+       +#+        */
/*                                                 +#+#+#+#+#+   +#+           */
/*    Created: 2025/12/26 22:54:04 by rdel-olm          #+#    #+#             */
/*    Updated: 2025/12/27 00:01:42 by rdel-olm         ###   ########.fr       */
/*                                                                             */
/* *************************************************************************** */

/* ******************** */
/* Syntax analyzer		*/
/* Bison – parser		*/
/* ********************	*/

/*
===============================================================================
B.y — Syntax Analyzer (Bison)

This file defines the syntax analyzer (parser) of the language using Bison.
Its responsibility is to validate the grammatical structure of the program
based on a context-free grammar and the tokens produced by the lexer (B.l).

Main responsibilities:
	- Define the grammar rules of the language.
	- Specify how tokens can be combined to form valid statements and expressions.
	- Associate semantic values with grammar symbols using a union.
	- Detect and report syntax errors.

How it works:
	- The parser receives tokens from the lexer via yylex().
	- Grammar rules describe valid sequences of tokens.
	- If the input follows the grammar, parsing succeeds.
	- If the input violates the grammar, yyerror() is called.

Key components:
	- %union defines the possible semantic value types (integers and strings).
	- %token declarations define terminal symbols and their associated types.
	- Grammar rules (program, statement, assignment, expression) describe
		the structure of valid input.
	- The current grammar supports simple assignments and arithmetic expressions.
	- Operators like '+' and '=' are treated as literal characters.
	- The grammar is minimal and intended as a foundation for future extensions.

Error handling:
	- yyerror() prints a human-readable syntax error message.
	- The parser stops or recovers according to Bison’s default behavior.

This parser does not execute code or evaluate expressions.
Its role is strictly syntactic validation and structural analysis.

===============================================================================
*/

%{
#include "../includes/B.h"
#include "../includes/emit.h"
%}

%union {
    char *str;
}

%token <str> IDENT NUMBER
%token IF ELSE
%token PLUS STAR

%left PLUS
%left STAR
%nonassoc IFX
%nonassoc ELSE

%%
program
    : statements
    ;

statements
    : /* empty */
    | statements statement
    ;

statement
    : assignment ';'
    | if_statement
    ;

assignment
    : IDENT '=' expression {
        declare_symbol($1);
        emit("\tmov [%s], eax\n", $1);
      }
    ;

expression
    : term
    | expression PLUS term {
        emit("\tpop ebx\n");
        emit("\tadd eax, ebx\n");
      }
    ;

term
    : factor
    | term STAR factor {
        emit("\tpop ebx\n");
        emit("\timul eax, ebx\n");
      }
    ;

factor
    : NUMBER {
        emit("\tmov eax, %s\n", $1);
      }
    | IDENT {
        emit("\tmov eax, [%s]\n", $1);
      }
    | '(' expression ')'
    ;

if_statement
    : IF '(' expression ')' statement %prec IFX
    | IF '(' expression ')' statement ELSE statement
    ;
%%

int yyerror(const char *s)
{
    (void)s;
    return 0;
}
