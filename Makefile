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

# ══ Emojis ══════════════════════════════════════════════════════════════════ #
#    ------                                                                    #
# ════════════════════════════════════════════════════════════════════════════ #

ROCKET = 🚀
GEAR = ⚙️
CLEAN = 🧹
CHECK = ✅
CROSS = ❌
INFO = 💡
GAME = 🎮
CHART = 📊
SHIELD = 🛡️
FIRE = 🔥

# ══ Compilation══════════════════════════════════════════════════════════════ #
#    -----------                                                               #
# ════════════════════════════════════════════════════════════════════════════ #

CC                  = gcc
AR                  = ar rcs
RM                  = rm -f
MKD                 = mkdir -p
FLEX                = flex
YACC                = bison
NASM                = nasm
LD                  = ld

# ══ Directories ═════════════════════════════════════════════════════════════ #
#    -----------                                                               #
# ════════════════════════════════════════════════════════════════════════════ #

SRC_DIR             = src
INC_DIR             = includes
UTL_DIR             = utils
B_MAN_DIR           = B_mandatory
B_BON_DIR           = B_bonus
OBJ_DIR             = obj

# ══ Flags ═══════════════════════════════════════════════════════════════════ #
#    -----                                                                     #
# ════════════════════════════════════════════════════════════════════════════ #

CFLAGS              = -Wall -Werror -Wextra -O2
IFLAGS              = -I${INC_DIR}
NASM_FLAGS          = -felf32
LD_FLAGS            = -m elf_i386

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

# ═══ Default filenames and backend selector ═════════════════════════════════ #
#     -------------------------------                                  	       #
# ════════════════════════════════════════════════════════════════════════════ #

# Default input B source (you can override with `make assemble INPUT=yourfile.b`)
# Tests sources live in `tests/` now, so default to a test file there.
INPUT ?= tests/test_add.b

# Output assembly produced by the compiler (temporary)
OUT_ASM ?= out.asm

# Object file produced after assembling (temporary)
OUT_OBJ ?= $(OBJ_DIR)/out.o

# Final executable produced by the linker
FINAL ?= final

# Backend selector for assembling/linking pipeline
#  - 'nasm' : use NASM (Intel syntax) + ld  (default, recommended by the subject)
#  - 'gas'  : use GNU as (AT&T) + ld
# Override example: `make assemble BACKEND=gas`
BACKEND ?= nasm
USE_BONUS_LIB ?= 0
BONUS_LIB := B_bonus/lib/libb.a

# ═══ Rules ══════════════════════════════════════════════════════════════════ #
#     -----                                                                    #
# ════════════════════════════════════════════════════════════════════════════ #

all: ${NAME}

${NAME}: $(YACC_OUT) $(LEX_OUT) $(SRCS)
	@echo ""
	@echo "$(YELLOW)Building ${NAME}...$(DEF_COLOR)"
	@$(CC) $(CFLAGS) $(IFLAGS) -o ${NAME} $(YACC_OUT) $(LEX_OUT) $(SRCS) -lfl
	@echo "$(GREEN)${NAME} built successfully.$(DEF_COLOR)"
	@echo ""
	
$(YACC_OUT) $(YACC_HDR): $(B_MAN_DIR)/B.y
	@$(YACC) -d -o $(YACC_OUT) $(B_MAN_DIR)/B.y 2>/dev/null

$(LEX_OUT): $(B_MAN_DIR)/B.l $(YACC_HDR)
	@$(FLEX) -o $(LEX_OUT) $(B_MAN_DIR)/B.l

clean:
	@echo ""
	@echo "$(YELLOW)Removing object files ...$(DEF_COLOR)"
	@$(RM) ${NAME} parser.tab.c parser.tab.h lex.yy.c lex.yy.o
	@$(RM) $(OUT_ASM) out asm out.s
	@$(RM) $(OUT_OBJ) final final2 out
	@$(RM) -r $(OBJ_DIR)
	@$(RM) *.out others/*.out
	@$(RM) tests_error/*.out || true
	@echo "$(RED)Object files removed $(DEF_COLOR)"
	@echo ""

fclean: clean
	@echo "$(YELLOW)Removing binaries ...$(DEF_COLOR)"
	@$(RM) ${NAME}
	@$(RM) test *.out others/*.out
	@$(RM) final final2 out out.asm out.s $(OUT_OBJ)
	@$(RM) tests_error/*.out || true
	@echo "$(RED)Binaries removed $(DEF_COLOR)"
	@echo ""

re: fclean all

# -------------------------------------------------------- #
# Generate assembly by running the compiler on `$(INPUT)`
# -------------------------------------------------------- #
test: $(NAME)
	@echo ""
	@echo "$(YELLOW)Running tests...$(DEF_COLOR)"
	@echo ""
	@./utils/run_tests.sh $(USE_BONUS_LIB)
	@echo ""
	
test-errors: $(NAME)
	@echo ""
	@echo "$(YELLOW)Running error tests...$(DEF_COLOR)"
	@./utils/run_error_tests.sh
	@echo ""

# --------------------------------------------------------------------------------- #
# run bonus tests (delegates logic to script)
# --------------------------------------------------------------------------------- #
test-bonus: $(NAME)
	@echo ""
	@echo "$(YELLOW)Running bonus tests...$(DEF_COLOR)"
	@echo ""
	@# run the test script located inside the tests-bonus/tests_bonus directory
	@# choose directory name and run runner there
	@BONUS_LIB=$(BONUS_LIB) USE_BONUS_LIB=$(USE_BONUS_LIB) ./utils/run_bonus_tests.sh

# --------------------------------------------------------------------------------- #
# Run bonus tests and always link the bonus library (convenience target)
# --------------------------------------------------------------------------------- #
test-bonus-lib: $(NAME)
	@echo ""
	@echo "$(YELLOW)Running bonus tests with bonus lib...$(DEF_COLOR)"
	@echo ""
	@# run the test script located inside the tests-bonus/tests_bonus directory
	@# choose directory name and run runner there
	@BONUS_LIB=$(BONUS_LIB) USE_BONUS_LIB=1 ./utils/run_bonus_tests.sh
# --------------------------------------------------------------------------------- #

run: assemble
	@echo ""
	@echo "$(YELLOW)Running $(FINAL)..
	.$(DEF_COLOR)"
	@./$(FINAL)

# --------------------------------------------------------------- #
# Single assemble target that picks backend using BACKEND variable
# --------------------------------------------------------------- #

assemble: $(NAME)
	@echo ""
	@./utils/assemble.sh $(INPUT) $(BACKEND) $(USE_BONUS_LIB)
	@echo ""

# ------------------------------------------------------------------ #
# Eval-friendly compile target using nasm (mirrors evaluator compile())
# ------------------------------------------------------------------ #
eval_compile:
	@if [ -z "$(ARGS)" ]; then \
		echo "Usage: make eval_compile ARGS='file1.b file2.b ...'"; exit 1; \
	fi; \
	set -e; \
	# If single input, produce `final`; if multiple, produce one executable per input
	count=0; for _f in $(ARGS); do count=$$((count+1)); done; \
	# prepare optional bonus lib (opt-in)
	if [ "$(USE_BONUS_LIB)" = "1" ]; then \
		if [ ! -f "$(BONUS_LIB)" ]; then \
			$(MAKE) -C B_bonus/lib; \
		fi; \
		BONUS_LINK="$(BONUS_LIB)"; \
	else \
		BONUS_LINK=""; \
	fi; \
	if [ $$count -eq 1 ]; then \
		for f in $(ARGS); do \
			S=$$(mktemp); O=$$(mktemp); \
			./$(NAME) < $$f > $$S; \
			nasm -felf32 $$S -o $$O; \
			rm -f $$S; \
			if [ -n "$$BONUS_LINK" ]; then \
				ld -m elf_i386 $$O brt0.o $$BONUS_LINK -o final; \
			else \
				ld -m elf_i386 $$O brt0.o -o final; \
			fi; \
			echo "Linked final"; \
		done; \
	else \
		for f in $(ARGS); do \
			out="final_$$(basename $$f .b)"; \
			S=$$(mktemp); O=$$(mktemp); \
			./$(NAME) < $$f > $$S; \
			nasm -felf32 $$S -o $$O; \
			rm -f $$S; \
			if [ -n "$$BONUS_LINK" ]; then \
				ld -m elf_i386 $$O brt0.o $$BONUS_LINK -o $$out; \
			else \
				ld -m elf_i386 $$O brt0.o -o $$out; \
			fi; \
			echo "Linked $$out"; \
		done; \
	fi; \

.PHONY: all clean fclean re assemble link run test test-errors test-bonus
