# API Response Envelope — Xomware Standard

## Overview

Every HTTP API response at Xomware **must** be wrapped in a structured envelope. This guarantees consistent shape across all services, simplifying client code, error handling, and logging.

---

## The Envelope Shape

```typescript
interface ApiResponse<T = unknown> {
  success: boolean;   // true on 2xx, false on error
  data?: T;           // payload on success
  error?: string;     // human-readable message on failure
}
```

### Rules

| Field | Success | Error |
|-------|---------|-------|
| `success` | `true` | `false` |
| `data` | present (may be `null` or `{}` for empty) | omitted |
| `error` | omitted | present (non-empty string) |

---

## Examples

### ✅ Successful response

```json
HTTP 200 OK
{
  "success": true,
  "data": {
    "id": "usr_123",
    "email": "dom@xomware.com"
  }
}
```

### ✅ Success with empty data

```json
HTTP 204 No Content (or 200)
{
  "success": true,
  "data": null
}
```

### ✅ Error response

```json
HTTP 400 Bad Request
{
  "success": false,
  "error": "Email address is required"
}
```

### ✅ Server error response

```json
HTTP 500 Internal Server Error
{
  "success": false,
  "error": "An unexpected error occurred. Please try again."
}
```

### ❌ Bare response (not allowed)

```json
{
  "id": "usr_123",
  "email": "dom@xomware.com"
}
```

### ❌ Non-standard error (not allowed)

```json
{
  "message": "Email required",
  "code": 400
}
```

---

## Implementation

### TypeScript

```typescript
import { ApiResponse } from './types/api-response';

// Express example
app.get('/users/:id', async (req, res) => {
  try {
    const user = await getUser(req.params.id);
    res.json({ success: true, data: user } satisfies ApiResponse<User>);
  } catch (err) {
    res.status(500).json({ success: false, error: 'Failed to retrieve user' } satisfies ApiResponse);
  }
});
```

### Python (FastAPI example)

```python
from types.api_response import ApiResponse

@router.get("/users/{user_id}")
async def get_user(user_id: str) -> ApiResponse:
    try:
        user = await fetch_user(user_id)
        return ApiResponse(success=True, data=user)
    except Exception:
        return ApiResponse(success=False, error="Failed to retrieve user")
```

---

## ESLint Enforcement

The `eslint-rule/no-bare-api-response.js` rule will **warn** when a route handler calls `res.json()` or `res.send()` with an object that does not contain a `success` key.

Install in your ESLint config:

```js
// eslint.config.js or .eslintrc.js
const noBareApiResponse = require('<xom-claude-workflows>/workflows/api-response-envelope/eslint-rule/no-bare-api-response');

module.exports = {
  plugins: {
    xomware: { rules: { 'no-bare-api-response': noBareApiResponse } },
  },
  rules: {
    'xomware/no-bare-api-response': 'warn',
  },
};
```

---

## HTTP Status Code Guidance

| Scenario | HTTP Status | `success` |
|----------|-------------|-----------|
| Resource fetched | 200 | `true` |
| Resource created | 201 | `true` |
| Action succeeded, no body | 204 | `true` (or no body) |
| Bad request / validation | 400 | `false` |
| Unauthorized | 401 | `false` |
| Forbidden | 403 | `false` |
| Not found | 404 | `false` |
| Server error | 500 | `false` |

---

## Pagination

For paginated responses, extend the `data` field:

```typescript
interface PaginatedResponse<T> {
  items: T[];
  total: number;
  page: number;
  pageSize: number;
}

// Example:
{
  "success": true,
  "data": {
    "items": [...],
    "total": 245,
    "page": 1,
    "pageSize": 20
  }
}
```

---

*Maintained by Xomware Engineering. Questions? Open an issue in xom-claude-workflows.*
