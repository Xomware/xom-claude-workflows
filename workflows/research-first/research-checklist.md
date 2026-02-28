# Research Checklist

Run this before starting any new feature, module, or significant dependency.

---

## Pre-Implementation Checklist

### 1. Problem Definition
- [ ] I can describe the problem in one paragraph without mentioning a solution
- [ ] I've confirmed this isn't already solved by existing code in our codebase
- [ ] I've checked if an existing dependency we already use could cover this

### 2. GitHub Search
- [ ] Searched GitHub for existing implementations (`gh search repos`)
- [ ] Reviewed top 3 results: checked stars, last commit, license, README quality
- [ ] Noted the best candidate or confirmed nothing suitable exists

### 3. Package Registry Search
- [ ] Checked npm/PyPI/Cargo/pkg.go.dev as applicable
- [ ] Reviewed top 3 packages: weekly downloads, maintenance status, issue tracker health
- [ ] Checked if any existing dependency in our project can be extended to cover this

### 4. Platform / Framework Docs
- [ ] Checked if the framework/platform we use has native support
- [ ] Checked changelog for recent versions of dependencies we already have
- [ ] Searched official docs and release notes

### 5. Decision
- [ ] Identified my preferred approach (adopt / fork / build / buy)
- [ ] Can articulate why I'm not using the best existing solution (or why there isn't one)
- [ ] Created a decision record (see `WORKFLOW.md` Step 5 template)

---

## Decision Gate

Answer these before writing code:

| Question | Answer |
|----------|--------|
| What problem am I solving? | |
| What did I find in my research? | |
| Why am I not using `<best existing option>`? | |
| What's the expected maintenance burden of my choice? | |

If you can't fill in the "Why not" row, stop and re-evaluate.

---

## Time Budget

| Step | Time Box |
|------|----------|
| GitHub search | 15 min |
| Package registry search | 20 min |
| Docs/web search | 15 min |
| Evaluation + decision record | 10 min |
| **Total** | **~60 min** |

One hour of research can save weeks of implementation and months of maintenance.

---

## Escalation

If after 60 minutes you're unsure, don't just start building. Options:
1. Post your findings in the relevant GitHub issue and ask for input
2. Consult a teammate who knows this domain
3. Spawn a `claude-research` session with your notes for deeper analysis

Never start building from uncertainty if you had less than 45 minutes of research time.
