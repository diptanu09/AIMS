# AIMS Disaster Recovery & Rollback Operating Procedure

**Scope**: High Availability, Emergency Rollback & Database Recovery Protocols  
**Target SLAs**: Recovery Point Objective (RPO) < 24 Hours, Recovery Time Objective (RTO) < 30 Minutes  

---

## 1. Zero-Downtime Rollback Procedure

If a deployed release (`v1.1.0`) fails post-deployment smoke testing:

### Step 1: Immediately Switch Proxy Traffic to Stable Container Version
```bash
docker compose -f docker-compose.prod.yml stop aims-api aims-web aims-worker
git checkout tags/v1.0.0
docker compose -f docker-compose.prod.yml up -d --build aims-api aims-web aims-worker
```

### Step 2: Verify Schema Backward Compatibility
Ensure database migrations follow the **Expand-Contract Pattern**:
- `v1.1.0` adds new nullable columns or tables without dropping `v1.0.0` fields.
- No database restore is required for backward-compatible schema changes.

---

## 2. Disaster Recovery Protocol (Total Server Loss)

In the event of physical hardware failure or hypervisor corruption:

```text
               1. Provision New Clean Ubuntu Server
                                ↓
               2. Mount Persistent Backup Storage
                                ↓
               3. Checkout Tagged Release (git checkout v0.9.0)
                                ↓
               4. Initialize PostgreSQL Container
                                ↓
               5. Execute Database Restore (restore.sh)
                                ↓
               6. Launch Application Stack (docker compose up -d)
                                ↓
               7. Run Automated Health Smoke Tests
```

### Execution Commands:
```bash
# 1. Clone repository on replacement server
git clone https://github.com/cag-org/aims.git /opt/aims
cd /opt/aims
git checkout tags/v0.9.0

# 2. Start PostgreSQL container only
docker compose -f docker/docker-compose.prod.yml up -d aims-postgres

# 3. Restore latest database dump
/opt/aims/docker/scripts/restore.sh /mnt/backups/latest_aims_backup.sql.gz

# 4. Bring up remaining application stack
docker compose -f docker/docker-compose.prod.yml up -d

# 5. Verify system readiness
curl -f http://localhost:8080/health/ready
```
