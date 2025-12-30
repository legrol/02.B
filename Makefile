# ══ Names ═══════════════════════════════════════════════════════════════════ #
#    -----                                                                     #
# ════════════════════════════════════════════════════════════════════════════ #

NAME                = B

# ══ Colors ══════════════════════════════════════════════════════════════════ #
#    ------                                                                    #
# ════════════════════════════════════════════════════════════════════════════ #

DEL_LINE            = \033[2K
ITALIC              = \033[3m
BOLD                = \033[1m
DEF_COLOR           = \033[0;39m
GRAY                = \033[0;90m
RED                 = \033[0;91m
GREEN               = \033[0;92m
YELLOW              = \033[0;93m
BLUE                = \033[0;94m
MAGENTA             = \033[0;95m
CYAN                = \033[0;96m
WHITE               = \033[0;97m
BLACK               = \033[0;99m
ORANGE              = \033[38;5;209m
BROWN               = \033[38;2;184;143;29m
DARK_GRAY           = \033[38;5;234m
MID_GRAY            = \033[38;5;245m
DARK_GREEN          = \033[38;2;75;179;82m
DARK_YELLOW         = \033[38;5;143m

# ══ Compilation══════════════════════════════════════════════════════════════ #
#    -----------                                                               #
# ════════════════════════════════════════════════════════════════════════════ #

CC                  = gcc
AR                  = ar rcs
RM                  = rm -f
MKD                 = mkdir -p
FLEX                = flex
YACC                = bison

# ══ Directories ═════════════════════════════════════════════════════════════ #
#    -----------                                                               #
# ════════════════════════════════════════════════════════════════════════════ #

SRC_DIR             = src
INC_DIR             = includes
UTL_DIR             = utils
B_MAN_DIR           = B_mandatory
B_BON_DIR           = B_bonus

# ══ Flags ═══════════════════════════════════════════════════════════════════ #
#    -----                                                                     #
# ════════════════════════════════════════════════════════════════════════════ #

CFLAGS              = -Wall -Werror -Wextra -O2
IFLAGS              = -I${INC_DIR}

# ══ Sources ═════════════════════════════════════════════════════════════════ #
#    -------                                                                   #
#    All C sources in src/ (auto-discovered)								   #	
# ════════════════════════════════════════════════════════════════════════════ #

SRCS := $(wildcard $(SRC_DIR)/*.c)

# ══ Output file names for generated parser/lexer ════════════════════════════ #
#    --------------------------------------------                              #
# ════════════════════════════════════════════════════════════════════════════ #

YACC_OUT            = parser.tab.c
YACC_HDR            = parser.tab.h
LEX_OUT             = lex.yy.c

# ══ Sources ═════════════════════════════════════════════════════════════════ #
#    -------                                                                   #
#    Generated / B sources 													   #
# ════════════════════════════════════════════════════════════════════════════ #

B_MAN_SRC 		= $(B_MAN_DIR)/B.l \
					$(B_MAN_DIR)/B.y

# ═══ Rules ══════════════════════════════════════════════════════════════════ #
#     -----                                                                    #
# ════════════════════════════════════════════════════════════════════════════ #

all: ${NAME}


${NAME}: $(YACC_OUT) $(LEX_OUT) $(SRCS)
	@echo "$(YELLOW)Building ${NAME}...$(DEF_COLOR)"
	@$(CC) $(CFLAGS) $(IFLAGS) -o ${NAME} $(YACC_OUT) $(LEX_OUT) $(SRCS) -lfl
	@echo "$(GREEN)${NAME} built successfully.$(DEF_COLOR)"
	@echo ""
	
$(YACC_OUT) $(YACC_HDR): $(B_MAN_DIR)/B.y
	@$(YACC) -d -o $(YACC_OUT) $(B_MAN_DIR)/B.y

$(LEX_OUT): $(B_MAN_DIR)/B.l $(YACC_HDR)
	@$(FLEX) -o $(LEX_OUT) $(B_MAN_DIR)/B.l

clean:
	@echo ""
	@echo "$(YELLOW)Removing object files ...$(DEF_COLOR)"
	@$(RM) ${NAME} parser.tab.c parser.tab.h lex.yy.c lex.yy.o
	@$(RM) -r ${OBJ_DIR}
	@$(RM) *.out others/*.out
	@echo "$(RED)Object files removed $(DEF_COLOR)"
	@echo ""

fclean: clean
	@echo "$(YELLOW)Removing binaries ...$(DEF_COLOR)"
	@$(RM) ${NAME}
	@$(RM) test *.out others/*.out
	@echo "$(RED)Binaries removed $(DEF_COLOR)"
	@echo ""

re: fclean all

.PHONY: all clean fclean re
