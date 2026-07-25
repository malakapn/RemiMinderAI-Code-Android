
"""
IMPORTANT:

This backend uses a background job worker for long-running tasks (STT + AI summary).

To fully run the system locally, you MUST run:

1) Backend API:
   uvicorn main:app --reload

2) Worker process (in a separate terminal):
   python -m workers.stt_worker

If the worker is not running, audio uploads will succeed but summaries will NEVER be generated.

When Cloud SQL env vars are set, SQL migrations in schemas/migrations/ run automatically on API
startup (see lifespan). Set SKIP_DB_MIGRATIONS=true to disable (e.g. local tests without DB).
"""
import asyncio
import logging
import os
import sys
from contextlib import asynccontextmanager

from dotenv import load_dotenv

logger = logging.getLogger(__name__)

# Explicitly load .env from backend directory
env_path = os.path.join(os.path.dirname(__file__), ".env")
try:
    load_dotenv(env_path)
except (FileNotFoundError, PermissionError):
    logger.warning(f"Could not load .env file from {env_path}. Make sure environment variables are set.")

# Verify critical environment variables are loaded
required_vars = ["GCS_BUCKET_NAME"]
for var in required_vars:
    if not os.getenv(var):
        raise RuntimeError(f"Critical environment variable {var} is not set. Check your .env file.")

# Check Cloud SQL environment variables (optional for read-only testing)
cloud_sql_vars = ["DB_HOST", "DB_PORT", "DB_NAME", "DB_USER", "DB_PASSWORD"]
cloud_sql_configured = all(os.getenv(var) for var in cloud_sql_vars)

if cloud_sql_configured:
    logger.info("Cloud SQL PostgreSQL environment variables loaded (read-only connection available)")
else:
    logger.info("Cloud SQL PostgreSQL environment variables not set (optional for read-only testing)")

logger.info("Database provider: Cloud SQL")

logger.info("Environment variables verified")

# Ensure backend package paths are preferred (avoid shadowing by legacy modules).
backend_dir = os.path.dirname(__file__)
if backend_dir not in sys.path:
    sys.path.insert(0, backend_dir)
sys.path = [
    path for path in sys.path
    if "phase1/backend/main_backend" not in path.replace("\\", "/")
]
sys.path.append('..')

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from route import care_team, caregiver_notes, internal_cron, patient_tasks, reminders, remivox, subscription, visit_summary, users
# DISABLED: Other routes temporarily disabled to focus on audio + STT features
# from route import invitations, patient_register, caregiver_patient, caregivers
# DISABLED: Reminders temporarily disabled due to Supabase dependency cleanup
# from route import reminders


def _run_db_migrations() -> None:
    from tools.apply_migrations import apply_migrations

    apply_migrations()


@asynccontextmanager
async def lifespan(app: FastAPI):
    skip = os.getenv("SKIP_DB_MIGRATIONS", "").strip().lower() in ("1", "true", "yes")
    if skip:
        logger.info("SKIP_DB_MIGRATIONS is set; skipping automatic SQL migrations on startup.")
    elif cloud_sql_configured:
        logger.info("Applying pending SQL migrations (schemas/migrations) …")
        await asyncio.to_thread(_run_db_migrations)
        logger.info("SQL migrations step completed.")
    else:
        logger.info("Cloud SQL not fully configured; skipping automatic migrations.")
    yield


app = FastAPI(lifespan=lifespan)

# Resolve CORS origins from environment first, then safe local defaults.
default_local_origins = [
    "http://localhost:3000",
    "http://localhost:8080",
    "http://localhost:5000",
    "http://127.0.0.1:5000",
]
cors_origins_env = os.getenv("CORS_ALLOW_ORIGINS", "").strip()
if cors_origins_env:
    allow_origins = [origin.strip() for origin in cors_origins_env.split(",") if origin.strip()]
else:
    allow_origins = default_local_origins

logger.info("CORS allowed origins: %s", allow_origins)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=allow_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
# DISABLED: Other routes temporarily disabled to focus on audio + STT features
# app.include_router(invitations.router)        # Caregiver invitations
# app.include_router(patient_register.router)   # Patient registration
# app.include_router(caregivers.router)         # Caregiver registration
# app.include_router(caregiver_patient.router)  # Caregiver-patient linking
app.include_router(visit_summary.router)      # Visit summaries (audio + STT only)
app.include_router(users.router)              # User authentication
app.include_router(care_team.router)          # Care team invitations
app.include_router(care_team.invitations_router)  # Email deep links (/api/invitations)
app.include_router(patient_tasks.router)      # Patient tasks
app.include_router(reminders.router)          # Reminders
logger.info("Reminders routes registered")
app.include_router(caregiver_notes.router)    # Caregiver notes
app.include_router(internal_cron.router)      # Scheduled internal jobs (cron secret)
app.include_router(subscription.router)        # Subscription / trial / RevenueCat sync
app.include_router(remivox.router)             # Vox voice companion

@app.get("/")
def root() -> dict:
    """Health check endpoint."""
    return {"message": "Backend running!"}


if __name__ == "__main__":
    import uvicorn
    # Run on all interfaces for development
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)