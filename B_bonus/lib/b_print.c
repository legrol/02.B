/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   b_print.c                                          :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: rdel-olm <rdel-olm@student.42malaga.com>   +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/01/05 16:02:24 by rdel-olm          #+#    #+#             */
/*   Updated: 2026/01/05 23:51:26 by rdel-olm         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

/* ************************************************************* */
/* b_print.c - simple print helper for B bonus library
 * Writes the given C string to stdout followed by a newline and
 * returns the number of bytes written (excluding the newline).
 */
/* ************************************************************* */

#include "../../includes/B.h"

int b_print(void)
{
    /* read pointer to string from global ARG0 (dd <ptr>) */
    const char *s = NULL;
    asm volatile ("movl ARG0, %0" : "=r"(s));
    if (!s)
        return 0;
    /* compute length without calling strlen to avoid libc dependency */
    int n = 0;
    while (s[n]) n++;

    /* sys_write(1, s, n) via int 0x80 to avoid linking with libc */
    if (n > 0)
    {
        asm volatile (
            "movl $4, %%eax\n\t"
            "movl $1, %%ebx\n\t"
            "movl %0, %%ecx\n\t"
            "movl %1, %%edx\n\t"
            "int $0x80\n\t"
            :
            : "r"(s), "r"(n)
            : "eax", "ebx", "ecx", "edx", "memory");
    }

    /* write newline */
    {
        const char nl = '\n';
        asm volatile (
            "movl $4, %%eax\n\t"
            "movl $1, %%ebx\n\t"
            "leal %0, %%ecx\n\t"
            "movl $1, %%edx\n\t"
            "int $0x80\n\t"
            :
            : "m"(nl)
            : "eax", "ebx", "ecx", "edx", "memory");
    }
    return n;
}
