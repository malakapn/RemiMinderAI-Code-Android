import logging
import os
import threading
import time
from http.server import BaseHTTPRequestHandler, HTTPServer

from jobs.stt_job import run_stt_job
from services.jobs_service import claim_job, mark_done, mark_failed

JOB_TYPE = "STT_JOB"
logger = logging.getLogger(__name__)


class HealthHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b"ok")

    def log_message(self, format, *args):
        pass


def create_health_server() -> HTTPServer:
    """Create and bind HTTP server on $PORT (call before any DB work)."""
    port = int(os.environ.get("PORT", 8080))
    httpd = HTTPServer(("0.0.0.0", port), HealthHandler)
    logger.info("STT worker health server bound on 0.0.0.0:%s", port)
    return httpd


def serve_health_forever(httpd: HTTPServer) -> None:
    """Run accept loop on the current thread (main thread for Cloud Run probes)."""
    httpd.serve_forever()
def run_worker_loop() -> None:
    while True:
        job = claim_job(JOB_TYPE)
        if not job:
            time.sleep(2)
            continue

        try:
            run_stt_job(job["payload"])
            mark_done(job["id"])
        except Exception as exc:
            attempts = int(job.get("attempts", 0))
            mark_failed(job["id"], str(exc), attempts)


if __name__ == "__main__":
    log_level_name = os.environ.get("LOG_LEVEL", "INFO").upper()
    logging.basicConfig(
        level=getattr(logging, log_level_name, logging.INFO),
        format="%(levelname)s %(name)s %(message)s",
    )
    port = int(os.environ.get("PORT", 8080))
    bucket = (os.environ.get("GCS_BUCKET_NAME") or "").strip()
    logger.info(
        "STT worker starting (health on 0.0.0.0:%s job_type=%s)",
        port,
        JOB_TYPE,
    )
    if not bucket:
        logger.warning(
            "GCS_BUCKET_NAME is unset; audio download will fail until it is configured."
        )
    else:
        logger.info("Using GCS bucket %s", bucket)

    # Bind $PORT before starting the job loop so TCP startup probes succeed even if
    # the first Cloud SQL connection is slow or misconfigured.
    httpd = create_health_server()
    threading.Thread(target=run_worker_loop, daemon=True).start()
    serve_health_forever(httpd)
