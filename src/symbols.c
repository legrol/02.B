/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   symbols.c                                          :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: rdel-olm <rdel-olm@student.42malaga.com>   +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2025/12/28 16:19:24 by rdel-olm          #+#    #+#             */
/*   Updated: 2025/12/30 00:47:08 by rdel-olm         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "../includes/B.h"

/* ****************************************************** */
/* Define the symbol table                                */
/* ****************************************************** */
static char *symbols[256];
static int count = 0;

void declare_symbol(const char *name)
{
    for (int i = 0; i < count; i++)
        if (!strcmp(symbols[i], name))
            return;

    symbols[count++] = strdup(name);

    /* Allocate storage */
    printf("%s:\n\t.long 0\n", name);
}

const char *symbol_label(const char *name)
{
    return name;
}
