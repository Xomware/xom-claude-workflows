#!/usr/bin/env bash
# ==============================================================================
# Xomware File Size Audit Script
#
# Scans a repository for source files exceeding the configured line count limit.
#
# Usage:
#   bash audit-file-sizes.sh [directory]
#
# Environment variables:
#   MAX_LINES   - Threshold for reporting (default: 800)
#   WARN_LINES  - Threshold for warnings (default: 600)
#   EXTENSIONS  - Comma-separated list of extensions (default: ts,tsx,js,jsx,py)
#
# Examples:
#   bash audit-file-sizes.sh
#   bash audit-file-sizes.sh ./src
#   MAX_LINES=600 bash audit-file-sizes.sh ./src
# ==============================================================================

set -euo pipefail

# ── Config ────────────────────────────────────────────────────────────────────
TARGET_DIR="${1:-.}"
MAX_LINES="${MAX_LINES:-800}"
WARN_LINES="${WARN_LINES:-600}"
EXTENSIONS="${EXTENSIONS:-ts,tsx,js,jsx,py}"

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# ── Exclusion patterns ────────────────────────────────────────────────────────
EXCLUDE_DIRS=(
  "node_modules"
  "dist"
  "build"
  ".next"
  ".nuxt"
  "coverage"
  "vendor"
  "__pycache__"
  ".cache"
  "migrations"
  "__fixtures__"
)

# ── Build find command ────────────────────────────────────────────────────────
build_find_cmd() {
  local cmd="find \"$TARGET_DIR\" -type f"

  # Exclude directories
  for dir in "${EXCLUDE_DIRS[@]}"; do
    cmd+=" -not -path \"*/${dir}/*\""
  done

  # Exclude minified/bundled files
  cmd+=" -not -name '*.min.js'"
  cmd+=" -not -name '*.bundle.js'"
  cmd+=" -not -name '*.min.css'"

  # Include only desired extensions
  local ext_clause="("
  local first=true
  IFS=',' read -ra EXT_ARRAY <<< "$EXTENSIONS"
  for ext in "${EXT_ARRAY[@]}"; do
    ext="${ext// /}"  # trim whitespace
    if $first; then
      ext_clause+="-name \"*.${ext}\""
      first=false
    else
      ext_clause+=" -o -name \"*.${ext}\""
    fi
  done
  ext_clause+=")"
  cmd+=" $ext_clause"

  echo "$cmd"
}

# ── Check for generated files ─────────────────────────────────────────────────
is_generated() {
  local file="$1"
  if head -5 "$file" 2>/dev/null | grep -qiE '@generated|AUTO-GENERATED|DO NOT EDIT'; then
    return 0  # is generated
  fi
  return 1    # not generated
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo -e "${BOLD}${CYAN}  Xomware File Size Audit${RESET}"
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo ""
  echo -e "  Target directory : ${TARGET_DIR}"
  echo -e "  Extensions       : ${EXTENSIONS}"
  echo -e "  Warn threshold   : ${WARN_LINES} lines"
  echo -e "  Error threshold  : ${MAX_LINES} lines"
  echo ""

  local error_count=0
  local warn_count=0
  local total_checked=0
  local error_files=()
  local warn_files=()

  # Collect files
  local find_cmd
  find_cmd=$(build_find_cmd)

  while IFS= read -r file; do
    # Skip generated files
    if is_generated "$file"; then
      continue
    fi

    local line_count
    line_count=$(wc -l < "$file" | tr -d ' ')

    total_checked=$((total_checked + 1))

    if [[ "$line_count" -ge "$MAX_LINES" ]]; then
      error_count=$((error_count + 1))
      error_files+=("${line_count}|${file}")
    elif [[ "$line_count" -ge "$WARN_LINES" ]]; then
      warn_count=$((warn_count + 1))
      warn_files+=("${line_count}|${file}")
    fi
  done < <(eval "$find_cmd" | sort)

  # ── Print errors ─────────────────────────────────────────────────────────
  if [[ ${#error_files[@]} -gt 0 ]]; then
    echo -e "${BOLD}${RED}  ❌  Files exceeding ${MAX_LINES} lines (must refactor):${RESET}"
    echo ""

    # Sort descending by line count
    local sorted_errors
    IFS=$'\n' sorted_errors=($(printf '%s\n' "${error_files[@]}" | sort -t'|' -k1 -rn))
    for entry in "${sorted_errors[@]}"; do
      local count="${entry%%|*}"
      local fname="${entry#*|}"
      local rel_path="${fname#$TARGET_DIR/}"
      printf "  ${RED}%-8s${RESET}  %s\n" "${count} lines" "$rel_path"
    done
    echo ""
  fi

  # ── Print warnings ────────────────────────────────────────────────────────
  if [[ ${#warn_files[@]} -gt 0 ]]; then
    echo -e "${BOLD}${YELLOW}  ⚠️   Files between ${WARN_LINES}–$((MAX_LINES - 1)) lines (consider refactoring):${RESET}"
    echo ""

    local sorted_warns
    IFS=$'\n' sorted_warns=($(printf '%s\n' "${warn_files[@]}" | sort -t'|' -k1 -rn))
    for entry in "${sorted_warns[@]}"; do
      local count="${entry%%|*}"
      local fname="${entry#*|}"
      local rel_path="${fname#$TARGET_DIR/}"
      printf "  ${YELLOW}%-8s${RESET}  %s\n" "${count} lines" "$rel_path"
    done
    echo ""
  fi

  # ── Summary ───────────────────────────────────────────────────────────────
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo -e "  Files checked  : ${total_checked}"

  if [[ $error_count -gt 0 ]]; then
    echo -e "  ${RED}Errors (≥${MAX_LINES}) : ${error_count}${RESET}"
  else
    echo -e "  Errors (≥${MAX_LINES}) : ${GREEN}0${RESET}"
  fi

  if [[ $warn_count -gt 0 ]]; then
    echo -e "  ${YELLOW}Warnings (≥${WARN_LINES}): ${warn_count}${RESET}"
  else
    echo -e "  Warnings (≥${WARN_LINES}): ${GREEN}0${RESET}"
  fi

  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo ""

  if [[ $error_count -gt 0 ]]; then
    echo -e "  ${RED}${BOLD}FAILED${RESET} — ${error_count} file(s) must be refactored before merging."
    echo -e "  See: workflows/modular-file-size/refactoring-guide.md"
    echo ""
    exit 1
  elif [[ $warn_count -gt 0 ]]; then
    echo -e "  ${YELLOW}${BOLD}WARNINGS${RESET} — ${warn_count} file(s) should be refactored."
    echo ""
    exit 0
  else
    echo -e "  ${GREEN}${BOLD}PASSED${RESET} — All files within size limits. ✅"
    echo ""
    exit 0
  fi
}

main "$@"
