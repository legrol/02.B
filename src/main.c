/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   main.c                                             :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: rdel-olm <rdel-olm@student.42malaga.com>   +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2025/12/26 22:51:50 by rdel-olm          #+#    #+#             */
/*   Updated: 2026/01/04 23:29:41 by rdel-olm         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "../includes/B.h"
#include "../includes/emit.h"
#include <stdlib.h>

/*
 * main.c — driver for the B compiler
 *
 * Responsibilities:
 *  - Parse command line; optionally freopen a source file to stdin.
 *  - Invoke the Bison parser (syntax-directed translation) which emits
 *    NASM assembly into the internal emission buffer via semantic actions.
 *  - Emit top-level assembly sections and data (calls into `emit.h`):
 *      - emit_symbols() to write interned strings, variables and function
 *        pointer slots into `.data`.
 *      - write `main: dd prog_main` entry pointer expected by `brt0.o`.
 *      - flush emitted text for `prog_main` and optional helpers.
 *  - Emit captured function bodies after `prog_main` using
 *    emit_function_bodies() so functions do not fall-through into main.
 *
 * Notes:
 *  - The program intentionally emits NASM/Intel assembly. The test scripts
 *    in this repo assemble with `nasm -felf32` and link with `ld -m elf_i386`.
 */

int yyparse(void);

int main(int argc, char **argv)
{
    if (argc > 1)
    {
        if (freopen(argv[1], "r", stdin) == NULL)
        {
            perror("fopen");
            return 1;
        }
    }

	/* ********************************** */
    /* parser debug traces off by default */
	/* ********************************** */
    extern int yydebug;
    yydebug = 0;
    yyparse();

	/* ************************************************ */
    /* produce NASM/Intel-friendly sections and globals */
	/* ************************************************ */
    printf("global main\n");
    printf("section .data\n");
    emit_symbols();

	/* ******************************** */
    /* entry pointer expected by brt0.o */
	/* ******************************** */
    printf("main: dd prog_main\n");

	/* ************************************************ */
    /* small buffer + newline used by print_eax routine */
	/* ************************************************ */
    printf("print_buf: times 12 db 0\n");
    printf("print_buf_end:\n");
    printf("nl: db 10\n");
    printf("section .text\n");
    printf("prog_main:\n");

    flush_emit();


	/* **************************************************************** */
    /* By default we emit a call to `print_eax` and the helper routine so
       the generated program prints its final `eax` value to stdout. If
       the compiler is run with the environment variable `NO_PRINT` set,
       we skip emitting the call and the helper (useful to suppress
       output when not required). */
	/* **************************************************************** */
    if (getenv("NO_PRINT") == NULL)
    {
        printf("\tcall print_eax\n");
        printf("\tret\n");

		/* ********************************************************************* */
        /* helper: print unsigned eax followed by newline (uses Linux sys_write) */
		/* ********************************************************************* */
        printf("print_eax:\n");
        printf("\tpush ebx\n");
        printf("\tpush ecx\n");
        printf("\tpush edx\n");
        printf("\tmov ebx, eax\n");
        printf("\tmov ecx, 10\n");
        printf("\tlea esi, [print_buf_end]\n");
        printf("\t; build digits backwards into buffer\n");
        printf("\tcmp ebx, 0\n");
        printf("\tjne .Lconv\n");
        printf("\tmov byte [esi-1], '0'\n");
        printf("\tlea esi, [esi-1]\n");
        printf("\tjmp .Lout\n");
        printf(".Lconv:\n");
        printf("\txor edx, edx\n");
        printf(".Lloop:\n");
        printf("\tmov eax, ebx\n");
        printf("\txor edx, edx\n");
        printf("\tdiv ecx\n");
        printf("\tadd dl, '0'\n");
        printf("\tdec esi\n");
        printf("\tmov [esi], dl\n");
        printf("\tmov ebx, eax\n");
        printf("\tcmp ebx, 0\n");
        printf("\tjne .Lloop\n");
        printf(".Lout:\n");
        printf("\t; write digits: sys_write(1, esi, print_buf_end - esi)\n");
        printf("\tmov eax, 4\n");
        printf("\tmov ebx, 1\n");
        printf("\tmov ecx, esi\n");
        printf("\tmov edx, print_buf_end\n");
        printf("\tsub edx, ecx\n");
        printf("\tint 0x80\n");
        printf("\t; write newline\n");
        printf("\tmov eax, 4\n");
        printf("\tmov ebx, 1\n");
        printf("\tmov ecx, nl\n");
        printf("\tmov edx, 1\n");
        printf("\tint 0x80\n");
        printf("\tpop edx\n");
        printf("\tpop ecx\n");
        printf("\tpop ebx\n");
        printf("\tret\n");
    }
	/* ******************************************************************** */
    /* Emit captured function bodies after prog_main and its epilog/helpers
       so that prog_main ends with a proper return and function bodies do
       not accidentally fall-through into the main code.                    */
	/* ******************************************************************** */
    emit_function_bodies();
    return 0;
}