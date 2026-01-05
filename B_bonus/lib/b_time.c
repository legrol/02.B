/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   b_time.c                                           :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: rdel-olm <rdel-olm@student.42malaga.com>   +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/01/05 16:04:25 by rdel-olm          #+#    #+#             */
/*   Updated: 2026/01/05 23:46:29 by rdel-olm         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

/* **************************************************** */
/* b_time.c - return current time (seconds since epoch) */
/* **************************************************** */
#include "../../includes/B.h"
#include <stdint.h>

int b_time(void)
{
    int t = 0;
    /* invoke time syscall directly (i386 syscall number 13) to avoid libc */
    register int eax asm("eax") = 13; /* sys_time */
    register int ebx asm("ebx") = 0;  /* NULL -> return value only */
    asm volatile ("int $0x80\n\t"
                  : "+r"(eax), "+r"(ebx)
                  : : "memory");
    t = eax;
    if (t < 0) return 0;
    return t;
}
