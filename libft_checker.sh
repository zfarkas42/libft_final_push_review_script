#!/bin/bash

# ============================================================
#  libft_checker.sh — Libft Project Validator (42 School)
#  Checks file structure, forbidden files, forbidden functions
#  and forbidden headers against the subject v19.2
# ============================================================

# ──────────────────────────────────────────────
#  Colour helpers
# ──────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

pass()  { echo -e "  ${GREEN}[PASS]${RESET} $*"; }
fail()  { echo -e "  ${RED}[FAIL]${RESET} $*"; ERRORS=$((ERRORS + 1)); }
warn()  { echo -e "  ${YELLOW}[WARN]${RESET} $*"; WARNINGS=$((WARNINGS + 1)); }
info()  { echo -e "  ${CYAN}[INFO]${RESET} $*"; }
header(){ echo -e "\n${BOLD}${CYAN}══════════════════════════════════════════${RESET}"; \
          echo -e "${BOLD}${CYAN}  $*${RESET}"; \
          echo -e "${BOLD}${CYAN}══════════════════════════════════════════${RESET}"; }

# progress_bar <current> <total> [label]
progress_bar() {
    local cur="$1" total="$2" label="${3:-}"
    local width=38
    local filled=$(( cur * width / total ))
    local empty=$(( width - filled ))
    local bar=""
    local i
    for (( i=0; i<filled; i++ )); do bar+="█"; done
    for (( i=0; i<empty;  i++ )); do bar+="░"; done
    local pct=$(( cur * 100 / total ))
    printf "\r  ${CYAN}[%s]${RESET} %3d%% (%d/%d) %s" "$bar" "$pct" "$cur" "$total" "$label"
}

ERRORS=0
WARNINGS=0

# ──────────────────────────────────────────────
#  Prompt for repo URL
# ──────────────────────────────────────────────
echo -e "\n${BOLD}╔══════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║        Libft Project Checker v1.0        ║${RESET}"
echo -e "${BOLD}║           42 School — v19.2              ║${RESET}"
echo -e "${BOLD}╚══════════════════════════════════════════╝${RESET}\n"

if [ -n "$1" ]; then
    REPO_URL="$1"
else
    echo -e "${BOLD}Enter your Git repository URL:${RESET}"
    read -r REPO_URL
fi

if [ -z "$REPO_URL" ]; then
    echo -e "${RED}Error: No repository URL provided.${RESET}"
    exit 1
fi

# ──────────────────────────────────────────────
#  Clone into a temp directory
# ──────────────────────────────────────────────
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

echo -e "\n${CYAN}Cloning repository...${RESET}"
if ! git clone --quiet "$REPO_URL" "$TMPDIR/repo" 2>&1; then
    echo -e "${RED}Error: Failed to clone repository. Check the URL and your access rights.${RESET}"
    exit 1
fi

REPO="$TMPDIR/repo"
echo -e "${GREEN}Repository cloned successfully.${RESET}"

# ──────────────────────────────────────────────
#  SECTION 1 — Required files present
# ──────────────────────────────────────────────
header "1 · Required Files"

REQUIRED_FILES=("Makefile" "libft.h")
for f in "${REQUIRED_FILES[@]}"; do
    if [ -f "$REPO/$f" ]; then
        pass "$f found"
    else
        fail "$f is MISSING"
    fi
done

# Check that at least some ft_*.c files exist
FT_C_COUNT=$(find "$REPO" -maxdepth 1 -name "ft_*.c" | wc -l)
if [ "$FT_C_COUNT" -gt 0 ]; then
    pass "$FT_C_COUNT ft_*.c source file(s) found"
else
    fail "No ft_*.c files found at the root"
fi

# README.md
if [ -f "$REPO/README.md" ]; then
    pass "README.md found"
else
    warn "README.md not found (required by subject Chapter V)"
fi

# ──────────────────────────────────────────────
#  SECTION 2 — File structure (all files at root)
# ──────────────────────────────────────────────
header "2 · File Structure"

# Files that must NOT be in subdirectories (only .c and .h source files)
SUBDIR_C=$(find "$REPO" -mindepth 2 -name "ft_*.c" ! -path "*/.git/*")
SUBDIR_H=$(find "$REPO" -mindepth 2 -name "*.h"    ! -path "*/.git/*")

if [ -z "$SUBDIR_C" ]; then
    pass "All ft_*.c files are at the root"
else
    while IFS= read -r f; do
        fail "ft_*.c file in subdirectory: ${f#$REPO/}"
    done <<< "$SUBDIR_C"
fi

if [ -z "$SUBDIR_H" ]; then
    pass "All header files are at the root"
else
    while IFS= read -r f; do
        fail "Header file in subdirectory: ${f#$REPO/}"
    done <<< "$SUBDIR_H"
fi

# libft.a must NOT be committed (it is built, not tracked)
if [ -f "$REPO/libft.a" ]; then
    warn "libft.a is committed to the repository (should be built, not tracked)"
else
    pass "libft.a not committed (correct)"
fi

# No object files committed
OBJ_FILES=$(find "$REPO" -maxdepth 1 -name "*.o" ! -path "*/.git/*")
if [ -z "$OBJ_FILES" ]; then
    pass "No .o files committed"
else
    while IFS= read -r f; do
        fail ".o file committed: ${f#$REPO/}"
    done <<< "$OBJ_FILES"
fi

# ──────────────────────────────────────────────
#  SECTION 3 — Forbidden / unexpected files
# ──────────────────────────────────────────────
header "3 · Forbidden / Unexpected Files"

# Allowed extensions at root: .c  .h  Makefile  README.md  .gitignore  libft.a (warn only above)
ALLOWED_PATTERN='^(ft_[a-z_]+\.c|libft\.h|Makefile|README\.md|\.gitignore|libft\.a)$'

while IFS= read -r filepath; do
    filename=$(basename "$filepath")
    # Skip hidden git files
    [[ "$filename" == .git* ]] && continue
    if ! echo "$filename" | grep -qE "$ALLOWED_PATTERN"; then
        warn "Unexpected file at root: $filename"
    fi
done < <(find "$REPO" -maxdepth 1 -type f ! -path "*/.git/*")

# Bonus files must be named *_bonus.c or *_bonus.h  (warn if present with wrong name)
BONUS_C=$(find "$REPO" -maxdepth 1 -name "*_bonus.c")
if [ -n "$BONUS_C" ]; then
    info "Bonus .c files detected — they will be checked separately"
fi

# ──────────────────────────────────────────────
#  SECTION 4 — Mandatory function files
# ──────────────────────────────────────────────
header "4 · Mandatory Function Files"

# Part 1 — Libc reimplementations
PART1=(
    ft_isalpha ft_isdigit ft_isalnum ft_isascii ft_isprint
    ft_strlen ft_memset ft_bzero ft_memcpy ft_memmove
    ft_strlcpy ft_strlcat ft_toupper ft_tolower
    ft_strchr ft_strrchr ft_strncmp ft_memchr ft_memcmp
    ft_strnstr ft_atoi ft_calloc ft_strdup
)

# Part 2 — Additional functions
PART2=(
    ft_substr ft_strjoin ft_strtrim ft_split ft_itoa
    ft_strmapi ft_striteri
    ft_putchar_fd ft_putstr_fd ft_putendl_fd ft_putnbr_fd
)

# Part 3 — Linked list
PART3=(
    ft_lstnew ft_lstadd_front ft_lstsize ft_lstlast
    ft_lstadd_back ft_lstdelone ft_lstclear ft_lstiter ft_lstmap
)

check_function_files() {
    local part_label="$1"
    local is_bonus_part="$2"
    shift 2
    local funcs=("$@")
    echo -e "\n  ${BOLD}$part_label${RESET}"
    for fn in "${funcs[@]}"; do
        if [ "$is_bonus_part" = "yes" ]; then
            # Part 3: files must be named *_bonus.c per the subject
            if [ -f "$REPO/${fn}_bonus.c" ]; then
                pass "${fn}_bonus.c"
            elif [ -f "$REPO/${fn}.c" ]; then
                warn "${fn}_bonus.c missing, but ${fn}.c exists (subject requires _bonus suffix for Part 3)"
            else
                fail "${fn}_bonus.c is MISSING"
            fi
        else
            if [ -f "$REPO/${fn}.c" ]; then
                pass "${fn}.c"
            else
                if [ -f "$REPO/${fn}_bonus.c" ]; then
                    warn "${fn}.c missing, but ${fn}_bonus.c exists (only counts for bonus)"
                else
                    fail "${fn}.c is MISSING"
                fi
            fi
        fi
    done
}

check_function_files "Part 1 — Libc functions"        "no"  "${PART1[@]}"
check_function_files "Part 2 — Additional functions"   "no"  "${PART2[@]}"
check_function_files "Part 3 — Linked list (bonus)"    "yes" "${PART3[@]}"

# ──────────────────────────────────────────────
#  SECTION 5 — Forbidden functions inside .c files
# ──────────────────────────────────────────────
header "5 · Forbidden Function Calls"

# Functions NEVER allowed in any ft_*.c (except where explicitly permitted)
ALWAYS_FORBIDDEN=(
    printf fprintf sprintf snprintf
    exit abort
    realloc
    system popen
)

# Functions allowed ONLY in specific files (malloc in calloc/strdup/part2/3, write in put*_fd)
# We check for *global* forbidden calls here; fine-grained per-file check follows.

echo -e "\n  ${BOLD}Checking for always-forbidden functions...${RESET}"
for fn in "${ALWAYS_FORBIDDEN[@]}"; do
    HITS=$(grep -rn --include="ft_*.c" "\b${fn}\s*(" "$REPO" 2>/dev/null | grep -v "//.*//" | grep -v "^\s*//" )
    if [ -n "$HITS" ]; then
        while IFS= read -r line; do
            fail "Forbidden '${fn}' in: $line"
        done <<< "$HITS"
    else
        pass "No use of '${fn}'"
    fi
done

# Part 1 functions must NOT use malloc/free (except calloc & strdup)
echo -e "\n  ${BOLD}Checking Part 1 functions — malloc/free not allowed (except ft_calloc, ft_strdup)...${RESET}"
PART1_NO_MALLOC=(
    ft_isalpha ft_isdigit ft_isalnum ft_isascii ft_isprint
    ft_strlen ft_memset ft_bzero ft_memcpy ft_memmove
    ft_strlcpy ft_strlcat ft_toupper ft_tolower
    ft_strchr ft_strrchr ft_strncmp ft_memchr ft_memcmp
    ft_strnstr ft_atoi
)
for fn in "${PART1_NO_MALLOC[@]}"; do
    src="$REPO/${fn}.c"
    [ ! -f "$src" ] && continue
    if grep -qE '\b(malloc|free)\s*\(' "$src"; then
        fail "${fn}.c uses malloc/free (not allowed in Part 1 for this function)"
    else
        pass "${fn}.c — no malloc/free"
    fi
done

# put*_fd functions must only use write as external function
echo -e "\n  ${BOLD}Checking ft_put*_fd — only 'write' allowed as external function...${RESET}"
PUT_FD=(ft_putchar_fd ft_putstr_fd ft_putendl_fd ft_putnbr_fd)
for fn in "${PUT_FD[@]}"; do
    src="$REPO/${fn}.c"
    [ ! -f "$src" ] && continue
    if grep -qE '\b(malloc|free)\s*\(' "$src"; then
        fail "${fn}.c uses malloc/free (only 'write' is allowed)"
    else
        pass "${fn}.c — no malloc/free"
    fi
done

# ──────────────────────────────────────────────
#  SECTION 6 — Forbidden header includes
# ──────────────────────────────────────────────
header "6 · Header Includes"

# Only allowed system headers (conservative list from what the functions need)
ALLOWED_HEADERS=(
    "stdlib.h"    # malloc, free, exit
    "unistd.h"    # write
    "string.h"    # size_t (via stddef)
    "stddef.h"    # size_t, NULL
    "strings.h"   # bzero (on some systems)
    "bsd/string.h" # strlcpy/strlcat testing only — warn if in submitted code
    "libft.h"
)

echo -e "\n  ${BOLD}Scanning all ft_*.c for included headers...${RESET}"
while IFS= read -r src; do
    fname=$(basename "$src")
    while IFS= read -r inc_line; do
        header_name=$(echo "$inc_line" | sed -E 's/.*#include\s*[<"]([^>"]+)[>"].*/\1/')
        # Check if it's an allowed header
        allowed=0
        for ah in "${ALLOWED_HEADERS[@]}"; do
            [ "$header_name" = "$ah" ] && allowed=1 && break
        done
        if [ "$allowed" -eq 0 ]; then
            fail "$fname includes forbidden/unexpected header: <$header_name>"
        fi
    done < <(grep -E '^\s*#include' "$src")
done < <(find "$REPO" -maxdepth 1 -name "ft_*.c")

# Warn about bsd/string.h — allowed for testing but not for submission on some campuses
BDS_USE=$(grep -rl "bsd/string.h" "$REPO" --include="ft_*.c" 2>/dev/null)
if [ -n "$BDS_USE" ]; then
    warn "bsd/string.h included in source files — only needed for local testing, may cause issues"
fi

# ──────────────────────────────────────────────
#  SECTION 7 — Global variables
# ──────────────────────────────────────────────
header "7 · Global Variables (Strictly Forbidden)"

GLOBAL_PATTERN='^[a-zA-Z].*[a-zA-Z0-9_]\s*[^(=;]*;'   # crude heuristic

echo -e "\n  ${BOLD}Scanning ft_*.c for potential global variables...${RESET}"
GLOBAL_FOUND=0
while IFS= read -r src; do
    fname=$(basename "$src")
    # Look for variable declarations outside of functions: lines at column 0, not keywords, not #
    while IFS= read -r line; do
        lineno=$(echo "$line" | cut -d: -f1)
        content=$(echo "$line" | cut -d: -f2-)
        # Skip preprocessor, comments, function definitions, typedefs, struct/enum
        echo "$content" | grep -qE '^\s*(#|/[/*]|typedef|struct|enum|static|void\s+\w+\s*\(|int\s+main)' && continue
        # Flag anything that looks like a declaration at file scope
        if echo "$content" | grep -qE '^[a-zA-Z_(][a-zA-Z0-9_ *]+\s+[a-zA-Z_][a-zA-Z0-9_]*\s*[;=]'; then
            fail "Possible global variable in $fname:$lineno → $content"
            GLOBAL_FOUND=1
        fi
    done < <(grep -n "" "$src" | head -50)   # only first 50 lines (globals are near top)
done < <(find "$REPO" -maxdepth 1 -name "ft_*.c")

[ "$GLOBAL_FOUND" -eq 0 ] && pass "No obvious global variables detected"

# ──────────────────────────────────────────────
#  SECTION 8 — Makefile checks
# ──────────────────────────────────────────────
header "8 · Makefile"

MAKEFILE="$REPO/Makefile"
if [ -f "$MAKEFILE" ]; then
    # Required rules
    for rule in '$(NAME)' 'all' 'clean' 'fclean' 're'; do
        if grep -q "$rule" "$MAKEFILE"; then
            pass "Rule '$rule' present"
        else
            fail "Rule '$rule' MISSING in Makefile"
        fi
    done

    # Bonus rule (warn only — not strictly mandatory unless submitting bonuses)
    if grep -q "bonus" "$MAKEFILE"; then
        pass "Bonus rule present"
    else
        warn "No 'bonus' rule in Makefile (required if submitting bonus functions)"
    fi

    # Must use ar, not libtool
    if grep -q "libtool" "$MAKEFILE"; then
        fail "Makefile uses 'libtool' — strictly forbidden (use 'ar')"
    else
        pass "No use of 'libtool'"
    fi

    if grep -q "\bar\b" "$MAKEFILE"; then
        pass "'ar' command found"
    else
        warn "'ar' command not detected — make sure you're using 'ar' to build libft.a"
    fi

    # Flags
    for flag in '-Wall' '-Wextra' '-Werror'; do
        if grep -qF -- "$flag" "$MAKEFILE"; then
            pass "Compiler flag '$flag' present"
        else
            fail "Compiler flag '$flag' MISSING"
        fi
    done

    # Must not use std=c99
    if grep -q "\-std=c99" "$MAKEFILE"; then
        fail "Makefile uses -std=c99 — forbidden by subject"
    else
        pass "No -std=c99 flag"
    fi

    # Must not use libtool
    if grep -q "libtool" "$MAKEFILE"; then
        fail "libtool found in Makefile — strictly forbidden"
    fi
else
    fail "Makefile not found — cannot check rules"
fi

# ──────────────────────────────────────────────
#  SECTION 9 — libft.h checks
# ──────────────────────────────────────────────
header "9 · libft.h Header File"

LIBFT_H="$REPO/libft.h"
if [ -f "$LIBFT_H" ]; then
    # t_list struct
    if grep -q "t_list" "$LIBFT_H"; then
        pass "t_list struct declaration found"
    else
        warn "t_list struct not found in libft.h (required for Part 3)"
    fi

    # content and next members
    if grep -q "content" "$LIBFT_H" && grep -q "next" "$LIBFT_H"; then
        pass "t_list members 'content' and 'next' found"
    else
        warn "t_list members 'content' / 'next' may be missing"
    fi

    # Include guard
    if grep -qE '#ifndef|#pragma once' "$LIBFT_H"; then
        pass "Include guard detected"
    else
        warn "No include guard (#ifndef / #pragma once) found in libft.h"
    fi

    # All mandatory prototypes declared
    echo -e "\n  ${BOLD}Checking function prototypes in libft.h...${RESET}"
    ALL_MANDATORY=("${PART1[@]}" "${PART2[@]}" "${PART3[@]}")
    for fn in "${ALL_MANDATORY[@]}"; do
        if grep -q "$fn" "$LIBFT_H"; then
            pass "Prototype for $fn"
        else
            fail "Prototype for $fn MISSING in libft.h"
        fi
    done
else
    fail "libft.h not found"
fi

# ──────────────────────────────────────────────
#  SECTION 10 — README.md content checks
# ──────────────────────────────────────────────
header "10 · README.md Requirements"

README="$REPO/README.md"
if [ -f "$README" ]; then
    # First line must be italicized and mention 42 curriculum
    FIRST_LINE=$(head -1 "$README")
    if echo "$FIRST_LINE" | grep -qi "42"; then
        pass "First line references '42'"
    else
        warn "First line should be italicized and mention the 42 curriculum"
    fi

    # Required sections
    for section in "Description" "Instructions" "Resources"; do
        if grep -qi "## *$section\|# *$section\|$section" "$README"; then
            pass "Section '$section' found"
        else
            warn "Section '$section' not found in README.md"
        fi
    done

    # AI usage mentioned in Resources
    if grep -qi "AI\|artificial intelligence\|ChatGPT\|Claude\|LLM" "$README"; then
        pass "AI usage mentioned in README"
    else
        warn "AI usage description not found (required in Resources section)"
    fi
else
    warn "README.md missing — skipping content checks"
fi

# ──────────────────────────────────────────────
#  SECTION 11 — Quick compile test (if cc available)
# ──────────────────────────────────────────────
header "11 · Compilation Test"

if command -v cc &>/dev/null; then
    echo -e "\n  ${BOLD}Attempting to compile all ft_*.c files individually...${RESET}"
    COMPILE_ERRORS=0
    while IFS= read -r src; do
        fname=$(basename "$src")
        OUTPUT=$(cc -Wall -Wextra -Werror -c "$src" -I"$REPO" -o /dev/null 2>&1)
        if [ $? -eq 0 ]; then
            pass "$fname compiles cleanly"
        else
            fail "$fname COMPILATION ERRORS:"
            echo "$OUTPUT" | sed 's/^/      /'
            COMPILE_ERRORS=$((COMPILE_ERRORS + 1))
        fi
    done < <(find "$REPO" -maxdepth 1 -name "ft_*.c")

    if [ "$COMPILE_ERRORS" -eq 0 ]; then
        pass "All files compiled without errors or warnings"
    fi
else
    warn "cc not found — skipping compilation test"
fi

# ──────────────────────────────────────────────
#  SECTION 12 — Function signature verification
# ──────────────────────────────────────────────
header "12 · Function Signatures"

# Helper: extract the definition signature from a .c file for a given function name.
# Strategy: grab up to 6 lines starting from the line that contains "fn_name(" but
# is NOT a prototype (i.e. does NOT end with ';'), collapse whitespace, strip the
# opening '{' and everything after it, then normalise spaces for comparison.
get_definition() {
    local src="$1"   # path to .c file
    local fn="$2"    # function name (e.g. ft_strlen)
    [ ! -f "$src" ] && { echo "FILE_NOT_FOUND"; return; }

    # Find the line number where the definition starts:
    # must contain the function name followed by '(' and must NOT be a prototype (no ';' at end)
    local start_line
    start_line=$(grep -n "\b${fn}\s*(" "$src" | grep -v ';\s*$' | grep -v '^\s*//' | head -1 | cut -d: -f1)
    [ -z "$start_line" ] && { echo "NOT_FOUND"; return; }

    # Read up to 8 lines from start_line, join them, cut at first '{'
    local raw
    raw=$(awk "NR>=${start_line} && NR<=${start_line}+7" "$src" | tr '\n' ' ')
    # Cut everything from '{' onward
    raw="${raw%%\{*}"
    # Normalise: collapse multiple spaces/tabs, trim
    raw=$(echo "$raw" | tr -s ' \t' ' ' | sed 's/^ //;s/ $//')
    echo "$raw"
}

# Helper: compare an extracted signature against an expected one.
# Both are normalised the same way before comparison.
normalise() {
    # Remove all spaces around '*', collapse spaces, lowercase type keywords
    echo "$1" \
        | sed 's/\s*\*\s*/\*/g' \
        | tr -s ' ' \
        | sed 's/ $//'
}

# Accumulate signature results so we can show a progress bar while scanning,
# then print detailed results afterwards.
SIG_RESULTS=()   # each entry: "STATUS|fn|expected|got_norm"

queue_sig() {
    local fn="$1"
    local expected="$2"
    local src="$REPO/${fn}.c"

    # Fall back to _bonus variant (Part 3 linked-list functions)
    if [ ! -f "$src" ] && [ -f "$REPO/${fn}_bonus.c" ]; then
        src="$REPO/${fn}_bonus.c"
    fi

    local got
    got=$(get_definition "$src" "$fn")

    local norm_got norm_exp
    norm_exp=$(normalise "$expected")

    if [ "$got" = "FILE_NOT_FOUND" ]; then
        SIG_RESULTS+=("WARN|$fn|$norm_exp|FILE_NOT_FOUND")
    elif [ "$got" = "NOT_FOUND" ]; then
        SIG_RESULTS+=("FAIL|$fn|$norm_exp|NOT_FOUND")
    else
        norm_got=$(normalise "$got")
        if [ "$norm_got" = "$norm_exp" ]; then
            SIG_RESULTS+=("PASS|$fn|$norm_exp|$norm_got")
        else
            SIG_RESULTS+=("FAIL|$fn|$norm_exp|$norm_got")
        fi
    fi
}

# Build the full list of (fn, expected) pairs
declare -a SIG_FNS SIG_EXP

SIG_FNS+=(ft_isalpha);    SIG_EXP+=("int ft_isalpha(int c)")
SIG_FNS+=(ft_isdigit);    SIG_EXP+=("int ft_isdigit(int c)")
SIG_FNS+=(ft_isalnum);    SIG_EXP+=("int ft_isalnum(int c)")
SIG_FNS+=(ft_isascii);    SIG_EXP+=("int ft_isascii(int c)")
SIG_FNS+=(ft_isprint);    SIG_EXP+=("int ft_isprint(int c)")
SIG_FNS+=(ft_strlen);     SIG_EXP+=("size_t ft_strlen(const char *s)")
SIG_FNS+=(ft_memset);     SIG_EXP+=("void *ft_memset(void *s, int c, size_t n)")
SIG_FNS+=(ft_bzero);      SIG_EXP+=("void ft_bzero(void *s, size_t n)")
SIG_FNS+=(ft_memcpy);     SIG_EXP+=("void *ft_memcpy(void *dest, const void *src, size_t n)")
SIG_FNS+=(ft_memmove);    SIG_EXP+=("void *ft_memmove(void *dest, const void *src, size_t n)")
SIG_FNS+=(ft_strlcpy);    SIG_EXP+=("size_t ft_strlcpy(char *dst, const char *src, size_t size)")
SIG_FNS+=(ft_strlcat);    SIG_EXP+=("size_t ft_strlcat(char *dst, const char *src, size_t size)")
SIG_FNS+=(ft_toupper);    SIG_EXP+=("int ft_toupper(int c)")
SIG_FNS+=(ft_tolower);    SIG_EXP+=("int ft_tolower(int c)")
SIG_FNS+=(ft_strchr);     SIG_EXP+=("char *ft_strchr(const char *s, int c)")
SIG_FNS+=(ft_strrchr);    SIG_EXP+=("char *ft_strrchr(const char *s, int c)")
SIG_FNS+=(ft_strncmp);    SIG_EXP+=("int ft_strncmp(const char *s1, const char *s2, size_t n)")
SIG_FNS+=(ft_memchr);     SIG_EXP+=("void *ft_memchr(const void *s, int c, size_t n)")
SIG_FNS+=(ft_memcmp);     SIG_EXP+=("int ft_memcmp(const void *s1, const void *s2, size_t n)")
SIG_FNS+=(ft_strnstr);    SIG_EXP+=("char *ft_strnstr(const char *haystack, const char *needle, size_t len)")
SIG_FNS+=(ft_atoi);       SIG_EXP+=("int ft_atoi(const char *nptr)")
SIG_FNS+=(ft_calloc);     SIG_EXP+=("void *ft_calloc(size_t nmemb, size_t size)")
SIG_FNS+=(ft_strdup);     SIG_EXP+=("char *ft_strdup(const char *s)")
SIG_FNS+=(ft_substr);     SIG_EXP+=("char *ft_substr(char const *s, unsigned int start, size_t len)")
SIG_FNS+=(ft_strjoin);    SIG_EXP+=("char *ft_strjoin(char const *s1, char const *s2)")
SIG_FNS+=(ft_strtrim);    SIG_EXP+=("char *ft_strtrim(char const *s1, char const *set)")
SIG_FNS+=(ft_split);      SIG_EXP+=("char **ft_split(char const *s, char c)")
SIG_FNS+=(ft_itoa);       SIG_EXP+=("char *ft_itoa(int n)")
SIG_FNS+=(ft_strmapi);    SIG_EXP+=("char *ft_strmapi(char const *s, char (*f)(unsigned int, char))")
SIG_FNS+=(ft_striteri);   SIG_EXP+=("void ft_striteri(char *s, void (*f)(unsigned int, char*))")
SIG_FNS+=(ft_putchar_fd); SIG_EXP+=("void ft_putchar_fd(char c, int fd)")
SIG_FNS+=(ft_putstr_fd);  SIG_EXP+=("void ft_putstr_fd(char *s, int fd)")
SIG_FNS+=(ft_putendl_fd); SIG_EXP+=("void ft_putendl_fd(char *s, int fd)")
SIG_FNS+=(ft_putnbr_fd);  SIG_EXP+=("void ft_putnbr_fd(int n, int fd)")
SIG_FNS+=(ft_lstnew);       SIG_EXP+=("t_list *ft_lstnew(void *content)")
SIG_FNS+=(ft_lstadd_front); SIG_EXP+=("void ft_lstadd_front(t_list **lst, t_list *new)")
SIG_FNS+=(ft_lstsize);      SIG_EXP+=("int ft_lstsize(t_list *lst)")
SIG_FNS+=(ft_lstlast);      SIG_EXP+=("t_list *ft_lstlast(t_list *lst)")
SIG_FNS+=(ft_lstadd_back);  SIG_EXP+=("void ft_lstadd_back(t_list **lst, t_list *new)")
SIG_FNS+=(ft_lstdelone);    SIG_EXP+=("void ft_lstdelone(t_list *lst, void (*del)(void *))")
SIG_FNS+=(ft_lstclear);     SIG_EXP+=("void ft_lstclear(t_list **lst, void (*del)(void *))")
SIG_FNS+=(ft_lstiter);      SIG_EXP+=("void ft_lstiter(t_list *lst, void (*f)(void *))")
SIG_FNS+=(ft_lstmap);       SIG_EXP+=("t_list *ft_lstmap(t_list *lst, void *(*f)(void *), void (*del)(void *))")

TOTAL_SIGS=${#SIG_FNS[@]}

echo -e "\n  Scanning ${TOTAL_SIGS} function signatures...\n"

for (( idx=0; idx<TOTAL_SIGS; idx++ )); do
    progress_bar $(( idx + 1 )) "$TOTAL_SIGS" "${SIG_FNS[$idx]}"
    queue_sig "${SIG_FNS[$idx]}" "${SIG_EXP[$idx]}"
done
echo -e "\n"   # newline after progress bar

# ── Print results grouped by part ──
print_sig_results() {
    local label="$1"; shift
    local fns=("$@")
    echo -e "  ${BOLD}$label${RESET}"
    for fn in "${fns[@]}"; do
        for entry in "${SIG_RESULTS[@]}"; do
            IFS='|' read -r status efn exp got <<< "$entry"
            [ "$efn" != "$fn" ] && continue
            case "$status" in
                PASS) pass "$fn — signature OK" ;;
                WARN) warn "$fn — file not found, skipping signature check" ;;
                FAIL)
                    fail "$fn — $([ "$got" = "NOT_FOUND" ] && echo "function definition not found in source" || echo "signature MISMATCH")"
                    if [ "$got" != "NOT_FOUND" ]; then
                        echo -e "      ${YELLOW}Expected:${RESET} $exp"
                        echo -e "      ${RED}Got     :${RESET} $got"
                    fi
                    ;;
            esac
            break
        done
    done
}

PART1_SIG=(ft_isalpha ft_isdigit ft_isalnum ft_isascii ft_isprint
           ft_strlen ft_memset ft_bzero ft_memcpy ft_memmove
           ft_strlcpy ft_strlcat ft_toupper ft_tolower
           ft_strchr ft_strrchr ft_strncmp ft_memchr ft_memcmp
           ft_strnstr ft_atoi ft_calloc ft_strdup)

PART2_SIG=(ft_substr ft_strjoin ft_strtrim ft_split ft_itoa
           ft_strmapi ft_striteri
           ft_putchar_fd ft_putstr_fd ft_putendl_fd ft_putnbr_fd)

PART3_SIG=(ft_lstnew ft_lstadd_front ft_lstsize ft_lstlast
           ft_lstadd_back ft_lstdelone ft_lstclear ft_lstiter ft_lstmap)

print_sig_results "Part 1 — Libc functions"      "${PART1_SIG[@]}"
echo ""
print_sig_results "Part 2 — Additional functions" "${PART2_SIG[@]}"
echo ""
print_sig_results "Part 3 — Linked list functions" "${PART3_SIG[@]}"

# ──────────────────────────────────────────────
#  SUMMARY
# ──────────────────────────────────────────────
echo -e "\n${BOLD}${CYAN}══════════════════════════════════════════${RESET}"
echo -e "${BOLD}${CYAN}  SUMMARY${RESET}"
echo -e "${BOLD}${CYAN}══════════════════════════════════════════${RESET}\n"

if [ "$ERRORS" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
    echo -e "  ${GREEN}${BOLD}★ Perfect! No errors or warnings found.${RESET}"
elif [ "$ERRORS" -eq 0 ]; then
    echo -e "  ${YELLOW}${BOLD}● ${WARNINGS} warning(s) found, but no hard errors.${RESET}"
else
    echo -e "  ${RED}${BOLD}✗ ${ERRORS} error(s) and ${WARNINGS} warning(s) found.${RESET}"
fi

echo ""
echo -e "  ${RED}Errors   : ${ERRORS}${RESET}"
echo -e "  ${YELLOW}Warnings : ${WARNINGS}${RESET}"
echo ""

if [ "$ERRORS" -gt 0 ]; then
    echo -e "  ${RED}This project would likely ${BOLD}FAIL${RESET}${RED} peer evaluation.${RESET}"
else
    echo -e "  ${GREEN}This project looks ${BOLD}READY${RESET}${GREEN} for peer evaluation.${RESET}"
fi

echo ""
exit "$ERRORS"