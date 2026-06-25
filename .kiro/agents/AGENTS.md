# Agents - IOT Face Recognition Attendance

Danh sach agent/role dung trong du an. Main agent dieu phoi, delegate phan viec doc lap.

## Roles

### main (coordinator)
- Giu critical path, tich hop ket qua, quyet dinh contract chung (event schema, API).
- Khong delegate phan dang block buoc tiep theo.

### explorer-device
- Map code trong `device/`, tim bottleneck pipeline, trace stage capture->match.
- Read-only. Tra ve: cau tra loi, file lien quan, ly do ngan.

### worker-device
- Implement trong `device/` (pipeline, enroll, offline queue).
- Owned scope: `device/`. Report file da doi + verify + risk.

### worker-server
- Implement trong `server/` (API nhan event, DB, dashboard).
- Owned scope: `server/`. Report file da doi + verify + risk.

## Skills Map

- Pipeline/accuracy/threshold -> `face-recognition-pipeline`.
- RPi setup/service/offline/deploy -> `rpi-edge-deploy`.
- Ship nhanh vertical slice -> `rapid-project-builder` (global).
- Review/done bar -> `quality-gate` (global).
- Delegation/parallel -> `subagent-orchestrator` (global).

## Ownership Rule

- 1 owner / module. `device/` va `server/` la 2 write-scope tach biet -> co the chay song song.
- Event schema (device <-> server) la contract chung, giu o main agent.
- Khong revert thay doi cua agent khac; dieu chinh de tuong thich.
