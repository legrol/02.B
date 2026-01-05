/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   print.c                                            :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: rdel-olm <rdel-olm@student.42malaga.com>   +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/01/05 01:46:42 by rdel-olm          #+#    #+#             */
/*   Updated: 2026/01/05 16:11:24 by rdel-olm         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

# include "../../includes/B.h"

/*
 * Example function exported by the B standard library.
 * Signature: int print(int x)
 * Behavior: print `x` followed by a newline and return `x`.
 *
 * This uses the C runtime `printf`. When linking with `ld` directly you
 * must link the C runtime or compile/link this module together with the
 * rest of your program (see README.md in this folder).
 */

int print(int x)
{
    printf("%d\n", x);
    fflush(stdout);
    return x;
}
