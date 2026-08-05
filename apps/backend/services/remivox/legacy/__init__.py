"""
Legacy RemiVox care path (pre–v2 Intent Router).

Stage E: production /api/remivox/ask uses remivox.pipeline.run_care_turn.
This package retains handle_prompt for rollback and regression tests only.
Do not wire it back into production routes.
"""

from services.remivox.legacy.handle_prompt import handle_prompt

__all__ = ["handle_prompt"]
