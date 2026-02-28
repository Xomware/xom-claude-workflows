#!/usr/bin/env bash
# persistence-script.sh — Write or read session state for cross-session continuity
#
# Usage:
#   ./persistence-script.sh write <label>    # Open editor to write session summary
#   ./persistence-script.sh read  <label>    # Read most recent summary for label
#   ./persistence-script.sh list             # List all session summaries
#   ./persistence-script.sh latest <label>   # Print path to latest summary for label

set -euo pipefail

SESSIONS_DIR="${SESSIONS_DIR:-.claude/sessions}"
DATE="$(date +%Y-%m-%d)"

# ─── Ensure sessions directory exists ────────────────────────────────────────

mkdir -p "$SESSIONS_DIR"

# ─── Commands ────────────────────────────────────────────────────────────────

CMD="${1:-}"
LABEL="${2:-}"

case "$CMD" in

  write)
    if [[ -z "$LABEL" ]]; then
      echo "Usage: $0 write <label>"
      echo "Example: $0 write forge-auth"
      exit 1
    fi

    FILENAME="${SESSIONS_DIR}/${DATE}-${LABEL}.md"

    # Bootstrap from template if file doesn't exist
    if [[ ! -f "$FILENAME" ]]; then
      cat > "$FILENAME" <<EOF
# Session Summary: ${LABEL} — ${DATE}

## Accomplished
- 

## Key Decisions
- 

## In Progress
- 

## Next Steps
1. 

## Blockers
- (none)

## Files Modified
- 
EOF
      echo "📝 Created: $FILENAME"
    fi

    # Open in editor
    EDITOR="${EDITOR:-nano}"
    "$EDITOR" "$FILENAME"
    echo "✅ Saved: $FILENAME"
    ;;

  read)
    if [[ -z "$LABEL" ]]; then
      echo "Usage: $0 read <label>"
      exit 1
    fi

    LATEST="$(ls -t "${SESSIONS_DIR}"/*"${LABEL}"*.md 2>/dev/null | head -1 || true)"

    if [[ -z "$LATEST" ]]; then
      echo "No session summary found for label: $LABEL"
      echo "Sessions directory: $SESSIONS_DIR"
      exit 0
    fi

    echo "📖 Reading: $LATEST"
    echo "---"
    cat "$LATEST"
    ;;

  latest)
    if [[ -z "$LABEL" ]]; then
      echo "Usage: $0 latest <label>"
      exit 1
    fi

    LATEST="$(ls -t "${SESSIONS_DIR}"/*"${LABEL}"*.md 2>/dev/null | head -1 || true)"

    if [[ -z "$LATEST" ]]; then
      echo "(none)"
    else
      echo "$LATEST"
    fi
    ;;

  list)
    echo "📁 Session summaries in ${SESSIONS_DIR}/:"
    echo ""
    if ls "${SESSIONS_DIR}"/*.md 2>/dev/null | head -1 > /dev/null; then
      ls -lt "${SESSIONS_DIR}"/*.md | awk '{print $6, $7, $8, $9}'
    else
      echo "  (no summaries yet)"
    fi
    ;;

  *)
    echo "Usage: $0 <command> [label]"
    echo ""
    echo "Commands:"
    echo "  write <label>    Write/edit today's session summary"
    echo "  read  <label>    Read most recent summary for label"
    echo "  latest <label>   Print path to latest summary for label"
    echo "  list             List all session summaries"
    echo ""
    echo "Examples:"
    echo "  $0 write forge-auth"
    echo "  $0 read  forge-auth"
    echo "  $0 list"
    exit 1
    ;;

esac
