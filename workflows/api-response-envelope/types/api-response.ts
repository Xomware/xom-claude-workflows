/**
 * Xomware Standard API Response Envelope
 *
 * All HTTP API responses MUST be wrapped in this envelope.
 *
 * @see workflows/api-response-envelope/WORKFLOW.md
 */

// ── Core envelope ─────────────────────────────────────────────────────────────

export interface ApiResponse<T = unknown> {
  /** true on success (2xx), false on error */
  success: boolean;
  /** Payload for successful responses */
  data?: T;
  /** Human-readable error message for failed responses */
  error?: string;
}

// ── Discriminated union variants ──────────────────────────────────────────────

export interface ApiSuccessResponse<T = unknown> extends ApiResponse<T> {
  success: true;
  data: T;
  error?: never;
}

export interface ApiErrorResponse extends ApiResponse<never> {
  success: false;
  data?: never;
  error: string;
}

// ── Paginated data wrapper ────────────────────────────────────────────────────

export interface PaginatedData<T> {
  items: T[];
  total: number;
  page: number;
  pageSize: number;
}

export type PaginatedApiResponse<T> = ApiSuccessResponse<PaginatedData<T>>;

// ── Helper factories ──────────────────────────────────────────────────────────

/**
 * Build a successful API response.
 *
 * @example
 * res.json(apiSuccess(user));
 * // { success: true, data: { id: 'usr_1', email: '...' } }
 */
export function apiSuccess<T>(data: T): ApiSuccessResponse<T> {
  return { success: true, data };
}

/**
 * Build an error API response.
 *
 * @example
 * res.status(400).json(apiError('Email is required'));
 * // { success: false, error: 'Email is required' }
 */
export function apiError(message: string): ApiErrorResponse {
  return { success: false, error: message };
}

/**
 * Build a paginated API response.
 *
 * @example
 * res.json(apiPaginated(users, { total: 245, page: 1, pageSize: 20 }));
 */
export function apiPaginated<T>(
  items: T[],
  meta: Omit<PaginatedData<T>, 'items'>
): PaginatedApiResponse<T> {
  return { success: true, data: { items, ...meta } };
}

// ── Type guards ───────────────────────────────────────────────────────────────

export function isApiSuccess<T>(
  response: ApiResponse<T>
): response is ApiSuccessResponse<T> {
  return response.success === true;
}

export function isApiError(response: ApiResponse): response is ApiErrorResponse {
  return response.success === false;
}
