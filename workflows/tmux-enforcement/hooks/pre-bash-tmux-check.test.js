#!/usr/bin/env node
/**
 * Unit tests for pre-bash-tmux-check.js
 *
 * Tests the pattern matching logic without spawning full hook processes.
 * Run with: node pre-bash-tmux-check.test.js
 */

const { execSync } = require('child_process');
const path = require('path');

// ─── Helpers ──────────────────────────────────────────────────────────────────

const HOOK = path.join(__dirname, 'pre-bash-tmux-check.js');
let passed = 0;
let failed = 0;

/**
 * Run the hook with a given command string and TMUX env var.
 * Returns the exit code.
 */
function runHook(command, tmuxEnv = '') {
  const input = JSON.stringify({ tool_input: { command } });
  const envFlag = tmuxEnv ? `TMUX=${tmuxEnv}` : 'env -u TMUX';
  try {
    execSync(`echo '${input.replace(/'/g, "'\\''")}' | ${envFlag} node ${HOOK}`, {
      stdio: 'pipe',
    });
    return 0;
  } catch (err) {
    return err.status;
  }
}

function assert(description, actual, expected) {
  if (actual === expected) {
    console.log(`  ✅ PASS: ${description}`);
    passed++;
  } else {
    console.error(`  ❌ FAIL: ${description}`);
    console.error(`         Expected exit ${expected}, got exit ${actual}`);
    failed++;
  }
}

// ─── Tests ────────────────────────────────────────────────────────────────────

console.log('\n=== pre-bash-tmux-check hook tests ===\n');

// --- Blocked outside tmux ---
console.log('Blocked commands (no TMUX):');
assert('npm run dev blocked',          runHook('npm run dev'),               2);
assert('pnpm dev blocked',             runHook('pnpm dev'),                  2);
assert('yarn dev blocked',             runHook('yarn dev'),                  2);
assert('bun run dev blocked',          runHook('bun run dev'),               2);
assert('manage.py runserver blocked',  runHook('./manage.py runserver'),      2);
assert('uvicorn blocked',              runHook('uvicorn app:main --reload'),  2);
assert('fastapi run blocked',          runHook('fastapi run main.py'),        2);
assert('next dev blocked',             runHook('next dev'),                   2);
assert('vite blocked',                 runHook('vite'),                       2);
assert('webpack-dev-server blocked',   runHook('webpack-dev-server'),         2);

// --- Allowed inside tmux ---
console.log('\nAllowed commands (inside TMUX):');
assert('npm run dev allowed in tmux',  runHook('npm run dev', '/tmp/tmux-1000/default,12345,0'), 0);
assert('pnpm dev allowed in tmux',     runHook('pnpm dev',    '/tmp/tmux-1000/default,12345,0'), 0);
assert('uvicorn allowed in tmux',      runHook('uvicorn app:main', '/tmp/tmux'), 0);

// --- Non-dev-server commands always allowed ---
console.log('\nNon-dev-server commands (always allowed):');
assert('npm install allowed',          runHook('npm install'),               0);
assert('npm run build allowed',        runHook('npm run build'),             0);
assert('npm run test allowed',         runHook('npm run test'),              0);
assert('git status allowed',           runHook('git status'),                0);
assert('ls -la allowed',               runHook('ls -la'),                    0);
assert('echo hello allowed',           runHook('echo hello'),                0);
assert('python script.py allowed',     runHook('python script.py'),          0);
assert('node index.js allowed',        runHook('node index.js'),             0);
assert('docker build allowed',         runHook('docker build .'),            0);

// --- Edge cases ---
console.log('\nEdge cases:');
assert('Empty command allowed',        runHook(''),                          0);
assert('npm run develop (not dev)',     runHook('npm run develop'),           0);
// "vite" in a path (not a bare command) — still matches substring, which is expected
assert('vitejs mentioned in comment',  runHook('# using vite for bundling'), 2); // substring match

// ─── Summary ──────────────────────────────────────────────────────────────────

console.log(`\n=== Results: ${passed} passed, ${failed} failed ===\n`);
process.exit(failed > 0 ? 1 : 0);
