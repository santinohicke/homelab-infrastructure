#!/usr/bin/env bash
# ==============================================================================
# HOMELAB ROUTINE MAINTENANCE & DOCKER CLEANUP SCRIPT
# ==============================================================================
# Ejecución recomendada semanal:
#   0 4 * * 0 /opt/homelab/scripts/maintenance.sh >> /var/log/homelab-maintenance.log 2>&1
# ==============================================================================

set -euo pipefail

echo "=========================================================="
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Iniciando tareas de mantenimiento programado..."
echo "=========================================================="

# 1. Poda de Docker (Imágenes huérfanas, contenedores detenidos y caché de build)
echo "[*] Limpiando imágenes y capas no utilizadas en Docker..."
docker system prune -af --volumes

# 2. Truncar logs de contenedores que superen límites sin reiniciar servicios
echo "[*] Verificando tamaño de logs de contenedores Docker..."
find /var/lib/docker/containers/ -name "*-json.log" -size +50M -exec truncate -s 0 {} +

# 3. Limpieza de paquetes del sistema operativo Ubuntu
if command -v apt-get &> /dev/null; then
    echo "[*] Limpiando caché local de apt y dependencias obsoletas..."
    apt-get autoremove -y
    apt-get autoclean -y
fi

# 4. Estado de almacenamiento tras el mantenimiento
echo "=========================================================="
echo "Estado de Disco SSD:"
df -h /
echo "=========================================================="
echo "Consumo de Memoria RAM:"
free -h
echo "=========================================================="
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Mantenimiento finalizado con éxito."
