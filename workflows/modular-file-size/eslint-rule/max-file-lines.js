/**
 * ESLint Custom Rule: max-file-lines
 *
 * Warns when a source file exceeds 600 lines.
 * Errors when a source file exceeds 800 lines.
 *
 * See: workflows/modular-file-size/WORKFLOW.md
 *
 * Installation:
 *   // eslint.config.js
 *   const maxFileLines = require('<path>/eslint-rule/max-file-lines');
 *
 *   module.exports = {
 *     plugins: { xomware: { rules: { 'max-file-lines': maxFileLines } } },
 *     rules: {
 *       'xomware/max-file-lines': ['error', { warn: 600, error: 800 }],
 *     },
 *   };
 */

'use strict';

const DEFAULT_WARN_LINES = 600;
const DEFAULT_ERROR_LINES = 800;

/** @type {import('eslint').Rule.RuleModule} */
module.exports = {
  meta: {
    type: 'suggestion',
    docs: {
      description: 'Limit the number of lines in a source file to encourage modularity',
      category: 'Best Practices',
      recommended: true,
      url: 'https://github.com/Xomware/xom-claude-workflows/blob/main/workflows/modular-file-size/WORKFLOW.md',
    },
    messages: {
      tooManyLinesError:
        'File has {{lineCount}} lines, which exceeds the maximum of {{limit}}. ' +
        'Split this file into smaller, single-responsibility modules. ' +
        'See: workflows/modular-file-size/refactoring-guide.md',
      tooManyLinesWarn:
        'File has {{lineCount}} lines, which exceeds the recommended maximum of {{limit}}. ' +
        'Consider splitting this file into smaller modules. ' +
        'See: workflows/modular-file-size/refactoring-guide.md',
    },
    schema: [
      {
        type: 'object',
        properties: {
          /** Line count at which a warning is reported (default: 600) */
          warn: {
            type: 'integer',
            minimum: 1,
            default: DEFAULT_WARN_LINES,
          },
          /** Line count at which an error is reported (default: 800) */
          error: {
            type: 'integer',
            minimum: 1,
            default: DEFAULT_ERROR_LINES,
          },
          /**
           * Whether to skip counting blank lines and single-line comments.
           * When true, only "logical" lines are counted.
           * Default: false (count all lines)
           */
          skipBlankLines: {
            type: 'boolean',
            default: false,
          },
          skipComments: {
            type: 'boolean',
            default: false,
          },
        },
        additionalProperties: false,
      },
    ],
  },

  create(context) {
    const options = context.options[0] || {};
    const warnLimit = options.warn ?? DEFAULT_WARN_LINES;
    const errorLimit = options.error ?? DEFAULT_ERROR_LINES;
    const skipBlankLines = options.skipBlankLines ?? false;
    const skipComments = options.skipComments ?? false;

    if (warnLimit >= errorLimit) {
      throw new Error(
        `max-file-lines: 'warn' limit (${warnLimit}) must be less than 'error' limit (${errorLimit})`
      );
    }

    return {
      Program(node) {
        const sourceCode = context.getSourceCode ? context.getSourceCode() : context.sourceCode;
        const lines = sourceCode.lines;
        let lineCount = lines.length;

        if (skipBlankLines || skipComments) {
          // Build a set of comment line numbers
          const commentLines = new Set();
          if (skipComments) {
            for (const comment of sourceCode.getAllComments()) {
              const start = comment.loc.start.line;
              const end = comment.loc.end.line;
              for (let l = start; l <= end; l++) {
                commentLines.add(l);
              }
            }
          }

          lineCount = 0;
          lines.forEach((line, idx) => {
            const lineNo = idx + 1; // 1-indexed
            const isBlank = skipBlankLines && line.trim() === '';
            const isComment = skipComments && commentLines.has(lineNo);
            if (!isBlank && !isComment) {
              lineCount++;
            }
          });
        }

        if (lineCount > errorLimit) {
          context.report({
            node,
            messageId: 'tooManyLinesError',
            data: { lineCount, limit: errorLimit },
          });
        } else if (lineCount > warnLimit) {
          context.report({
            node,
            messageId: 'tooManyLinesWarn',
            data: { lineCount, limit: warnLimit },
          });
        }
      },
    };
  },
};
