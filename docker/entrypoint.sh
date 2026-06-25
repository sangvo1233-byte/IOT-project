#!/usr/bin/env bash
# Entrypoint Docker: tai model neu thieu roi khoi dong server.
set -euo pipefail

LANDMARKER="models/face_landmarker.task"
BUFFALO="models/models/buffalo_l"

if [ ! -f "$LANDMARKER" ] || [ ! -d "$BUFFALO" ]; then
  echo "[entrypoint] Model chua day du -> tai ve (buffalo_l + face_landmarker.task)..."
  python scripts/download_models.py || echo "[entrypoint] CANH BAO: tai model that bai. Server van chay nhung nhan dien se loi cho den khi co model."
else
  echo "[entrypoint] Model da co san, bo qua buoc tai."
fi

echo "[entrypoint] Khoi dong FastAPI tren ${HOST:-0.0.0.0}:${PORT:-8000}"
exec uvicorn main:app --host "${HOST:-0.0.0.0}" --port "${PORT:-8000}"