#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

if [[ ! -f .env ]]; then
  echo "Missing .env — copy .env.example to .env and set at least GCS_BUCKET_NAME."
  exit 1
fi

# Prefer python3.11/3.10 when available; fall back to python3 (macOS may be 3.9).
pick_python() {
  local candidate
  for candidate in python3.12 python3.11 python3.10 python3; do
    if command -v "$candidate" >/dev/null 2>&1; then
      echo "$candidate"
      return 0
    fi
  done
  echo "No python3 found. Install Python 3.10+ (Homebrew: brew install python@3.11)." >&2
  exit 1
}

PY="$(pick_python)"

if [[ ! -x .venv/bin/python ]]; then
  echo "Creating .venv with $($PY --version) ..."
  rm -rf .venv
  "$PY" -m venv .venv
  .venv/bin/python -m pip install --upgrade pip
  .venv/bin/python -m pip install -r requirements.txt
elif [[ ! -f .venv/.deps_installed ]] || [[ requirements.txt -nt .venv/.deps_installed ]]; then
  echo "Installing/updating backend requirements ..."
  .venv/bin/python -m pip install -r requirements.txt
  touch .venv/.deps_installed
fi

# Mark deps installed after a fresh venv create too.
touch .venv/.deps_installed

set -a
# shellcheck source=/dev/null
source .env
set +a

exec .venv/bin/python -m uvicorn main:app --reload --host "${HOST:-0.0.0.0}" --port "${PORT:-8000}"
