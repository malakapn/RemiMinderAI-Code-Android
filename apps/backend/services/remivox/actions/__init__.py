"""Action Layer: execute backend operations."""

from services.remivox.actions.types import ActionResult

__all__ = ["ActionResult", "execute_intent"]


def __getattr__(name: str):
    if name == "execute_intent":
        from services.remivox.actions.executor import execute_intent

        return execute_intent
    raise AttributeError(f"module {__name__!r} has no attribute {name!r}")
