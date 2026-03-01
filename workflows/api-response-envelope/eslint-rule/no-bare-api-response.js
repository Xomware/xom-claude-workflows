/**
 * ESLint Custom Rule: no-bare-api-response
 *
 * Warns when a route handler calls res.json() or res.send() with an object
 * that does not contain a `success` property — i.e., the response is not
 * wrapped in the Xomware API response envelope.
 *
 * See: workflows/api-response-envelope/WORKFLOW.md
 *
 * Installation:
 *   // eslint.config.js
 *   const noBareApiResponse = require('<path>/eslint-rule/no-bare-api-response');
 *
 *   module.exports = {
 *     plugins: { xomware: { rules: { 'no-bare-api-response': noBareApiResponse } } },
 *     rules: { 'xomware/no-bare-api-response': 'warn' },
 *   };
 *
 * Examples:
 *   // ❌ Warns:
 *   res.json({ id: user.id, email: user.email });
 *   res.send({ message: 'ok' });
 *
 *   // ✅ OK:
 *   res.json({ success: true, data: user });
 *   res.json({ success: false, error: 'Not found' });
 *   res.json(apiSuccess(user));   // variable — not flagged (can't statically check)
 */

'use strict';

/** @type {import('eslint').Rule.RuleModule} */
module.exports = {
  meta: {
    type: 'suggestion',
    docs: {
      description:
        'Require all res.json() / res.send() calls to use the Xomware API response envelope ({ success, data?, error? })',
      category: 'Best Practices',
      recommended: true,
      url: 'https://github.com/Xomware/xom-claude-workflows/blob/main/workflows/api-response-envelope/WORKFLOW.md',
    },
    messages: {
      missingEnvelope:
        'API response must use the Xomware envelope: { success: boolean, data?, error? }. ' +
        'Found res.{{method}}() without a `success` property. ' +
        'Wrap with apiSuccess(data) or apiError(message).',
    },
    schema: [
      {
        type: 'object',
        properties: {
          // Additional method names to check beyond json/send
          methods: {
            type: 'array',
            items: { type: 'string' },
            default: ['json', 'send'],
          },
          // Object names that are always treated as response objects (default: res, reply)
          responseObjects: {
            type: 'array',
            items: { type: 'string' },
            default: ['res', 'reply', 'response'],
          },
        },
        additionalProperties: false,
      },
    ],
  },

  create(context) {
    const options = context.options[0] || {};
    const checkedMethods = new Set(options.methods || ['json', 'send']);
    const responseObjectNames = new Set(
      options.responseObjects || ['res', 'reply', 'response']
    );

    /**
     * Returns true if the ObjectExpression node has a property named `success`.
     * @param {import('estree').ObjectExpression} node
     */
    function hasSuccessProperty(node) {
      return node.properties.some((prop) => {
        if (prop.type === 'SpreadElement') {
          // Can't statically verify spread — give benefit of the doubt
          return true;
        }
        const keyName =
          prop.key.type === 'Identifier'
            ? prop.key.name
            : prop.key.type === 'Literal'
            ? String(prop.key.value)
            : null;
        return keyName === 'success';
      });
    }

    return {
      CallExpression(node) {
        // Match: <responseObject>.<method>(...)
        if (
          node.callee.type !== 'MemberExpression' ||
          node.callee.computed
        ) {
          return;
        }

        const object = node.callee.object;
        const property = node.callee.property;

        // Check the receiver name (res, reply, etc.)
        const objectName =
          object.type === 'Identifier' ? object.name : null;
        if (!objectName || !responseObjectNames.has(objectName)) {
          return;
        }

        // Check the method name (json, send, etc.)
        const methodName =
          property.type === 'Identifier' ? property.name : null;
        if (!methodName || !checkedMethods.has(methodName)) {
          return;
        }

        // Inspect the first argument
        const [firstArg] = node.arguments;
        if (!firstArg) return;

        // If the argument is an inline object literal, check for `success`
        if (firstArg.type === 'ObjectExpression') {
          if (!hasSuccessProperty(firstArg)) {
            context.report({
              node: firstArg,
              messageId: 'missingEnvelope',
              data: { method: methodName },
            });
          }
        }
        // All other argument types (variables, function calls) are skipped —
        // we trust the developer used the envelope helpers.
      },
    };
  },
};
