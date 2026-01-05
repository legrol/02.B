/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   B.h                                                :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: rdel-olm <rdel-olm@student.42malaga.com>   +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2025/12/26 22:52:08 by rdel-olm          #+#    #+#             */
/*   Updated: 2026/01/05 23:51:26 by rdel-olm         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#ifndef B_H
# define B_H

// ============================================================================
// Libraries
// ============================================================================
# include <stdio.h>
# include <stdlib.h>
# include <string.h>
# include <stdarg.h>
# include <unistd.h>
# include <sys/types.h>
# include <stdint.h>
# include <time.h>

// ============================================================================
// Access to my libraries
// ============================================================================
# include "colors.h"

// ============================================================================
// Mandatory functions
// Flex/Bison runtime declarations 		
// ============================================================================
int yyparse(void);
int yylex(void);
int yyerror(const char *s);

// ============================================================================
// Symbol table
// ============================================================================
typedef enum {
	SYM_LABEL = 0,
	SYM_VAR,
	SYM_STR,
	SYM_FLOAT,
	SYM_FUNC
} sym_type_t;

void declare_label(const char *name);
void declare_var(const char *name);
void declare_func(const char *name, const char *code_label);
void set_function_body(const char *name, const char *body);
void emit_function_bodies(void);
sym_type_t get_symbol_type(const char *name);
int get_symbol_offset(const char *name);
int get_symbol_stack_size(void);
void emit_symbols(void);
void emit_externs(void);

// ============================================================================
// intern a literal string and return the generated data label name
// ============================================================================
const char *intern_string(const char *s);

// ============================================================================
// Bonus functions
// ============================================================================
const char *intern_float(const char *s);

/* ********************************************************************/
/* Bonus library functions provided in B_bonus/lib/libb.a
 * Declare prototypes here so the compiler sources can reference them
 * if needed. These are also useful as documentation for students.
 */
/* ****************************************************************** */
int get_ten(void);
int b_print(void);
int b_time(void);
int b_ipow(void);

#endif