# Session Summary Template

Copy this template when writing a session summary at end of session.

**Save to:** `.claude/sessions/YYYY-MM-DD-<label>.md`

---

```markdown
# Session Summary: <label> — YYYY-MM-DD

## Accomplished
<!-- What was completed this session (bullet list) -->
- 

## Key Decisions
<!-- Decisions made and WHY — context for next session -->
- 

## In Progress
<!-- What is partially done (with file locations and % complete if known) -->
- 

## Next Steps
<!-- Ordered list of what to do next session -->
1. 

## Blockers
<!-- Anything that needs external input or is blocking progress -->
- (none)

## Files Modified
<!-- Key files created or changed this session -->
- 

## Notes
<!-- Any other context that would help next session start faster -->
```

---

## Minimal Template (for short sessions)

```markdown
# Session: <label> — YYYY-MM-DD
**Done:** <one-line summary of what was accomplished>
**Next:** <one-line summary of what to do next>
**Blockers:** <none | describe blockers>
```

---

## Reading a Previous Summary

At session start, the agent should:

```bash
# Find the most recent summary for a label
ls -t .claude/sessions/*<label>*.md | head -1

# Read it
cat .claude/sessions/2026-02-28-forge-auth.md
```

Or from within an agent prompt:

```markdown
## Session Resume Instructions
1. Run: ls -t .claude/sessions/ | head -5
2. Find the most recent file matching your session label
3. Read that file
4. Begin your session with that context loaded
```

---

## Multi-Session Example

```
.claude/sessions/
├── 2026-02-26-forge-auth.md    ← Day 1: set up skeleton
├── 2026-02-27-forge-auth.md    ← Day 2: JWT impl
└── 2026-02-28-forge-auth.md    ← Day 3: OAuth (read THIS one to resume)
```

Each day's summary builds on the previous. The next agent reads only the latest.
