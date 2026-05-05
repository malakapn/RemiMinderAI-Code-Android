import logging
import os
from typing import Optional

from sqlalchemy import create_engine, Engine, text
from sqlalchemy.engine import URL
from sqlalchemy.pool import QueuePool

logger = logging.getLogger(__name__)

# Global variable to cache the engine (lazy initialization)
_cloud_sql_engine: Optional[Engine] = None

def get_cloud_sql_engine() -> Engine:
    """Lazy initialization of Cloud SQL PostgreSQL engine."""
    global _cloud_sql_engine
    if _cloud_sql_engine is not None:
        return _cloud_sql_engine

    # Read environment variables at runtime (not import time)
    db_host = os.getenv("DB_HOST")
    db_port = os.getenv("DB_PORT")
    db_name = os.getenv("DB_NAME")
    db_user = os.getenv("DB_USER")
    db_password = os.getenv("DB_PASSWORD")

    # Check if all required environment variables are set
    missing_vars = []
    if not db_host:
        missing_vars.append("DB_HOST")
    if not db_port:
        missing_vars.append("DB_PORT")
    if not db_name:
        missing_vars.append("DB_NAME")
    if not db_user:
        missing_vars.append("DB_USER")
    if not db_password:
        missing_vars.append("DB_PASSWORD")

    if missing_vars:
        raise RuntimeError(
            f"Cloud SQL engine not initialized. Missing environment variables: {', '.join(missing_vars)}. "
            "Set DB_HOST, DB_PORT, DB_NAME, DB_USER, and DB_PASSWORD for Cloud SQL connection."
        )

    db_sslmode = os.getenv("DB_SSLMODE", "prefer")

    try:
        # Create database URL using SQLAlchemy URL.create() to safely handle special characters
        database_url = URL.create(
            drivername="postgresql",
            username=db_user,
            password=db_password,
            host=db_host,
            port=db_port,
            database=db_name
        )

        # Create engine with connection pooling
        _cloud_sql_engine = create_engine(
            database_url,
            poolclass=QueuePool,
            pool_size=5,
            max_overflow=10,
            pool_timeout=30,
            pool_recycle=3600,  # Recycle connections every hour
            echo=False,  # Set to True for SQL debugging
            connect_args={
                "connect_timeout": 10,
                "application_name": "MediMinder-Backend",
                "sslmode": db_sslmode
            }
        )

        # Test the connection
        with _cloud_sql_engine.connect() as conn:
            conn.execute(text("SELECT 1"))
            logger.info("Cloud SQL PostgreSQL connection established successfully")

        return _cloud_sql_engine

    except Exception as e:
        logger.error(f"Failed to initialize Cloud SQL engine: {e}")
        raise RuntimeError(f"Cloud SQL engine initialization failed: {e}")

def is_cloud_sql_available() -> bool:
    """Check if Cloud SQL connection is available and configured."""
    try:
        get_cloud_sql_engine()
        return True
    except (RuntimeError, Exception):
        return False
