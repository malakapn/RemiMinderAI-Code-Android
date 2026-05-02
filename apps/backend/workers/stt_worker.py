import os
import threading
import time
from http.server import BaseHTTPRequestHandler, HTTPServer

from jobs.stt_job import run_stt_job
from services.jobs_service import claim_job, mark_done, mark_failed

JOB_TYPE = "STT_JOB"


class HealthHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b"ok")

    def log_message(self, format, *args):
        pass


def start_health_server():
    port = int(os.environ.get("PORT", 8080))
    HTTPServer(("0.0.0.0", port), HealthHandler).serve_forever()


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
    threading.Thread(target=start_health_server, daemon=True).start()
    run_worker_loop()
