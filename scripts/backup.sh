#!/usr/bin/env bash
# ==============================================================================
# HOMELAB AUTOMATED BACKUP & RETENTION SCRIPT
# ==============================================================================
# Ejecución programada vía cron (03:00 AM todos los días):
#   0 3 * * * /opt/homelab/scripts/backup.sh >> /var/log/homelab-backup.log 2>&1
# ==============================================================================

set -euo pipefail

BACKUP_DIR="${BACKUP_DIR:-/opt/homelab/backups}"
DATA_ROOT="${DATA_ROOT:-/opt/homelab/data}"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
RETENTION_DAYS=14

echo "=========================================================="
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Iniciando proceso de backup..."
echo "=========================================================="

mkdir -p "${BACKUP_DIR}/${TIMESTAMP}"

# 1. Backup de Base de Datos SQLite de Vaultwarden (Consistente con sqlite3 .backup)
if [ -f "${DATA_ROOT}/vaultwarden/db.sqlite3" ]; then
    echo "[*] Generando snapshot seguro de Vaultwarden SQLite..."
    sqlite3 "${DATA_ROOT}/vaultwarden/db.sqlite3" ".backup '${BACKUP_DIR}/${TIMESTAMP}/vaultwarden_db.sqlite3'"
    tar -czf "${BACKUP_DIR}/${TIMESTAMP}/vaultwarden-${TIMESTAMP}.tar.gz" \
        -C "${BACKUP_DIR}/${TIMESTAMP}" vaultwarden_db.sqlite3 \
        -C "${DATA_ROOT}/vaultwarden" attachments 2>/dev/null || true
    rm -f "${BACKUP_DIR}/${TIMESTAMP}/vaultwarden_db.sqlite3"
fi

# 2. Backup de Home Assistant Config
if [ -d "${DATA_ROOT}/homeassistant" ]; then
    echo "[*] Comprimiendo configuraciones de Home Assistant..."
    tar --exclude='home-assistant_v2.db-shm' \
        --exclude='home-assistant_v2.db-wal' \
        -czf "${BACKUP_DIR}/${TIMESTAMP}/homeassistant-${TIMESTAMP}.tar.gz" \
        -C "${DATA_ROOT}" homeassistant
fi

# 3. Backup de Nginx Proxy Manager (Certificados SSL y configuraciones de hosts)
if [ -d "${DATA_ROOT}/npm" ]; then
    echo "[*] Respaldando certificados SSL y hosts de Nginx Proxy Manager..."
    tar -czf "${BACKUP_DIR}/${TIMESTAMP}/npm-ssl-${TIMESTAMP}.tar.gz" \
        -C "${DATA_ROOT}" npm
fi

# 4. Backup de Uptime Kuma
if [ -d "${DATA_ROOT}/uptime-kuma" ]; then
    echo "[*] Respaldando base de datos de Uptime Kuma..."
    tar -czf "${BACKUP_DIR}/${TIMESTAMP}/uptime-kuma-${TIMESTAMP}.tar.gz" \
        -C "${DATA_ROOT}" uptime-kuma
fi

# 5. Generación de Checksums SHA-256 para validación de integridad
echo "[*] Calculando sumas de verificación SHA-256..."
cd "${BACKUP_DIR}/${TIMESTAMP}"
sha256sum *.tar.gz > "SHA256SUMS"

# 6. Política de Retención: Eliminar backups con más de 14 días
echo "[*] Aplicando política de retención (${RETENTION_DAYS} días)..."
find "${BACKUP_DIR}" -mindepth 1 -maxdepth 1 -type d -mtime +${RETENTION_DAYS} -exec rm -rf {} +

echo "=========================================================="
echo "[$(date '+%Y-%m-%d %H:%M:%S')] ¡Backup completado con éxito en ${BACKUP_DIR}/${TIMESTAMP}!"
echo "=========================================================="
