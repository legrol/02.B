/* *************************************************************************** */
/*                                                                             */
/*                                                        :::      ::::::::    */
/*    B.l                                                :+:      :+:    :+:   */
/*                                                     +:+ +:+         +:+     */
/*    By: rdel-olm <rdel-olm@student.42malaga.com>   +#+  +:+       +#+        */
/*                                                 +#+#+#+#+#+   +#+           */
/*    Created: 2025/12/26 22:54:03 by rdel-olm          #+#    #+#             */
/*    Updated: 2025/12/27 00:00:59 by rdel-olm         ###   ########.fr       */
/*                                                                             */
/* *************************************************************************** */

/* ******************** */
/* Lexical analyzer		*/
/* Flex – lexer			*/
/* ********************	*/

/*
===============================================================================
B.l — Lexical Analyzer (Flex)

This file defines the lexical analyzer of the language using Flex.
Its responsibility is to read the raw input character stream and convert it
into a sequence of tokens that will be consumed by the Bison parser (B.y).

Main responsibilities:
	- Ignore irrelevant input such as whitespace and comments.
	- Recognize identifiers, keywords, literals, operators, and symbols.
	- Return the correct token type to the parser.
	- Attach semantic values (yylval) when needed (e.g., numbers and strings).

How it works:
	- Flex scans the input from left to right using regular expressions.
	- Each rule matches a pattern and executes an associated C action.
	- When a token is recognized, the lexer returns a token defined in parser.tab.h.
	- Keywords are detected by comparing identifier text against reserved words.
	- Operators and symbols are returned directly as token constants or characters.

Important implementation details:
	- %option noinput nounput disables unused Flex helper functions to avoid
		compiler warnings under -Wall -Wextra -Werror.
	- parser.tab.h is included to make token definitions visible to the lexer.
	- B.h provides shared declarations used across the project.
	- String literals allocate memory dynamically and store their value in yylval.
	- Comments (single-line and multi-line) are fully ignored by the lexer.
	- Any single unmatched character is returned as-is to the parser.

This lexer does not perform syntax validation.
Its only job is tokenization; grammar rules and structure are handled by Bison.

===============================================================================
*/

%option noinput nounput

%{
/* ========================================================================= */
/* Includes                                                                  */
/* ========================================================================= */
#include "parser.tab.h"
#include "../includes/B.h"
%}

/* ========================================================================= */
/* Lexer rules                                                               */
/* ========================================================================= */
%%
[ \t\r\n]+               ;   /* whitespace */

"//"[^\n]*               ;   /* single-line comment */

\/\*([^*]|\*+[^*/])*\*\/ ;   /* multi-line comment */

[A-Za-z_][A-Za-z0-9_]* {
	printf("LEX: IDENTIFIER or KEYWORD -> \"%s\"\n", yytext);

    if (strcmp(yytext, "if") == 0)       return IF;
    if (strcmp(yytext, "else") == 0)     return ELSE;
    if (strcmp(yytext, "while") == 0)    return WHILE;
    if (strcmp(yytext, "return") == 0)   return RETURN;
    if (strcmp(yytext, "switch") == 0)   return SWITCH;
    if (strcmp(yytext, "case") == 0)     return CASE;
    if (strcmp(yytext, "default") == 0)  return DEFAULT;
    if (strcmp(yytext, "break") == 0)    return BREAK;
    if (strcmp(yytext, "continue") == 0) return CONTINUE;
    return IDENT;
}

[0-9]+ { 
	printf("LEX: NUMBER -> \"%s\"\n", yytext);
	yylval.num = atoi(yytext);
	return NUMBER;
}

\"([^\"\\]|\\.)*\" { 
	printf("LEX: STRING -> \"%s\"\n", yytext);
	yylval.str = strdup(yytext); 
	return STRING; 
}

"=="     { printf("LEX: EQ\n"); return EQ; }
"!="     { printf("LEX: NE\n"); return NE; }
"<="     { printf("LEX: LE\n"); return LE; }
">="     { printf("LEX: GE\n"); return GE; }
"&&"     { printf("LEX: ANDAND\n"); return ANDAND; }
"||"     { printf("LEX: OROR\n"); return OROR; }
"<<"     { printf("LEX: SHL\n"); return SHL; }
">>"     { printf("LEX: SHR\n"); return SHR; }
"+" 	 { printf("LEX: PLUS\n"); return PLUS; }
"*" 	 { printf("LEX: STAR\n"); return STAR; }

. { 
	printf("LEX: CHAR -> '%c'\n", yytext[0]);
	return yytext[0];
}

<<EOF>> {
	printf("LEX: EOF\n");
	return 0;
}
%%

int yywrap(void)
{
    return 1;
}
