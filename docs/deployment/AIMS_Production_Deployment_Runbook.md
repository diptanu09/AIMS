# AIMS Production Deployment & Infrastructure Runbook

**Application**: Attendance Information Management System (AIMS)  
**Version**: `v0.9.0` (Pilot Release)  
**Target OS**: Ubuntu Server 24.04 LTS (x86_64)  
**Network**: Internal Organization LAN (`aims.internal`)  

---

## 1. Architecture Topology

```text
                                ORGANIZATION LAN
                                       │
                             ┌─────────▼─────────┐
                             │   Caddy Proxy     │ (Ports 80/443, TLS, CSP, Rate Limit)
                             └─────────┬─────────┘
                                       │
                  ┌────────────────────┴────────────────────┐
                  │                                         │
        ┌─────────▼─────────┐                     ┌─────────▼─────────┐
        │  Next.js Web UI   │                     │   Rust API Engine │ (Port 8080 Internal)
        │  (aims-web:3000)  │                     │   (aims-api:8080) │
        └───────────────────┘                     └─────────┬─────────┘
                                                            │
                                                  ┌─────────▼─────────┐
                                                  │  Background Worker│
                                                  │  (aims-worker)    │
                                                  └─────────┬─────────┘
                                                            │
                                                  ┌─────────▼─────────┐
                                                  │ PostgreSQL 16 DB  │ (Persistent Volume)
                                                  │  (aims-postgres)  │
                                                  └───────────────────┘
```

---

## 2. Pre-Deployment Prerequisites

- Docker Engine 26.0+ & Docker Compose v2.25+
- Open LAN ports: `80` (HTTP), `443` (HTTPS)
- System User: `aims-deploy` in `docker` group
- Storage: Minimum 50 GB NVMe SSD volume mounted at `/var/lib/docker`

---

## 3. Production Deployment Execution Steps

### Step 1: Clone Release Tag & Navigate to Repository
```bash
git clone https://github.com/cag-org/aims.git /opt/aims
cd /opt/aims
git checkout tags/v0.9.0
```

### Step 2: Configure Environment Secrets
Create `/opt/aims/docker/.env`:
```env
ENVIRONMENT=production
DB_OWNER_PASSWORD=StrongOwnerPass_9823#!
DB_APP_PASSWORD=StrongAppPass_1294#!
SESSION_COOKIE_NAME=aims_session
ALLOWED_ORIGINS=https://aims.internal
```

### Step 3: Launch Production Stack
```bash
cd /opt/aims/docker
docker compose -f docker-compose.prod.yml up -d --build
```

### Step 4: Verify Container Health Status
```bash
docker compose -f docker-compose.prod.yml ps
```
Ensure `aims-postgres`, `aims-api`, `aims-worker`, `aims-web`, and `aims-proxy` report `running (healthy)`.

---

## 4. Production Smoke Test Protocol

1. **Health Verification**:
   ```bash
   curl -f https://aims.internal/api/v1/health/live
   curl -f https://aims.internal/api/v1/health/ready
   ```
2. **Web Portal Sign-In**: Navigate to `https://aims.internal/login` in Google Chrome / Edge and authenticate with administrative credentials.
3. **Biometric Matrix Import**: Upload `sample.csv` via `/import` and verify preview & commit execution.
4. **Attendance Calculation**: Confirm `/attendance` register displays processed status (`PRESENT`, `LATE`, `ABSENT`).
5. **PDF Report Export**: Generate and download Monthly Section Report PDF via `/reports`.

---

## 5. Backup & Recovery Schedule

- **Daily Backup**: Executed via Cron at `02:00 AM` (`/opt/aims/docker/scripts/backup.sh`).
- **Retention**: 30 daily backups, 12 weekly archives.
- **Restore Command**:
  ```bash
  /opt/aims/docker/scripts/restore.sh /var/backups/aims/aims_backup_20260822_020000.sql.gz
  ```
