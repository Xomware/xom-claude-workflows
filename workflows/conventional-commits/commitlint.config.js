// commitlint.config.js — Xomware Conventional Commits configuration
//
// Install:
//   npm install --save-dev @commitlint/cli @commitlint/config-conventional
//   cp <xom-claude-workflows>/workflows/conventional-commits/commitlint.config.js commitlint.config.js
//
// Run:
//   npx commitlint --from HEAD~1 --to HEAD
//
// Docs: https://commitlint.js.org/

/** @type {import('@commitlint/types').UserConfig} */
module.exports = {
  extends: ['@commitlint/config-conventional'],

  rules: {
    // ── Type ────────────────────────────────────────────────────────────────
    'type-enum': [
      2, // error
      'always',
      [
        'feat',
        'fix',
        'refactor',
        'docs',
        'test',
        'chore',
        'perf',
        'ci',
        'build',
        'revert',
      ],
    ],
    'type-case': [2, 'always', 'lower-case'],
    'type-empty': [2, 'never'],

    // ── Scope ───────────────────────────────────────────────────────────────
    'scope-case': [2, 'always', 'lower-case'],

    // ── Subject / Description ────────────────────────────────────────────────
    'subject-empty': [2, 'never'],
    'subject-full-stop': [2, 'never', '.'],
    'subject-case': [2, 'always', 'lower-case'],
    'subject-min-length': [2, 'always', 10],

    // ── Header ──────────────────────────────────────────────────────────────
    'header-max-length': [2, 'always', 100],

    // ── Body ────────────────────────────────────────────────────────────────
    'body-max-line-length': [1, 'always', 72], // warn, not error

    // ── Footer ──────────────────────────────────────────────────────────────
    'footer-max-line-length': [1, 'always', 72],
  },
};
