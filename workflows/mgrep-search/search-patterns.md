# mgrep Search Patterns

Common search patterns for Claude agents working in codebases.

---

## Function / Method Definitions

```bash
# Python
mgrep "^def " src/
mgrep "def <function_name>" src/
mgrep "async def " src/

# JavaScript / TypeScript
mgrep "function <name>" src/
mgrep "const <name> = " src/
mgrep "=> {" src/              # arrow functions (broad)
mgrep "<name>: \(" src/        # method in object

# Go
mgrep "^func " .
mgrep "func (<name>)" .        # method on receiver

# Rust
mgrep "^fn " src/
mgrep "pub fn " src/

# Ruby
mgrep "def <name>" .
```

---

## Class / Type Definitions

```bash
# Python
mgrep "^class " src/
mgrep "class <ClassName>" src/
mgrep "class <ClassName>(" src/  # with inheritance

# TypeScript / JavaScript
mgrep "^class " src/
mgrep "interface <Name>" src/
mgrep "type <Name> =" src/

# Go
mgrep "^type " .
mgrep "type <Name> struct" .
mgrep "type <Name> interface" .

# Rust
mgrep "^struct " src/
mgrep "^enum " src/
mgrep "^trait " src/
```

---

## Import / Dependency Usage

```bash
# Find where a module is imported
mgrep "import.*<module>" .
mgrep "from <module> import" src/       # Python
mgrep "require('<module>')" src/        # Node.js
mgrep "import .* from '<module>'" src/  # ES modules
mgrep "use <crate>::" src/              # Rust

# Find all files that use a specific dependency
mgrep -l "<dependency>" .
```

---

## TODOs and Code Markers

```bash
# All TODOs in the codebase
mgrep "TODO" .
mgrep "TODO:" .
mgrep "FIXME" .
mgrep "HACK" .
mgrep "XXX" .

# Files-only listing (for triage)
mgrep -l "TODO" .

# Count TODOs per file
mgrep -c "TODO" . | sort -t: -k2 -rn
```

---

## Error Handling Patterns

```bash
# Find error returns / throws
mgrep "throw new " src/
mgrep "raise " src/
mgrep "return Err(" src/     # Rust
mgrep "return nil, err" .    # Go

# Find error handler definitions
mgrep "catch (e" src/
mgrep "except Exception" src/
mgrep "if err != nil" .
```

---

## Configuration and Constants

```bash
# Find config keys
mgrep "config\." src/
mgrep "process.env\." src/
mgrep "os.environ" src/
mgrep "getenv(" .

# Find constants
mgrep "^const " src/
mgrep "^[A-Z_]* = " src/    # Python UPPER_CASE constants
```

---

## API Endpoints

```bash
# Express / Node
mgrep "\.get\(" src/
mgrep "\.post\(" src/
mgrep "router\." src/

# Python FastAPI / Flask
mgrep "@app\." src/
mgrep "@router\." src/

# Go
mgrep "http\.Handle" .
mgrep "\.HandleFunc(" .
```

---

## Test Patterns

```bash
# Find test files
mgrep -l "def test_" .         # Python unittest
mgrep -l "it(" test/           # Jest/Mocha
mgrep -l "func Test" .         # Go tests

# Find specific test
mgrep "def test_<name>" tests/
mgrep "it('<description>'" test/
```

---

## Quick Reference

```bash
# All usages of a symbol
mgrep "<symbol>" . --type py

# Find where something is defined vs used
mgrep "def <name>"   src/   # definition
mgrep "<name>("      src/   # call sites

# Cross-language search
mgrep -i "<name>" .

# Narrow to a subdirectory
mgrep "pattern" src/auth/
```
