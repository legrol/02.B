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
/* Lexical analyzer     */
/* Flex – lexer         */
/* ******************** */

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

/* ================================================================== */
/* helper: unescape a C-style quoted string (returns malloc'd string) */
/* ================================================================== */
static char *unescape_string(const char *s, int len)
{
	char *out = malloc(len + 1);
	if (!out) return NULL;
	int ri = 0;
	for (int i = 0; i < len; i++)
	{
		char c = s[i];
		if (c == '\\' && i + 1 < len)
		{
			i++;
			char esc = s[i];
			switch (esc) {
				case 'n': out[ri++] = '\n'; break;
				case 't': out[ri++] = '\t'; break;
				case 'r': out[ri++] = '\r'; break;
				case '\\': out[ri++] = '\\'; break;
				case '\'': out[ri++] = '\''; break;
				case '"': out[ri++] = '"'; break;
				case '0': out[ri++] = '\0'; break;
				default: out[ri++] = esc; break;
			}
		}
		else
		{
			out[ri++] = c;
		}
	}
	out[ri] = '\0';
	return out;
}
%}

/* ============================================================================ */
/* Lexer rules                                                                  */
/*                                                                              */
/* This lexer converts the input stream into tokens consumed by the Bison       */
/* parser (B.y). It recognizes identifiers, numbers, keywords, operators and    */
/* punctuation. Whitespace and comments are ignored. The lexer stores semantic  */
/* values in `yylval.str` for tokens that carry text (IDENT, NUMBER).           */
/*                                                                              */
/* The lexer intentionally returns single characters for punctuation (e.g.      */
/* '(' , ')' , ';') so the grammar can use them directly.                       */
/* ============================================================================ */

%%
[ \t\r\n]+               ;   /* whitespace */

"//"[^\n]*               ;   /* single-line comment */

\/\*([^*]|\*+[^*/])*\*\/ ;   /* multi-line comment */

"if"        { return IF; }
"else"      { return ELSE; }
"then"      { return THEN; }
"function"  { return FUNCTION; }
"endfunction" { return ENDFUNCTION; }
"return"    { return RETURN; }
"extrn"     { return EXTRN; }

[A-Za-z_][A-Za-z0-9_]* {
	yylval.str = strdup(yytext);
    return IDENT;
}

[0-9]+ { 
	yylval.str = strdup(yytext);
	return NUMBER;
}

\"([^\\\"\n]|\\.)*\" {
	/* string literal with C-style escapes */
	int L = yyleng - 2; /* drop quotes */
	char *raw = malloc(L + 1);
	if (!raw) raw = "";
	if (L > 0)
		memcpy(raw, yytext + 1, L);
	raw[L] = '\0';
	char *un = unescape_string(raw, L);
	free(raw);
	yylval.str = un;
	return STRING;
}

\'([^\\'\n]|\\.)\' {
	/* char literal (single character, possibly escaped) */
	int L = yyleng - 2;
	char buf[4] = {0};
	if (L > 0)
		memcpy(buf, yytext + 1, L);
	char *un = unescape_string(buf, L);
	/* convert to decimal string to reuse existing NUMBER handling */
	char tmp[16];
	unsigned char v = (unsigned char)un[0];
	snprintf(tmp, sizeof(tmp), "%u", (unsigned)v);
	yylval.str = strdup(tmp);
	free(un);
	return NUMBER; /* reuse NUMBER token carrying string numeric */
}

"+" 	 { return PLUS; }
"*" 	 { return STAR; }
"="    	 { return '='; }
";"      { return ';'; }
"("      { return '('; }
")"      { return ')'; }

. { return yytext[0]; }

<<EOF>> {	
	return 0;
}
%%

int yywrap(void)
{
    return 1;
}
