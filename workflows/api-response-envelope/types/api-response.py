"""
Xomware Standard API Response Envelope — Python

All HTTP API responses MUST be wrapped in this envelope.

See: workflows/api-response-envelope/WORKFLOW.md

Compatible with:
  - FastAPI (pydantic models)
  - Flask / Django (via .dict() serialisation)
  - Standard dicts (use ApiResponseDict)
"""

from __future__ import annotations

from typing import Generic, Optional, TypeVar

# ── Pydantic v2 (preferred for FastAPI) ───────────────────────────────────────
try:
    from pydantic import BaseModel

    T = TypeVar("T")

    class ApiResponse(BaseModel, Generic[T]):
        """
        Xomware standard API response envelope.

        Usage::

            @router.get("/users/{user_id}")
            async def get_user(user_id: str) -> ApiResponse:
                try:
                    user = await fetch_user(user_id)
                    return ApiResponse.ok(user)
                except NotFoundException:
                    return ApiResponse.fail("User not found")
        """

        success: bool
        data: Optional[T] = None
        error: Optional[str] = None

        model_config = {"populate_by_name": True}

        @classmethod
        def ok(cls, data: T) -> "ApiResponse[T]":
            """Build a successful response."""
            return cls(success=True, data=data)

        @classmethod
        def fail(cls, error: str) -> "ApiResponse":
            """Build an error response."""
            return cls(success=False, error=error)

        @property
        def is_success(self) -> bool:
            return self.success is True

        @property
        def is_error(self) -> bool:
            return self.success is False

except ImportError:
    # Pydantic not available — fall back to dataclass implementation
    pass


# ── Dataclass implementation (no external deps) ───────────────────────────────
from dataclasses import dataclass, field, asdict
from typing import Any

T_co = TypeVar("T_co", covariant=True)


@dataclass
class ApiResponseDC:
    """
    Dependency-free dataclass version of ApiResponse.

    Usage::

        from api_response import api_ok, api_error

        def get_user(user_id: str) -> dict:
            try:
                user = fetch_user(user_id)
                return asdict(api_ok(user))
            except Exception:
                return asdict(api_error("User not found"))
    """

    success: bool
    data: Any = field(default=None)
    error: Optional[str] = field(default=None)

    def to_dict(self) -> dict:
        result: dict = {"success": self.success}
        if self.data is not None:
            result["data"] = self.data
        if self.error is not None:
            result["error"] = self.error
        return result


# ── Helper factories ──────────────────────────────────────────────────────────

def api_ok(data: Any) -> ApiResponseDC:
    """
    Build a successful API response.

    Example::

        return api_ok({"id": "usr_1", "email": "dom@xomware.com"}).to_dict()
        # {"success": True, "data": {"id": "usr_1", "email": "dom@xomware.com"}}
    """
    return ApiResponseDC(success=True, data=data)


def api_error(message: str) -> ApiResponseDC:
    """
    Build an error API response.

    Example::

        return api_error("Email is required").to_dict()
        # {"success": False, "error": "Email is required"}
    """
    return ApiResponseDC(success=False, error=message)


# ── TypedDict for strict dict typing ─────────────────────────────────────────
from typing import TypedDict


class ApiResponseDict(TypedDict, total=False):
    """TypedDict version for use in type-checked dict contexts."""
    success: bool  # required
    data: Any
    error: str
