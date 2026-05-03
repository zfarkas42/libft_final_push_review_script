# Libft Checker Script

A **Bash script** to automatically verify the compliance of a **42 Libft project** with the subject requirements. It checks for mandatory files, Makefile rules, forbidden source files, forbidden functions, and more.

---

## 📌 **Features**

- **Repository Cloning**: Clones the provided Git repository for analysis.
- **File Existence Checks**: Verifies the presence of `Makefile`, `libft.h`, and other required files.
- **Makefile Validation**: Ensures the `Makefile` contains all required rules (`all`, `clean`, `fclean`, `re`, `$(NAME)`) and optional rules like `bonus`.
- **Forbidden Source Files**: Checks for disallowed source files (e.g., `.c` files not listed in the subject).
- **Forbidden Functions**: Detects the use of restricted functions (e.g., `printf`, `malloc`, `free`) in unauthorized files.
- **Norm Compliance**: Validates adherence to the **42 Norm** (e.g., line length, function count, and parameter limits).
- **Relinking Issues**: Identifies potential issues with `ar -rcs` in the `Makefile`.
- `**.PHONY` Declarations**: Checks for `.PHONY` declarations in the `Makefile` (recommended but optional).

---

## 🚀 **Usage**

### **1. Run the Script**

```bash
chmod +x check_libft.sh
./check_libft.sh
```

### **2. Enter the Git Repository URL**

When prompted, provide the URL of the **Libft repository** you want to check:

```
Enter the Git repository URL to check: https://github.com/your-username/libft.git
```

### **3. View Results**

The script will output:

- ✅ **Successes** (files/rules that pass checks).
- ❌ **Errors** (missing files, forbidden functions, etc.).
- ⚠️ **Warnings** (optional but recommended fixes).

Example output:

```
✅ Makefile exists.
✅ Makefile has the rule: all
❌ Makefile is missing the rule: bonus
⚠️  Makefile is missing .PHONY declarations (optional but recommended).
❌ 'printf' is forbidden in ft_putstr.c
```

---

## 📂 **Requirements**

- **Git**: Must be installed to clone the repository.
- **Bash**: The script is designed for Bash (Linux/macOS).

---

## 🔧 **Customization**

You can modify the following variables in the script to match your project's requirements:

- `REQUIRED_RULES`: Add/remove Makefile rules.
- `FORBIDDEN_SOURCES`: Update the list of disallowed source files.
- `FORBIDDEN_FUNCTIONS`: Adjust the list of restricted functions.
- `ALLOWED_MALLOC_FILES`/`ALLOWED_FREE_FILES`: Specify files where `malloc`/`free` are permitted.

---

## 📜 **Example Output**

```
=== Summary ===
Errors:   2
Warnings: 1
❌ The project has errors. Please fix them.
```

---

## 🤝 **Contributing**

Found a bug or want to improve the script? Open an issue or submit a pull request!

---
