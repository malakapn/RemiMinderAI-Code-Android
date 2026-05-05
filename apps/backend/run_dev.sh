#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
if [[ ! -f .env ]]; then
  echo "Missing .env — copy .env.example to .env and set at least GCS_BUCKET_NAME."
  exit 1
fi
if [[ ! -d .venv ]]; then
  echo "Create a venv first:"
  echo "  python3 -m venv .venv && source .venv/bin/activate && pip install -r requirements.txt"
  exit 1
fi
set -a
# shellcheck source=/dev/null
source .env
set +a
exec .venv/bin/uvicorn main:app --reload --host "${HOST:-0.0.0.0}" --port "${PORT:-8000}"
