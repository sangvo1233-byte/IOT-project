# Face Attendance System

Real-time face attendance system built with FastAPI, InsightFace ArcFace embeddings,
MediaPipe-based stream liveness, SQLite, and a vanilla JavaScript dashboard. The
deployment target is a Raspberry Pi 4 (ARM64), packaged with Docker.

The default web runtime is Detect V4.4. It supports:

- `Auto` scan mode selection on the dashboard
- `Browser Stream` scanning over `ws://.../ws/scan-v4`
- `Local Direct` scanning from the server webcam over `ws://.../ws/scan-v4/local`
- multi-angle enrollment with `front`, `left`, and `right` capture
- layered anti-spoofing with moire detection, screen-context checks, phone-rectangle checks, passive liveness, stream liveness, and active challenge fallback

Detect V3 and legacy V1 routes are still present for compatibility, but the current UI is wired around V4.4.

---

## Quick Start (Docker on Raspberry Pi 4)

This is the recommended path for a teammate deploying on the Pi.

```bash
git clone https://github.com/sangvo1233-byte/IOT-project.git
cd IOT-project
docker compose up -d --build
docker compose logs -f
```

Open `http://<pi-ip>:8000/`. First start is slower because the container downloads
the model set (~600 MB) into the mounted `models/` volume. See the full
[Docker Deployment](#docker-deployment-raspberry-pi-4--arm64) section for details.

---

## Current Runtime Summary

| Runtime | Main routes | Purpose | Status |
|---|---|---|---|
| Detect V4.4 | `/ws/scan-v4`, `/api/scan/v4`, `/ws/scan-v4/local` | Current production scan pipeline | Default |
| Detect V3 | `/ws/scan-v3`, `/api/scan/v3`, `/api/scan/v3/challenge` | Older strict + challenge path | Compatibility |
| Legacy V1 | `/api/scan`, `/api/enroll` | Baseline single-frame flow | Legacy |

The dashboard scan-mode selector uses three frontend modes:

- `auto`: chooses `local_direct` when the page is opened on localhost/private LAN and the server camera is available; otherwise falls back to `browser_ws`
- `local_direct`: server webcam drives Detect V4.4 through `core/local_runner_v4.py`
- `browser_ws`: this browser camera sends JPEG frames to `/ws/scan-v4`

The `/phone` page and `/ws/phone-camera` transport are still available, but they are not the default Detect V4.4 dashboard path.

---

## Feature Highlights

- FastAPI backend with static dashboard served from `web/`
- SQLite student/session/attendance storage
- InsightFace face detection and 512-d ArcFace embeddings (`buffalo_l`)
- multi-angle V2 enrollment with per-angle validation
- Detect V4.4 backend-owned scan runtime shared by browser stream and local-direct modes
- active challenge fallback supporting `TURN_LEFT`, `TURN_RIGHT`, `LOOK_UP`, `LOOK_DOWN`, `OPEN_MOUTH`, and `CENTER_HOLD`
- attendance success overlay and in-camera challenge overlay
- debug "Tech Overlay" for runtime geometry and diagnostics
- student archive/restore flow with photo and evidence endpoints
- health, readiness, version, and capability endpoints for deployment checks

---

## Detect V4.4 Pipeline

```text
Browser camera or server webcam frame
  -> InsightFace face detect + embedding
  -> Streaming liveness tracker
  -> Rolling moire detector
  -> Screen-context detector
  -> Phone-rectangle detector
  -> Passive liveness check
  -> ArcFace match at V4 threshold
  -> If suspicious after identity match: start active challenge
  -> If challenge passes or no challenge needed: record attendance
```

### What V4.4 adds compared with V3

- Detect V4.4 is transport-agnostic: both browser-stream and local-direct modes feed the same backend runtime in `core/runtime_v4.py`
- moire decisions use the V4 detector in `core/detect_v4.py`
- screen-context analysis is enabled
- phone-rectangle analysis is enabled, including rolling decisions across frames
- challenge handling lives inside the runtime session instead of relying on a separate client-driven verification loop
- the frontend can render debug geometry from runtime diagnostics using the "Tech Overlay" toggle

### Active challenge behavior

V4.4 only starts a challenge after a matched identity looks suspicious. Current challenge types:

| Challenge | Description |
|---|---|
| `TURN_LEFT` | Turn face to the left |
| `TURN_RIGHT` | Turn face to the right |
| `LOOK_UP` | Tilt face upward |
| `LOOK_DOWN` | Tilt face downward |
| `OPEN_MOUTH` | Open mouth visibly |
| `CENTER_HOLD` | Hold face centered and still |

Current challenge state is in-memory and process-local.

---

## Project Structure

```text
IOT-project/
|
|-- main.py                  FastAPI entrypoint (lifespan preload model + camera)
|-- config.py                Centralized configuration
|-- requirements.txt
|-- pytest.ini
|-- README.md
|-- .env.example
|
|-- Dockerfile               ARM64 image for Raspberry Pi 4
|-- docker-compose.yml       One-command build/run with volumes + camera mapping
|-- .dockerignore
|-- docker/
|   |-- entrypoint.sh         Downloads models on first run, then starts uvicorn
|
|-- app/
|   |-- __init__.py
|   |-- routes/
|       |-- attendance.py
|       |-- enrollment.py
|       |-- enrollment_v2.py
|       |-- live.py
|       |-- local_scan.py
|       |-- phone_camera.py
|       |-- scan_v3.py
|       |-- scan_v4.py
|       |-- system.py
|       |-- __init__.py
|
|-- core/
|   |-- face_engine.py        InsightFace detect + ArcFace embed + match
|   |-- camera.py             Shared webcam producer thread
|   |-- database.py           SQLite student/session/attendance
|   |-- detect_v3.py  detect_v4.py
|   |-- runtime_v3.py  runtime_v4.py
|   |-- local_runner.py  local_runner_v4.py
|   |-- stream_scan_v3.py  stream_scan_v4.py
|   |-- anti_spoof.py  liveness.py  moire.py  challenge_v3.py
|   |-- enrollment_v2.py  schemas.py  __init__.py
|
|-- web/
|   |-- index.html  phone.html
|   |-- app.js  style.css  phone.js  phone_style.css
|   |-- js/
|       |-- api.js  enrollment.js  history.js  main.js  scan.js
|       |-- session.js  state.js  students.js  ui.js
|
|-- scripts/
|   |-- download_models.py    Downloads buffalo_l + face_landmarker.task
|
|-- tests/
|   |-- test_core.py          Integration (skips without a test video dir)
|   |-- test_detect_v4.py  test_v2_v3.py  run_test.py
|
|-- docs/
|   |-- 15-realignment-plan.md
|
|-- models/                  Downloaded models (gitignored, .gitkeep only)
|-- database/                SQLite runtime data (gitignored, .gitkeep only)
|-- logs/                    Evidence + face crops + logs (gitignored, created at runtime)
```

---

## Repository Map

Which paths are tracked in Git and which are local-only runtime data.

| Path | Tracked in Git | Notes |
|---|---|---|
| `app/`, `core/`, `web/`, `tests/`, `scripts/`, `docs/` | Yes | Application source and docs |
| `main.py`, `config.py`, `requirements.txt`, `pytest.ini` | Yes | Entry point and config |
| `Dockerfile`, `docker-compose.yml`, `.dockerignore`, `docker/` | Yes | Container build and deploy |
| `.env.example` | Yes | Environment variable reference with no secrets |
| `.gitignore`, `.gitattributes` | Yes | Repo tooling |
| `models/` | No | Downloaded model files; too large for Git |
| `database/` | No | SQLite database and backups; local runtime data |
| `logs/` | No | Evidence images, face crops, and runtime logs |
| `.env` | No | Real environment variables; never commit |

Git safety: `.gitignore` reduces the chance of accidentally committing local data, but
it is not a security boundary. Sensitive values should be managed through environment
variables, not committed files.

Runtime data is stored in `database/attendance.db`, `database/backups/`,
`logs/evidence/`, and `logs/face_crops/`. None of it is committed.

---

## Requirements

- Python 3.11 (recommended). MediaPipe does not yet provide wheels for Python 3.13, so 3.11 is the safe choice.
- Conda or virtualenv recommended for a local (non-Docker) install
- modern browser with camera permission
- optional NVIDIA GPU for faster ONNX inference (not present on the Pi; CPU is used there)

The codebase uses modern type syntax such as `str | None`, so Python 3.10+ is the floor.

---

## Local Installation (without Docker)

### 1. Create an environment

```bash
conda create -n face-att python=3.11
conda activate face-att
```

### 2. Install Python dependencies

```bash
pip install -r requirements.txt
```

### 3. Download models

```bash
python scripts/download_models.py
```

This fetches the InsightFace `buffalo_l` set and `models/face_landmarker.task` into
`models/`. InsightFace can also auto-download `buffalo_l` on first run; the script
just prepares everything up front (and is what the Docker image runs on first start).

If you want GPU inference, install a matching `onnxruntime-gpu` build instead of CPU-only `onnxruntime`.

---

## Docker Deployment (Raspberry Pi 4 / ARM64)

The repository ships a `Dockerfile`, `.dockerignore`, and `docker-compose.yml` so a
teammate can build and run the whole stack without installing Python, InsightFace,
or MediaPipe by hand. Models are NOT in Git; the container downloads them on first
start via `scripts/download_models.py` (needs internet) and caches them in the
mounted `models/` volume.

### Build and run on the Pi (recommended)

```bash
git clone https://github.com/sangvo1233-byte/IOT-project.git
cd IOT-project
docker compose up -d --build
docker compose logs -f
```

The dashboard is then served on `http://<pi-ip>:8000`. The first start is slower
because it downloads the `buffalo_l` model set (~600 MB) into `models/`.

### Plain Docker (without compose)

```bash
docker build -t face-attendance .
docker run -d --name face-attendance \
  -p 8000:8000 \
  --device /dev/video0:/dev/video0 \
  -v "$(pwd)/models:/app/models" \
  -v "$(pwd)/database:/app/database" \
  -v "$(pwd)/logs:/app/logs" \
  face-attendance
```

### Cross-building from an x86 PC for the Pi

```bash
docker buildx build --platform linux/arm64 -t face-attendance --load .
```

### Notes

- Camera: the compose file maps `/dev/video0`. Change it if the USB webcam is on
  another index. The Pi Camera Module (CSI) is not exposed through `/dev/video0`
  by default and needs extra setup.
- Persistence: `models/`, `database/`, and `logs/` are bind-mounted so models and
  attendance data survive container rebuilds.
- Security: the app has no authentication. Keep it on a trusted LAN, do not expose
  port 8000 directly to the internet.

---

## Running The App (local)

```bash
python main.py
```

Open `http://localhost:8000/`. Phone camera page is at `http://localhost:8000/phone`.

Useful health endpoints:

- `GET /health`
- `GET /ready`
- `GET /version`
- `GET /api/system/status`
- `GET /api/system/capabilities`

Interactive API docs are available at `/docs` when `API_DOCS_ENABLED=true`.

---

## API Summary

### Session endpoints

| Method | Endpoint | Purpose |
|---|---|---|
| `POST` | `/api/session/start` | Start a session |
| `POST` | `/api/session/end` | End the active session |
| `GET` | `/api/session/active` | Get the current active session |
| `GET` | `/api/session/{session_id}/result` | Get present/absent results for a session |
| `GET` | `/api/sessions` | List past sessions |
| `GET` | `/api/session/attendance` | Get current-session attendance list |

### Student endpoints

| Method | Endpoint | Purpose |
|---|---|---|
| `GET` | `/api/students?view=active|archived|all` | List students |
| `GET` | `/api/students/{student_id}` | Student details, embedding count, history |
| `PUT` | `/api/students/{student_id}` | Update name or class |
| `DELETE` | `/api/students/{student_id}` | Archive student |
| `POST` | `/api/students/{student_id}/restore` | Restore archived student |
| `GET` | `/api/students/{student_id}/photo` | Serve stored face crop |
| `GET` | `/api/evidence/{filename}` | Serve attendance evidence image |

### Enrollment endpoints

| Method | Endpoint | Purpose |
|---|---|---|
| `POST` | `/api/enroll` | Legacy single-image enrollment |
| `POST` | `/api/enroll/v2` | Multi-angle enrollment with front/left/right images |
| `POST` | `/api/enroll/v2/validate` | Validate one angle before saving |

### Detect V4.4 endpoints

| Method | Endpoint | Purpose |
|---|---|---|
| `POST` | `/api/scan/v4` | Single-frame V4 compatibility scan |
| `WS` | `/ws/scan-v4` | Default browser-camera V4 stream |
| `POST` | `/api/scan/v4/local/start` | Start server-webcam local-direct V4 runner |
| `POST` | `/api/scan/v4/local/stop` | Stop local-direct V4 runner |
| `GET` | `/api/scan/v4/local/status` | Get local-direct V4 status |
| `WS` | `/ws/scan-v4/local` | Subscribe to local-direct V4 events |

### Compatibility endpoints

| Method | Endpoint | Purpose |
|---|---|---|
| `POST` | `/api/scan` | Legacy V1 scan |
| `POST` | `/api/scan/v3` | Single-frame Detect V3 scan |
| `WS` | `/ws/scan-v3` | Detect V3 browser stream |
| `POST` | `/api/scan/v3/challenge` | Verify V3 challenge frames |
| `POST` | `/api/scan/v3/local/start` | Start V3 local-direct runner |
| `POST` | `/api/scan/v3/local/stop` | Stop V3 local-direct runner |
| `GET` | `/api/scan/v3/local/status` | Get V3 local-direct status |
| `WS` | `/ws/scan-v3/local` | Subscribe to V3 local-direct events |

### Camera and system endpoints

| Method | Endpoint | Purpose |
|---|---|---|
| `GET` | `/api/live/stream` | Server webcam MJPEG stream |
| `GET` | `/api/live/phone-stream` | MJPEG stream from phone uploader |
| `GET` | `/api/phone/status` | Phone transport status |
| `GET` | `/api/phone/latest` | Latest phone frame |
| `WS` | `/ws/phone-camera` | Phone frame upload transport |
| `GET` | `/api/system/status` | Runtime system summary |
| `GET` | `/api/system/capabilities` | API versions, modes, and thresholds |

---

## Configuration

Configuration is split across two places:

- `config.py` for app paths, server flags, camera options, enrollment rules, and shared V3 stream settings
- `core/detect_v4.py` for Detect V4.4 scoring thresholds and detector constants

### Common app settings in `config.py`

| Setting | Default | Purpose |
|---|---:|---|
| `APP_VERSION` | `4.4.0` | App version reported by `/version` |
| `HOST` | `0.0.0.0` | Uvicorn bind host |
| `PORT` | `8000` | Uvicorn bind port |
| `AUTO_PRELOAD_MODELS` | `True` | Warm up face engine during startup |
| `AUTO_LOAD_EMBEDDING_CACHE` | `True` | Load student embeddings during warmup |
| `AUTO_START_CAMERA` | `True` | Start server webcam on boot |
| `CAMERA_REQUIRED` | `False` | Mark camera failure as fatal when true |
| `CAMERA_SOURCE` | `0` | Server webcam source |
| `INSIGHTFACE_MODEL` | `buffalo_l` | InsightFace model pack |
| `EMBEDDING_DIM` | `512` | ArcFace embedding size |
| `COSINE_THRESHOLD` | `0.45` | Base 1:N match threshold |

### Detect V4.4 thresholds in `core/detect_v4.py`

| Setting | Default | Purpose |
|---|---:|---|
| `V4_COSINE_THRESHOLD` | `0.52` | V4 face-match threshold |
| `MOIRE_SCREEN_THRESHOLD` | `0.60` | Suspicious moire threshold |
| `MOIRE_BLOCK_THRESHOLD` | `0.45` | Hard screen block threshold |
| `SCREEN_CONTEXT_STRONG_THRESHOLD` | `0.78` | Strong screen-context trigger |
| `PHONE_RECT_SUSPICIOUS_THRESHOLD` | `0.38` | Suspicious phone-rectangle threshold |
| `PHONE_RECT_STRONG_THRESHOLD` | `0.58` | Strong phone-rectangle threshold |

If you change V4 behavior, update both the code and this README so the documented thresholds stay honest.

---

## Testing

Run the automated suite (53 tests) with a Python 3.11 environment that has the deps installed:

```bash
python -m pytest -q
```

`tests/test_detect_v4.py` and `tests/test_v2_v3.py` mock the heavy models, so they run
without downloading anything.

`tests/test_core.py` is an integration test marked `@pytest.mark.integration`. It needs
an external video directory and loads the real model. If that directory is not present
it skips itself, which is why the default run still passes. To run it explicitly:

```bash
python -m pytest tests/test_core.py -m integration -s
```

Optional frontend syntax check (requires Node.js):

```bash
node --check web/js/main.js
node --check web/js/scan.js
node --check web/js/enrollment.js
```

### Manual smoke checklist

- start a session from the dashboard
- enroll a student with the V2 front/left/right flow
- verify `Auto` picks the expected scan mode
- test `Browser Stream` on a remote browser
- test `Local Direct` on the machine that has the webcam attached
- verify attendance success overlay and challenge overlay both render
- end the session and inspect history details

---

## Known Limitations

- challenge state is in-memory and process-local, so multiple app workers would need shared state
- thresholds still need real-camera tuning for lighting, compression, and replay conditions
- `Local Direct` only makes sense when the camera is physically attached to the server machine
- the app has no authentication; do not expose it directly to the internet
- ArcFace (`w600k_r50`, ~166 MB) runs on CPU on the Pi 4, so per-face latency is higher than on a PC; real FPS should be measured on the device
- runtime data under `database/`, `logs/`, and `models/` can grow quickly during testing

See `docs/15-realignment-plan.md` for the history of how this repo was realigned to the
production codebase and the planned Raspberry Pi port.
