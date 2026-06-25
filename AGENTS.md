# AGENTS.md - Face Attendance System (deploy len Raspberry Pi 4)

Tai lieu dinh huong cho moi coding agent lam viec trong repo nay. Doc truoc khi chinh sua code.

## Project Summary

He thong diem danh bang nhan dien khuon mat thoi gian thuc, muc tieu nhung len
Raspberry Pi 4. Stack: FastAPI + InsightFace (ArcFace 512-D) + MediaPipe
(stream liveness) + SQLite + dashboard JavaScript thuan.

Pipeline (Detect V4.4): camera/browser frame -> InsightFace detect + embed ->
liveness (stream + passive) -> moire / screen / phone-rectangle anti-spoof ->
match cosine voi gallery -> active challenge fallback -> ghi attendance + evidence.

## Repo Layout

- `main.py` - entrypoint FastAPI (lifespan preload model + camera).
- `config.py` - cau hinh tap trung (model, nguong, camera, server).
- `app/routes/` - REST + WebSocket endpoints (attendance, enrollment, scan_v3/v4, system...).
- `core/` - AI engine + runtime: face_engine, detect_v3/v4, liveness, moire,
  challenge, anti_spoof, camera, database, runtime_v3/v4, local_runner*.
- `web/` - dashboard tinh (index.html, app.js, js/, style.css) + trang /phone.
- `tests/` - pytest (core, detect_v4, v2_v3).
- `scripts/` - tien ich (download_models, setup Pi...).
- `models/` - model tai ve (gitignored; KHONG commit).
- `database/` - SQLite runtime (gitignored; KHONG commit).
- `docs/` - tai lieu kien truc / trien khai. Xem 15-realignment-plan.md.
- `.kiro/` - skill/agent gan rieng du an.

## Model dang dung (giu nguyen, chua doi)

- InsightFace goi `buffalo_l`: det_10g (detect) + w600k_r50 (ArcFace 512-D).
- MediaPipe `face_landmarker.task`: landmark day cho stream liveness / challenge.
- Tham so loi: EMBEDDING_DIM=512, COSINE_THRESHOLD=0.45, DET_SIZE=(480,480).
- Model NANG va KHONG commit; tai bang `scripts/download_models.py`.

## Tooling Policy (RTK)

@C:\Users\ADMIN\.codex-9router-v2\RTK.md

## Working Rules

- Reply tieng Viet; giu nguyen code, lenh, path, API bang tieng Anh.
- Uu tien implementation thay vi ke hoach dai; ship vertical slice truoc.
- Muc tieu chay tren RPi 4 (CPU ARM, khong GPU). Khi port can do hieu suat THAT.
- Doc `docs/` truoc khi doi kien truc. Cap nhat doc khi doi hanh vi quan trong.
- KHONG commit: model nang, *.db, anh nguoi that (logs/face_crops, logs/evidence),
  .env, secrets, embeddings cua nguoi that.

## Verification Default

- Server/core: chay pytest (`tests/`) + smoke test endpoint /health, /ready.
- AI: kiem nhan dien + liveness tren anh/video mau truoc khi tin la dung.
- Pi: do FPS / nhiet / RAM that bang thiet bi; ghi ro phan chua verify duoc.
