#!/usr/bin/env bash
# ==============================================================================
# HOMELAB ENDPOINT & CONTAINER HEALTHCHECK
# ==============================================================================

set -uo pipefail

echo "=== Verificando Estado de Contenedores Docker ==="
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "=== Test de Conectividad HTTP / HTTPS Interna ==="

check_url() {
    local name="$1"
    local url="$2"
    local status
    status=$(curl -k -s -o /dev/null -w "%{http_code}" "$url" || echo "FAIL")
    if [[ "$status" =~ ^(200|301|302)$ ]]; then
        echo -e "[\e[32mOK\e[0m] $name ($url) -> HTTP $status"
    else
        echo -e "[\e[31mFALLA\e[0m] $name ($url) -> Código: $status"
    fi
}

check_url "Dashboard Web" "http://localhost:3000"
check_url "Uptime Kuma" "http://localhost:3001"
check_url "Vaultwarden" "http://localhost:8085"
check_url "Nginx Proxy Manager Admin" "http://localhost:81"
check_url "Home Assistant" "http://localhost:8123"

echo ""
echo "=== Verificación Finalizada ==="
