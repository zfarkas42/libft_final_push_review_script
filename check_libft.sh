#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Temporary directory for cloning
TEMP_DIR=$(mktemp -d)
if [ ! -d "$TEMP_DIR" ]; then
    echo -e "${RED}Error: Failed to create temporary directory.${NC}"
    exit 1
fi

# Function to clean up on exit
cleanup() {
    rm -rf "$TEMP_DIR" 2>/dev/null
}
trap cleanup EXIT

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo -e "${RED}Error: git is not installed.${NC}"
    exit 1
fi

# Ask for Git repo URL
read -p "Enter the Git repository URL to check: " REPO_URL
if [ -z "$REPO_URL" ]; then
    echo -e "${RED}Error: No repository URL provided.${NC}"
    exit 1
fi

# Clone the repo
echo -e "${BLUE}Cloning repository...${NC}"
if ! git clone --quiet "$REPO_URL" "$TEMP_DIR" 2>/dev/null; then
    echo -e "${RED}Error: Failed to clone the repository. Check the URL.${NC}"
    exit 1
fi

# Navigate to the repo
cd "$TEMP_DIR" || {
    echo -e "${RED}Error: Failed to enter the repository directory.${NC}"
    exit 1
}

# --- Initialize counters ---
ERRORS=0
WARNINGS=0

# --- Helper function to check if a file exists ---
file_exists() {
    if [ ! -f "$1" ]; then
        echo -e "${RED}❌ $1 is missing.${NC}"
        ERRORS=$((ERRORS + 1))
        return 1
    else
        echo -e "${GREEN}✅ $1 exists.${NC}"
        return 0
    fi
}

# --- 1. Check for Makefile and libft.h ---
file_exists "Makefile"
file_exists "libft.h"

# --- 2. Check Makefile rules ---
REQUIRED_RULES=("all" "clean" "fclean" "re" "\$(NAME)")
for rule in "${REQUIRED_RULES[@]}"; do
    if ! grep -q "^$rule:" Makefile; then
        echo -e "${RED}❌ Makefile is missing the rule: $rule${NC}"
        ERRORS=$((ERRORS + 1))
    else
        echo -e "${GREEN}✅ Makefile has the rule: $rule${NC}"
    fi
done

# --- 3. Check for bonus rule (optional) ---
if ! grep -q "^bonus:" Makefile; then
    echo -e "${YELLOW}⚠️  Makefile is missing the 'bonus' rule (optional but recommended).${NC}"
    WARNINGS=$((WARNINGS + 1))
else
    echo -e "${GREEN}✅ Makefile has the 'bonus' rule.${NC}"
fi

# --- 4. Check compilation flags (-Wall -Wextra -Werror) ---
CFLAGS_LINE=$(grep -E "^CFLAGS\s*=" Makefile | head -n 1)
if [ -z "$CFLAGS_LINE" ]; then
    echo -e "${RED}❌ Makefile is missing CFLAGS definition.${NC}"
    ERRORS=$((ERRORS + 1))
else
    if echo "$CFLAGS_LINE" | grep -q "\-Wall" && \
       echo "$CFLAGS_LINE" | grep -q "\-Wextra" && \
       echo "$CFLAGS_LINE" | grep -q "\-Werror"; then
        echo -e "${GREEN}✅ Makefile has required flags: -Wall -Wextra -Werror${NC}"
    else
        echo -e "${RED}❌ Makefile is missing required flags: -Wall -Wextra -Werror${NC}"
        ERRORS=$((ERRORS + 1))
    fi
fi

# --- 5. Check if ar is used to create the library ---
if ! grep -q "ar -rcs" Makefile; then
    echo -e "${RED}❌ Makefile does not use 'ar -rcs' to create the library.${NC}"
    ERRORS=$((ERRORS + 1))
else
    echo -e "${GREEN}✅ Makefile uses 'ar -rcs' to create the library.${NC}"
fi

# --- 6. Check for mandatory source files ---
MANDATORY_FUNCS=(
    "ft_isalpha" "ft_isdigit" "ft_isalnum" "ft_isascii" "ft_isprint"
    "ft_strlen" "ft_memset" "ft_bzero" "ft_memcpy" "ft_memmove"
    "ft_strlcpy" "ft_strlcat" "ft_toupper" "ft_tolower" "ft_strchr"
    "ft_strrchr" "ft_strncmp" "ft_memchr" "ft_memcmp" "ft_strnstr"
    "ft_atoi" "ft_calloc" "ft_strdup" "ft_substr" "ft_strjoin"
    "ft_strtrim" "ft_split" "ft_itoa" "ft_strmapi" "ft_striteri"
    "ft_putchar_fd" "ft_putstr_fd" "ft_putendl_fd" "ft_putnbr_fd"
)

for func in "${MANDATORY_FUNCS[@]}"; do
    file_exists "${func}.c"
done

# --- 7. Check for bonus source files (if bonus rule exists) ---
if grep -q "^bonus:" Makefile; then
    BONUS_FUNCS=(
        "ft_lstnew" "ft_lstadd_front" "ft_lstsize" "ft_lstlast"
        "ft_lstadd_back" "ft_lstdelone" "ft_lstclear" "ft_lstiter" "ft_lstmap"
    )
    for func in "${BONUS_FUNCS[@]}"; do
        file_exists "${func}_bonus.c"
    done
fi

# --- 8. Check libft.h ---
if [ -f "libft.h" ]; then
    # Check for header guards
    if ! grep -q "#ifndef LIBFT_H" libft.h || ! grep -q "# define LIBFT_H" libft.h || ! grep -q "#endif" libft.h; then
        echo -e "${RED}❌ libft.h is missing header guards.${NC}"
        ERRORS=$((ERRORS + 1))
    else
        echo -e "${GREEN}✅ libft.h has header guards.${NC}"
    fi

    # Check for bonus prototypes (if BONUS is defined)
    if grep -q "#ifdef BONUS" libft.h; then
        echo -e "${GREEN}✅ libft.h has conditional compilation for bonus.${NC}"

        # Check if t_list is inside #ifdef BONUS
        if grep -q "typedef struct s_list" libft.h; then
            # Extract the block between #ifdef BONUS and #endif
            BONUS_BLOCK=$(sed -n '/#ifdef BONUS/,/#endif/p' libft.h)
            if echo "$BONUS_BLOCK" | grep -q "typedef struct s_list"; then
                echo -e "${GREEN}✅ t_list struct is properly wrapped in #ifdef BONUS.${NC}"
            else
                echo -e "${RED}❌ t_list struct is not wrapped in #ifdef BONUS.${NC}"
                ERRORS=$((ERRORS + 1))
            fi
        fi
    else
        echo -e "${YELLOW}⚠️  libft.h does not use #ifdef BONUS for bonus prototypes.${NC}"
        WARNINGS=$((WARNINGS + 1))
    fi
fi

# --- 9. Check for forbidden source files (e.g., non-bonus files with _bonus suffix) ---
for file in *.c; do
    if [[ "$file" == *_bonus.c ]] && ! grep -q "^bonus:" Makefile; then
        echo -e "${RED}❌ Bonus file $file exists but 'bonus' rule is missing in Makefile.${NC}"
        ERRORS=$((ERRORS + 1))
    fi
done

# --- 10. Check for global variables (forbidden) ---
for file in *.c; do
    # Skip comments and static variables
    if grep -E "^[^#]*=[^=]" "$file" 2>/dev/null | grep -v "static " | grep -v "^[[:space:]]" | grep -v "^//" | grep -v "^/\*" | grep -q .; then
        echo -e "${RED}❌ Potential global variable in $file.${NC}"
        ERRORS=$((ERRORS + 1))
    fi
done

# --- 11. Check for norm compliance (25 lines per function) ---
for file in *.c; do
    # Check for functions longer than 25 lines (excluding empty lines and comments)
    if awk '
        /^{$/{start=NR; braces=1}
        /^{$/{braces++}
        /^}$/{braces--; if(braces==0 && NR-start>25) print FILENAME, NR-start}
    ' "$file" | grep -q .; then
        echo -e "${YELLOW}⚠️  $file contains functions longer than 25 lines (norm violation).${NC}"
        WARNINGS=$((WARNINGS + 1))
    fi
done

# --- 12. Check for forbidden functions ---
# List of forbidden functions (except in allowed files)
FORBIDDEN_FUNCS=(
    "printf"
    "fprintf"
    "sprintf"
    "snprintf"
    "puts"
    "putchar"
    "exit"
)

# Files where malloc is allowed
ALLOWED_MALLOC_FILES=(
    "ft_calloc.c"
    "ft_strdup.c"
    "ft_substr.c"
    "ft_strjoin.c"
    "ft_strtrim.c"
    "ft_split.c"
    "ft_itoa.c"
    "ft_strmapi.c"
    "ft_lstnew_bonus.c"
    "ft_lstmap_bonus.c"
)

# Files where free is allowed
ALLOWED_FREE_FILES=(
    "ft_lstclear_bonus.c"
    "ft_lstdelone_bonus.c"
    "ft_split.c"
    "ft_strtrim.c"
    "ft_strjoin.c"
    "ft_substr.c"
    "ft_strmapi.c"
    "ft_lstmap_bonus.c"
)

# Check each .c file for forbidden functions
for file in *.c; do
    # Skip binary files (if any)
    if ! file "$file" | grep -q "text"; then
        continue
    fi

    # Remove comments and strings from the file for accurate checks
    CLEANED_FILE=$(mktemp)
    # Remove single-line comments (// ...)
    # Remove multi-line comments (/* ... */)
    # Remove strings ("..." and '...')
    awk '
        {
            line = $0
            # Remove strings
            gsub /"[^"]*"/, "", line
            gsub /\x27[^\x27]*\x27/, "", line
            # Remove single-line comments
            gsub /\/\/.*$/, "", line
            # Remove multi-line comments (simplified)
            if (line ~ /\/\*/) {
                in_comment = 1
                sub(/\/\*[^*]*\*?/, "", line)
            }
            if (in_comment) {
                if (line ~ /\*\//) {
                    in_comment = 0
                    sub(/[^*]*\*\//, "", line)
                } else {
                    line = ""
                }
            }
            if (line != "") print line
        }
    ' "$file" > "$CLEANED_FILE"

    # Check for forbidden functions in the cleaned file
    for func in "${FORBIDDEN_FUNCS[@]}"; do
        if grep -E "\b$func\b" "$CLEANED_FILE" | grep -q .; then
            echo -e "${RED}❌ Forbidden function '$func' found in $file.${NC}"
            ERRORS=$((ERRORS + 1))
        fi
    done

    # Check for malloc (allowed only in specific files)
    if grep -E "\bmalloc\b" "$CLEANED_FILE" | grep -q .; then
        ALLOWED=0
        for allowed_file in "${ALLOWED_MALLOC_FILES[@]}"; do
            if [[ "$file" == "$allowed_file" ]]; then
                ALLOWED=1
                break
            fi
        done
        if [ "$ALLOWED" -eq 0 ]; then
            echo -e "${RED}❌ 'malloc' is not allowed in $file.${NC}"
            ERRORS=$((ERRORS + 1))
        fi
    fi

    # Check for free (allowed only in specific files)
    if grep -E "\bfree\b" "$CLEANED_FILE" | grep -q .; then
        ALLOWED=0
        for allowed_file in "${ALLOWED_FREE_FILES[@]}"; do
            if [[ "$file" == "$allowed_file" ]]; then
                ALLOWED=1
                break
            fi
        done
        if [ "$ALLOWED" -eq 0 ]; then
            echo -e "${RED}❌ 'free' is not allowed in $file.${NC}"
            ERRORS=$((ERRORS + 1))
        fi
    fi

    # Clean up the temporary file
    rm -f "$CLEANED_FILE"
done

# --- 13. Check for Makefile relinking issues ---
if grep -q "ar -rcs" Makefile && ! grep -q "\$(NAME): \$(OBJS)" Makefile; then
    echo -e "${YELLOW}⚠️  Makefile may have relinking issues. Ensure \$(NAME) depends on \$(OBJS).${NC}"
    WARNINGS=$((WARNINGS + 1))
fi

# --- 14. Check for .PHONY ---
if ! grep -q ".PHONY" Makefile; then
    echo -e "${YELLOW}⚠️  Makefile is missing .PHONY declarations (optional but recommended).${NC}"
    WARNINGS=$((WARNINGS + 1))
else
    echo -e "${GREEN}✅ Makefile has .PHONY declarations.${NC}"
fi

# --- Summary ---
echo -e "\n${BLUE}=== Summary ===${NC}"
echo -e "Errors:   ${RED}$ERRORS${NC}"
echo -e "Warnings: ${YELLOW}$WARNINGS${NC}"

if [ "$ERRORS" -eq 0 ]; then
    echo -e "${GREEN}✅ The project seems fully compliant with the subject!${NC}"
    exit 0
else
    echo -e "${RED}❌ The project has errors. Please fix them.${NC}"
    exit 1
fi