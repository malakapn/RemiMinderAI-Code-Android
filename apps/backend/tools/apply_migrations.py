from __future__ import annotations

import logging
from pathlib import Path

from sqlalchemy import text

from services.cloud_sql_engine import get_cloud_sql_engine

MIGRATIONS_DIR = Path(__file__).resolve().parents[1] / "schemas" / "migrations"
logger = logging.getLogger(__name__)

# Session-scoped key so concurrent Cloud Run / uvicorn workers coordinate safely.
MIGRATION_ADVISORY_LOCK_KEY = 842_060_719


def _ensure_schema_migrations_table() -> None:
    engine = get_cloud_sql_engine()
    with engine.begin() as conn:
        conn.exec_driver_sql(
            """
            CREATE TABLE IF NOT EXISTS public.schema_migrations (
                filename TEXT PRIMARY KEY
            )
            """
        )


def apply_migrations() -> None:
    """
    Apply any *.sql files in schemas/migrations that are not yet recorded in schema_migrations.

    Uses pg_try_advisory_lock so only one concurrent process runs migrations; others skip quickly.
    """
    migration_files = sorted(MIGRATIONS_DIR.glob("*.sql"))
    if not migration_files:
        raise RuntimeError(f"No migration files found in {MIGRATIONS_DIR}")

    _ensure_schema_migrations_table()
    engine = get_cloud_sql_engine()

    with engine.connect() as conn:
        got = conn.execute(
            text("SELECT pg_try_advisory_lock(:k)"),
            {"k": MIGRATION_ADVISORY_LOCK_KEY},
        ).scalar()
        # End implicit transaction so a clean conn.begin() can run the migration batch.
        conn.commit()
        if not got:
            logger.info(
                "Skipping migrations: advisory lock held by another process "
                "(expected when multiple instances start together)."
            )
            return
        try:
            with conn.begin():
                applied_rows = conn.exec_driver_sql(
                    "SELECT filename FROM schema_migrations;"
                ).fetchall()
                applied = {row[0] for row in applied_rows}

                for migration_file in migration_files:
                    if migration_file.name in applied:
                        continue
                    sql = migration_file.read_text()
                    if not sql.strip():
                        continue
                    conn.exec_driver_sql(sql)
                    conn.exec_driver_sql(
                        "INSERT INTO schema_migrations(filename) VALUES (%(filename)s)",
                        {"filename": migration_file.name},
                    )
                    logger.info("Applied migration %s", migration_file.name)
        finally:
            conn.execute(
                text("SELECT pg_advisory_unlock(:k)"),
                {"k": MIGRATION_ADVISORY_LOCK_KEY},
            )
            conn.commit()


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    apply_migrations()
