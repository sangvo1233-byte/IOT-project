---
name: face-recognition-pipeline
description: Build and tune the face recognition attendance pipeline (capture, detect, align, embed, match, attendance logging). Use for accuracy, threshold, enrollment, anti-spoofing, and 2D camera pipeline work on edge devices.
---

# Face Recognition Pipeline

Use this skill for any work on the recognition pipeline running on Raspberry Pi 4 with a 2D camera.

## Pipeline Stages

1. Capture: doc frame tu camera (Picamera2 hoac USB/OpenCV), kiem soat FPS va do phan giai.
2. Detect: phat hien khuon mat (ưu tien model nhe: SCRFD / RetinaFace-mobile / Haar fallback).
3. Align: can chinh landmark truoc khi embed de tang do chinh xac.
4. Embed: trich xuat embedding (MobileFaceNet / ArcFace-lite, dung ONNX/TFLite cho ARM).
5. Match: so sanh cosine/L2 voi gallery embeddings, ap nguong xac dinh.
6. Attendance: ghi su kien (person_id, timestamp, score), chong cham trung (debounce).

## Edge Constraints

- Khong GPU manh: chon model quantized (INT8) hoac mobile-grade.
- Uu tien throughput on dinh ~5-15 FPS thay vi do chinh xac toi da.
- Cache gallery embeddings trong RAM; chi reload khi enroll thay doi.
- Do detection -> embed o do phan giai vua du (vd 112x112 cho embed).

## Accuracy Rules

- Tach nguong verification (1:1) va identification (1:N) ro rang.
- Luu nhieu embedding/nguoi (3-5 goc mat) de tang recall.
- Theo doi FAR/FRR; ghi log score de tinh chinh nguong.
- Co buoc anti-spoofing toi thieu (blink/motion hoac passive liveness) vi camera 2D de bi anh/video gia.

## Attendance Logic

- Debounce: 1 nguoi chi ghi 1 lan trong cua so thoi gian cau hinh (vd 5 phut).
- Phan biet check-in / check-out neu can.
- Khi mat server: ghi local queue, sync lai khi co mang.

## Verification

- Test tren bo anh mau co nhan truoc khi chay live.
- Do latency tung stage de tim bottleneck.
- Kiem tra ca truong hop khong co mat, nhieu mat, anh gia.
