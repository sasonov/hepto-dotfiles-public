---
name: file-skeletonization
description: "Read code files smartly — skeleton first, details on demand. Reduces token consumption by 80-90% while maintaining comparable answer quality. Based on Gemini research on AST skeletonization for LLM code understanding."
triggers:
  - "read code"
  - "understand codebase"
  - "explore file"
  - "navigate code"
  - "file structure"
  - "skeleton"
  - "AST"
---

# File Skeletonization: Read Smart, Not Hard

Based on Gemini research findings that AST skeletonization reduces token consumption by 80-90% while maintaining comparable answer quality. The key insight: for most tasks, you don't need function bodies — you need the skeleton of what exists and where it lives.

## Core Principle

**ALWAYS read the skeleton first. Only dive into function bodies when you need to modify them.**

## When to Use This Skill

- **Always** when reading a file > 200 lines or > 5K characters
- When exploring an unfamiliar codebase
- When figuring out where to make changes
- When searching for a specific function or class

For files under 200 lines AND under 5K chars, you can read the full file — the overhead is small enough.

## The Skeleton-First Protocol

### Step 1: State Your Intent

Before reading any large file, state what you're looking for:

> "I need to find the auth middleware function so I can add rate limiting"

This keeps you focused and prevents distraction-spirals.

### Step 2: Read the Skeleton

Use `read_file(path, limit=50)` to get the top of the file — imports, module docstrings, initial constants, and typically the first class/function definitions.

This gives you the file's structure at a fraction of the cost.

### Step 3: Search for Specifics

If the target isn't in the first 50 lines, use targeted searches:

```
search_files(pattern="class |def ", target="content", path=<file>)
```

This reveals all class and function signatures with their line numbers, without reading the whole file.

### Step 4: Targeted Deep Dive

Only now, read specific sections:

```
read_file(path, offset=<line_number>, limit=30)
```

Read just enough to understand the function you need to modify. 30 lines is usually sufficient for one function.

### Step 5: Modify

Now that you understand the structure and the specific function, make your edit. You never needed the other 800 lines.

## Skeleton Pattern by Language

### Python
Lines matching these patterns are skeleton lines:
- `import ` or `from ` (imports)
- `class ` (class definitions)
- `def ` (function/method definitions)
- Lines with `:` at indentation level 0 (top-level decorators, constants)
- Module-level docstrings (triple-quoted strings at the top)
- Constants: `UPPER_CASE = ` assignments at module level

NOT skeleton: function bodies (anything indented under a `def` or `class`).

### JavaScript/TypeScript
- `import ` / `export ` statements
- `class ` / `function ` declarations
- `const ` / `let ` / `var ` at top level (signatures only)
- Interface/type definitions (names + property lists, not implementations)
- `module.exports` / `export default`

### Go
- `import (`
- `func ` (all function signatures)
- `type ` (type definitions)
- `var ` / `const ` at package level
- `interface {` blocks (method signatures only)

### Rust
- `use ` statements
- `pub fn ` / `fn ` declarations
- `struct ` / `enum ` definitions
- `impl ` blocks (just the method signatures)
- `trait ` definitions (method signatures only)

### Bash/Shell
- Function definitions: `function_name() {`
- `source` / `.` statements
- Variable assignments at the top level
- `case` patterns (labels only, not bodies)

## Good vs Bad Patterns

### BAD — Reading Everything Upfront

```
# Don't do this for a 1200-line file
read_file(path="server.py")
# → Consumes ~30K tokens to understand the file
```

### GOOD — Skeleton First, Details On Demand

```
# Step 1: What am I looking for?
# "I need the request validation logic in server.py"

# Step 2: Get the skeleton
read_file(path="server.py", limit=50)
# → Sees imports, module docstring, first few classes

# Step 3: Find the specific section
search_files(pattern="def.*valid", target="content", path="server.py")
# → Finds: line 423: def validate_request(req):

# Step 4: Read just that section
read_file(path="server.py", offset=420, limit=30)
# → Reads the validation function in detail, ~750 tokens
```

### BAD — Sequential Scanning

```
# Reading chunks until you find what you need
read_file(path="server.py", limit=100)    # Not here...
read_file(path="server.py", offset=100, limit=100)  # Still not...
read_file(path="server.py", offset=200, limit=100)  # Found it but wasted 3 reads
```

### GOOD — Search Then Read

```
# Search for the target directly, then read precisely
search_files(pattern="def process_order", target="content", path="server.py")
# → Finds: line 567: def process_order(order):
read_file(path="server.py", offset=564, limit=40)
# → Got exactly what you need in one targeted read
```

### BAD — Reading Full Files for Navigation

```
# Trying to understand project structure by reading every file
read_file(path="src/models.py")    # 500 lines
read_file(path="src/views.py")     # 800 lines
read_file(path="src/routes.py")    # 400 lines
# Total: ~42K tokens just to find "where is the user auth"
```

### GOOD — Skeleton Multiple Files, Then Deep Dive

```
# Skeleton each file cheaply
read_file(path="src/models.py", limit=40)
read_file(path="src/views.py", limit=40)
read_file(path="src/routes.py", limit=40)
# Total: ~3K tokens, now you know auth is in routes.py:line 234

# Deep dive only where needed
read_file(path="src/routes.py", offset=230, limit=50)
# → Auth logic understood, total cost: ~5K tokens
```

## Workflow Integration

### When Exploring a New Project
1. Skeleton the top-level files (limit=40 each) — understand the architecture
2. Use `search_files` to map key functions across the codebase
3. Deep dive only into the files/functions you need to modify

### When Fixing a Bug
1. State what you're looking for (e.g., "where is the error handler for WebSocket disconnects")
2. Use `search_files` across the project to find candidate locations
3. Skeleton the candidate files if uncertain
4. Deep dive into the specific function with offset+limit

### When Adding a Feature
1. Skeleton the files where similar features live (for patterns)
2. Find the exact insertion point with `search_files`
3. Read 30-50 lines around the insertion point for context
4. Make your change

### When Reviewing PRs
1. Skeleton the changed files to understand their role
2. Read only the changed sections (use diff line numbers with offset+limit)
3. Skip reading unchanged function bodies entirely

## Token Savings Estimation

| Scenario | Full Read | Skeleton + Targeted | Savings |
|----------|-----------|-------------------|---------|
| 800-line Python file | ~20K tokens | ~2K tokens | 90% |
| Navigate 5 files (avg 400 lines) | ~50K tokens | ~5K tokens | 90% |
| Fix 1 function in 1500-line file | ~37K tokens | ~2K tokens | 95% |
| Understand project structure (20 files) | ~200K tokens | ~20K tokens | 90% |

## Anti-Patterns

1. **Reading the whole file "just in case"** — This is the most common waste. If you're not modifying most of the file, you don't need most of the file.
2. **Sequential scanning** — Reading chunks from line 1 until you find your target. Use search first.
3. **Skipping the intent statement** — Without stating what you need, you'll wander through code aimlessly.
4. **Re-reading files** — If you skeletonized a file earlier in the conversation, reference that knowledge rather than re-reading.

## Key Principles

1. **Intent first**: Always state what you're looking for before reading.
2. **Skeleton always**: For files > 200 lines or > 5K chars, skeleton first — no exceptions.
3. **Search before read**: Use `search_files` to find line numbers, then `read_file` with offset+limit to read precisely.
4. **Only what you modify**: Never read a function body unless you need to change it. Signatures suffice for understanding.
5. **Amortize knowledge**: Remember what you've already skeletonized. Don't re-read files in the same session.