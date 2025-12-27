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
%}

%union {
    int   num;
    char *str;
}

%token <num> NUMBER
%token <str> STRING
%token IDENT

%token IF ELSE WHILE RETURN
%token SWITCH CASE DEFAULT
%token BREAK CONTINUE

%token EQ NE LE GE
%token ANDAND OROR
%token SHL SHR

%token PLUS STAR
%left PLUS
%left STAR

%type <num> expression term factor

%%
program
    : statement {
        printf("PARSER: program reduced\n");
      }
    ;

statement
    : assignment ';' {
        printf("PARSER: statement (assignment) reduced\n");
      }
    ;

assignment
    : IDENT '=' expression {
        printf("RESULT: %d\n", $3);
      }
    ;

expression
    : expression PLUS term {
		$$ = $1 + $3;
        printf("PARSER: expression -> expression + term\n");
      }
    | term {
		$$ = $1;
        printf("PARSER: expression -> term\n");
      }
    ;

term
    : term STAR factor {
		$$ = $1 * $3;
        printf("PARSER: term -> term * factor\n");
      }
    | factor {
		$$ = $1;
        printf("PARSER: term -> factor\n");
      }
    ;

factor
    : NUMBER {
		$$ = $1;
        printf("PARSER: factor -> NUMBER (%d)\n", $1);
      }
    | '(' expression ')' {
		$$ = $2;
        printf("PARSER: factor -> (expression)\n");
      }
    ;

%%

int yyerror(const char *s) {
    fprintf(stderr, "parse error: %s\n", s);
    return 0;
}
