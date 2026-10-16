#!/usr/bin/env bash
# ==============================================================================
# HOMELAB DISASTER RECOVERY & RESTORE SCRIPT
# ==============================================================================
# Uso:
#   ./restore.sh <TIMESTAMP_FOLDER> <SERVICE_NAME>
# Ejemplo:
#   ./restore.sh 20261016_030000 vaultwarden
# ==============================================================================

set -euo pipefail

if [ $# -lt 2 ]; then
    echo "Uso: $0 <DIRECTORIO_TIMESTAMP> <SERVICIO (vaultwarden|homeassistant|npm|uptime-kuma|all)>"
    exit 1
fi

TIMESTAMP="$1"
SERVICE="$2"
BACKUP_PATH="/opt/homelab/backups/${TIMESTAMP}"
DATA_ROOT="/opt/homelab/data"

if [ ! -d "${BACKUP_PATH}" ]; then
    echo "[-] Error: El directorio de backup ${BACKUP_PATH} no existe."
    exit 1
fi

echo "[*] Verificando sumas de comprobación SHA-256 en ${BACKUP_PATH}..."
cd "${BACKUP_PATH}"
if [ -f "SHA256SUMS" ]; then
    sha256sum -c SHA256SUMS
    echo "[+] Verificación de integridad SHA-256 completada con éxito."
else
    echo "[!] Advertencia: No se encontró archivo SHA256SUMS. Continuando con precaución."
fi

# Restaurar Vaultwarden
if [ "${SERVICE}" == "vaultwarden" ] || [ "${SERVICE}" == "all" ]; then
    echo "[*] Restaurando Vaultwarden..."
    docker stop vaultwarden || true
    tar -xzf "${BACKUP_PATH}/vaultwarden-"*.tar.gz -C "${DATA_ROOT}"
    docker start vaultwarden
    echo "[+] Vaultwarden restaurado y en ejecución."
fi

# Restaurar Home Assistant
if [ "${SERVICE}" == "homeassistant" ] || [ "${SERVICE}" == "all" ]; then
    echo "[*] Restaurando Home Assistant..."
    docker stop homeassistant || true
    tar -xzf "${BACKUP_PATH}/homeassistant-"*.tar.gz -C "${DATA_ROOT}"
    docker start homeassistant
    echo "[+] Home Assistant restaurado y en ejecución."
fi

# Restaurar Nginx Proxy Manager
if [ "${SERVICE}" == "npm" ] || [ "${SERVICE}" == "all" ]; then
    echo "[*] Restaurando Nginx Proxy Manager..."
    docker stop nginx-proxy-manager || true
    tar -xzf "${BACKUP_PATH}/npm-ssl-"*.tar.gz -C "${DATA_ROOT}"
    docker start nginx-proxy-manager
    echo "[+] Nginx Proxy Manager restaurado y en ejecución."
fi

echo "[+] Proceso de restauración finalizado para '${SERVICE}'."
