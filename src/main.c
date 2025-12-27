/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   main.c                                             :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: rdel-olm <rdel-olm@student.42malaga.com>   +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2025/12/26 22:51:50 by rdel-olm          #+#    #+#             */
/*   Updated: 2025/12/27 18:56:49 by rdel-olm         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "../includes/B.h"

int main(int argc, char **argv) 
{
	if (argc > 1) {
		yyin = fopen(argv[1], "r");
		if (!yyin) {
			perror("fopen");
			return 1;
		}
	}
	if (yyparse() != 0) {
		fprintf(stderr, "Parsing failed\n");
		return 1;
	}
	return 0;
}
