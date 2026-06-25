---
name: rpi-edge-deploy
description: Deploy, run, and operate the attendance device on Raspberry Pi 4. Use for OS setup, camera config, dependency install on ARM, systemd service, auto-start, offline queue, OTA-style update, and field operations.
---

# RPi Edge Deploy

Use this skill for getting the attendance device running reliably on Raspberry Pi 4 in the field.

## Hardware / OS Baseline

- Raspberry Pi 4 (2GB toi thieu, 4GB+ khuyen nghi), Raspberry Pi OS 64-bit.
- Camera: Pi Camera Module (Picamera2) hoac USB UVC webcam.
- Tan nhiet tot (heatsink/fan) vi inference lien tuc gay nong va throttling.

## Dependency Strategy

- Dung Python venv; pin version trong requirements.
- Uu tien wheel ARM co san (opencv-python-headless, onnxruntime, numpy).
- Tranh build tu source neu co the; build native rat cham tren Pi.
- Tach requirements device va server.

## Run As Service

- Chay app duoi systemd service, auto-restart on failure.
- Auto-start on boot; log ra journald.
- Health check dinh ky; watchdog restart neu treo camera.

## Offline / Sync

- Local SQLite queue cho attendance events khi mat mang.
- Sync batch len server khi co ket noi; idempotent theo event_id.
- Giu config (server URL, device_id, nguong) trong file config tach biet code.

## Operations

- Cap nhat code: pull + restart service (OTA-style co the lam sau).
- Bao ve secrets/device token; khong hardcode trong repo.
- Theo doi nhiet do CPU, RAM, FPS de phat hien suy giam.

## Verification

- Smoke test: boot -> camera mo -> nhan dien 1 mau -> event len server.
- Test mat mang -> queue -> co mang lai -> sync thanh cong.
- Do nhiet va FPS sau 30+ phut chay lien tuc.
