/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   symbols.c                                          :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: rdel-olm <rdel-olm@student.42malaga.com>   +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2025/12/28 16:19:24 by rdel-olm          #+#    #+#             */
/*   Updated: 2026/01/05 23:29:07 by rdel-olm         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "../includes/B.h"

/* ************************************************************************** */
/*
 * symbols.c — symbol table and string interning
 *
 * Responsibilities:
 *  - Maintain a compact symbol table for labels, variables, functions and
 *    interned string literals.
 *  - Provide declaration helpers used by the parser:
 *      - declare_label, declare_var, declare_func
 *  - Intern string literals so identical strings share a single label in
 *    the `.data` section (intern_string).
 *  - Store captured function bodies (set_function_body) for deferred
 *    emission (emit_function_bodies).
 *  - Enforce simple collision checks between labels/vars/funcs and report
 *    semantic errors via stderr (this project is focused on code-golfing,
 *    so diagnostics are minimal but deterministic).
 *
 * Design notes:
 *  - Undeclared references default to `SYM_LABEL` per the assignment.
 *  - Functions are represented as data slots containing the address of the
 *    function code label (so calling a function is implemented as a pointer
 *    call in generated assembly).
 */
/* ************************************************************************** */


typedef struct {
    char *name;
    sym_type_t type;
    char *code_label; /* for functions: label of the code body */
    char *code_body;  /* captured code emitted for the function body */
    char *data;       /* for string literals: raw data */
} symbol_t;

static symbol_t symbols[512];
static int count = 0;

static int find_symbol(const char *name)
{
    for (int i = 0; i < count; i++)
        if (!strcmp(symbols[i].name, name))
            return i;
    return -1;
}

void declare_label(const char *name)
{
    int idx = find_symbol(name);
    if (idx >= 0)
    {
        if (symbols[idx].type == SYM_VAR)
        {
            fprintf(stderr, "semantic error: symbol '%s' already declared as variable\n", name);
            exit(1);
        }
        return;
    }
    symbols[count].name = strdup(name);
    symbols[count].type = SYM_LABEL;
    count++;
}

void declare_var(const char *name)
{
    int idx = find_symbol(name);
    if (idx >= 0)
    {
        if (symbols[idx].type == SYM_LABEL)
        {
            fprintf(stderr, "semantic error: symbol '%s' already declared as label\n", name);
            exit(1);
        }
        return;
    }
    symbols[count].name = strdup(name);
    symbols[count].type = SYM_VAR;
    count++;
}

void declare_func(const char *name, const char *code_label)
{
    int idx = find_symbol(name);
    if (idx >= 0)
    {
        if (symbols[idx].type == SYM_VAR)
        {
            fprintf(stderr, "semantic error: symbol '%s' already declared as variable\n", name);
            exit(1);
        }
        if (symbols[idx].type == SYM_FUNC)
            return;
        /* **************************************************************** */
		/* if previously label, upgrade to func */
		/* **************************************************************** */
        symbols[idx].type = SYM_FUNC;
        symbols[idx].code_label = strdup(code_label);
        return;
    }
    symbols[count].name = strdup(name);
    symbols[count].type = SYM_FUNC;
    symbols[count].code_label = strdup(code_label);
    symbols[count].code_body = NULL;
    count++;
}

const char *intern_string(const char *s)
{
    /**************************************************** */
	/* check for existing identical string -> reuse label */
	/**************************************************** */
    for (int i = 0; i < count; i++)
    {
        if (symbols[i].type == SYM_STR && strcmp(symbols[i].data, s) == 0)
            return symbols[i].name;
    }
    char lbl[32];
    snprintf(lbl, sizeof(lbl), "S%d", count);
    symbols[count].name = strdup(lbl);
    symbols[count].type = SYM_STR;
    symbols[count].data = strdup(s);
    symbols[count].code_label = NULL;
    symbols[count].code_body = NULL;
    count++;
    return symbols[count-1].name;
}

const char *intern_float(const char *s)
{
    /* check for existing identical float literal -> reuse label */
    for (int i = 0; i < count; i++)
    {
        if (symbols[i].type == SYM_FLOAT && strcmp(symbols[i].data, s) == 0)
            return symbols[i].name;
    }
    char lbl[32];
    snprintf(lbl, sizeof(lbl), "F%d", count);
    symbols[count].name = strdup(lbl);
    symbols[count].type = SYM_FLOAT;
    symbols[count].data = strdup(s);
    symbols[count].code_label = NULL;
    symbols[count].code_body = NULL;
    count++;
    return symbols[count-1].name;
}

void set_function_body(const char *name, const char *body)
{
    int idx = find_symbol(name);
    if (idx < 0)
        return;
    if (symbols[idx].code_body)
        free(symbols[idx].code_body);
    symbols[idx].code_body = strdup(body);
}

sym_type_t get_symbol_type(const char *name)
{
    int idx = find_symbol(name);
    if (idx >= 0)
        return symbols[idx].type;
    return SYM_LABEL; /* default for undeclared: treat as label per subject */
}

int get_symbol_stack_size(void)
{
    return count;
}

void emit_symbols(void)
{
    /*************************************************************** */
	/* Emit string data first, then variables and function pointers. */
	/*************************************************************** */
    for (int i = 0; i < count; i++)
    {
        if (symbols[i].type == SYM_STR)
        {
            /*************************************** */
			/* emit label and bytes, terminated by 0 */
			/*************************************** */
            printf("%s: db ", symbols[i].name);
			/************************************** */
            /* print as comma-separated byte values */
			/************************************** */
            size_t slen = strlen(symbols[i].data);
            for (size_t j = 0; j < slen; j++)
            {
                unsigned char c = (unsigned char)symbols[i].data[j];
                printf("%u", (unsigned int)c);
                if (j + 1 < slen)
                    printf(", ");
            }
            if (slen > 0)
                printf(", ");
            printf("0\n");
        }
    }
    for (int i = 0; i < count; i++)
    {
        if (symbols[i].type == SYM_FLOAT)
        {
            /* emit float literal as dq <value> */
            printf("%s: dq %s\n", symbols[i].name, symbols[i].data);
        }
    }
    for (int i = 0; i < count; i++)
    {
        if (symbols[i].type == SYM_VAR)
        {
            /* make variable label visible to linker (so external C code
               can reference ARG0-like data labels) */
            printf("global %s\n", symbols[i].name);
            printf("%s: dd 0\n", symbols[i].name);
        }
        else if (symbols[i].type == SYM_FUNC)
        {
            /* function pointer slot should be global too */
            printf("global %s\n", symbols[i].name);
            printf("%s: dd %s\n", symbols[i].name, symbols[i].code_label);
        }
    }
}

void emit_function_bodies(void)
{
    for (int i = 0; i < count; i++)
    {
        if (symbols[i].type == SYM_FUNC && symbols[i].code_body)
        {
            printf("%s\n", symbols[i].code_body);
        }
    }
}

void emit_externs(void)
{
    /* Emit NASM extern declarations for referenced labels that are not
       declared as variables or functions with bodies. These represent
       external symbols provided by a separate library (e.g. libb.a).
    */
    for (int i = 0; i < count; i++)
    {
        if (symbols[i].type == SYM_LABEL)
        {
            printf("extern %s\n", symbols[i].name);
        }
    }
}