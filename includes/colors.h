/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   colors.h                                           :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: rdel-olm <rdel-olm@student.42malaga.com    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2025/12/15 23:45:29 by rdel-olm          #+#    #+#             */
/*   Updated: 2025/12/15 23:45:29 by rdel-olm         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#ifndef COLORS_H
# define COLORS_H

// =======================================================
// # Regular Colors
// =======================================================

# define RED		"\033[0;31m"
# define GREEN		"\033[0;32m"
# define YELLOW		"\033[0;33m"
# define BLUE		"\033[0;34m"
# define MAGENTA	"\033[0;35m"
# define CYAN		"\033[0;36m"
# define WHITE		"\033[0;37m"
# define ORANGE 	"\033[1;31m"
# define RESET		"\033[0m"

// =======================================================
// # Bold
// =======================================================

# define BDBLACK 	"\033[1;30m"
# define BDRED 		"\033[1;31m"
# define BDGREEN 	"\033[1;32m"
# define BDYELLOW 	"\033[1;33m"
# define BDBLUE 	"\033[1;34m"
# define BDMAGENTA 	"\033[1;35m"
# define BDCYAN 	"\033[1;36m"
# define BDWHITE 	"\033[1;37m"

// =======================================================
// # Underline
// =======================================================

# define ULRED 		"\033[4;31m"
# define ULGREEN 	"\033[4;32m"
# define ULYELLOW 	"\033[4;33m"
# define ULBLUE 	"\033[4;34m"
# define ULMAGENTA 	"\033[4;35m"
# define ULCYAN 	"\033[4;36m"
# define ULWHITE 	"\033[4;37m"

// =======================================================
// # Lines, fills, miscellany
// # (see graphics bellow)
// =======================================================

# define EQLIN 		"\u2550"
# define LSHADE 	"\u2591"
# define MSHADE 	"\u2592"
# define HSHADE 	"\u2593"
# define FBLOCK 	"\u2588"
# define EBLOCK 	"\u258d"
# define ARROWRG 	"\u2911"

#endif

// EQLIN	═══════════════════
// LSHADE	░░░░░░░░░░░░░░░░░░░
// MSHADE	▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
// HSHADE	▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
// FBLOCK	███████████████████
// EBLOCK	▍▍▍▍▍▍▍▍▍▍▍▍▍▍▍▍▍▍▍
// ARROWRG	⤑⤑⤑⤑⤑⤑⤑⤑⤑⤑⤑⤑⤑⤑