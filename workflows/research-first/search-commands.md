# Search Commands Reference

Curated search commands for research-first development. Copy-paste these; replace `<keywords>` with your specific terms.

---

## GitHub

```bash
# Search repos by keyword, sorted by stars
gh search repos "<keywords>" --sort stars --limit 20

# Filter by language
gh search repos "<keywords>" --language typescript --sort stars --limit 10

# Search only recently updated repos (active maintenance signal)
gh search repos "<keywords>" --sort updated --limit 10

# Search code across GitHub (find implementations)
gh search code "<function or class name>" --language python

# Search issues for workarounds and discussions
gh search issues "<problem description>" --limit 10

# Search PRs (find merged solutions)
gh search prs "<feature name>" --state merged --limit 10

# Check a specific repo's issues for known problems
gh issue list --repo <owner>/<repo> --label bug --state open --limit 20

# Check how active a repo is
gh repo view <owner>/<repo> --json pushedAt,stargazerCount,openIssues,forkCount
```

---

## npm (Node.js / TypeScript)

```bash
# Search npm registry
npm search <keywords> --parseable | head -20

# Get package details (downloads, dependencies, latest version)
npm info <package-name> description version weeklyDownloads

# Check download stats via npx
npx npm-stat <package-name>

# Find alternatives to a known package
npm search "keywords:<tag-from-package-json>"

# Audit what we already have (may already cover the need)
npm list --depth=0
cat package.json | jq '.dependencies,.devDependencies'

# Check bundle size before adopting
npx bundlephobia <package-name>

# Check for security advisories
npm audit --dry-run
npm info <package-name> | grep -i deprecated
```

---

## PyPI (Python)

```bash
# Search PyPI (use pip search or the website: https://pypi.org/search/?q=<keywords>)
pip search <keywords> 2>/dev/null || echo "Use: https://pypi.org/search/?q=<keywords>"

# Get package info
pip show <package-name>
pip index versions <package-name>

# Check if already installed / available
pip list | grep -i <keyword>

# Inspect a package without installing
pip download <package-name> --no-deps -d /tmp/pkg && unzip -l /tmp/pkg/*.whl

# Check stats on PyPI Stats: https://pypistats.org/packages/<package-name>
curl -s "https://pypistats.org/api/packages/<package-name>/recent" | python3 -m json.tool
```

---

## Go

```bash
# Search on pkg.go.dev (use browser or curl)
open "https://pkg.go.dev/search?q=<keywords>"

# Check if a module is importable
go list -m golang.org/x/...

# View module info
go list -m -json <module-path>@latest

# Find what packages are already in your module graph
go list -m all | grep <keyword>

# Check module size and dependency count
go mod graph | grep <package> | wc -l
```

---

## Rust / Cargo

```bash
# Search crates.io
cargo search <keywords> --limit 10

# Get crate details
cargo info <crate-name>  # newer cargo versions

# Check downloads and metadata
curl -s "https://crates.io/api/v1/crates/<crate-name>" | jq '.crate | {downloads,recent_downloads,max_version,updated_at}'

# Show features available in a crate
cargo add <crate-name> --dry-run
```

---

## Web / Documentation Searches

Use these search patterns in your browser or with `curl`/`jq`:

```bash
# Search Stack Overflow via API
open "https://api.stackexchange.com/2.3/search?order=desc&sort=votes&intitle=<encoded-query>&site=stackoverflow"

# Find GitHub topics
open "https://github.com/topics/<topic-keyword>"

# Awesome lists (curated alternatives)
gh search repos "awesome-<keyword>" --sort stars --limit 5

# Find CNCF / Linux Foundation projects in a space
open "https://landscape.cncf.io/?category=<category>"

# Check a library's release cadence
gh api /repos/<owner>/<repo>/releases --jq '.[0:5] | .[] | {tag_name, published_at}'
```

---

## Evaluating a Candidate (Quick Health Check)

Run this block for any serious candidate:

```bash
REPO="<owner>/<repo>"
echo "=== Health Check: $REPO ==="
gh repo view $REPO --json stargazerCount,forkCount,openIssues,pushedAt,licenseInfo \
  --jq '{stars: .stargazerCount, forks: .forkCount, open_issues: .openIssues, last_push: .pushedAt, license: .licenseInfo.name}'
echo ""
echo "=== Recent releases ==="
gh api /repos/$REPO/releases --jq '.[0:3] | .[] | {tag: .tag_name, date: .published_at}'
echo ""
echo "=== Recent commits ==="
gh api /repos/$REPO/commits --jq '.[0:3] | .[] | {sha: .sha[0:7], message: .commit.message[0:80], date: .commit.committer.date}'
```

Green flags: stars >500, last push <3 months, has recent releases, active issue responses.
Red flags: last commit >1 year, hundreds of open bugs, no releases in 2+ years, archived.
