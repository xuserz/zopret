#!/bin/bash
(
set -e

# ========== ВАШИ ДАННЫЕ (ЗАПОЛНИТЕ) ==========
PANEL_IPS="192.168.1.100 10.0.0.50"           # IP панелей через пробел
SSH_PORT="22"                                   # Порт SSH
SSH_LIMIT="yes"                                 # Ограничить SSH (yes/no)
NODE_API_PORT="2222"                            # Порт API ноды
CLIENT_PORTS="443:tcp,5000:tcp,8000:tcp,9999:both"  # Порт:протокол
SHADOWSOCK_PORTS="9999 10001 10002"             # ТОЛЬКО ПОРТЫ (без паролей)
SHADOWSOCK_ALLOWED_IPS="10.0.0.0/8"            # С каких IP можно подключаться (можно пусто)
OPEN_HTTP_HTTPS="yes"                           # Открыть 80/443
ENABLE_BBR="yes"                                # Включить BBR
# ============================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

echo -e "${GREEN}Starting UFW + BBR setup...${NC}"

apt update -qq && apt install ufw -y -qq

ufw default deny incoming
ufw default allow outgoing

# SSH
if [[ "$SSH_LIMIT" = "yes" ]]; then
    ufw limit $SSH_PORT/tcp comment 'SSH'
else
    ufw allow $SSH_PORT/tcp comment 'SSH'
fi

# HTTP/HTTPS
if [[ "$OPEN_HTTP_HTTPS" = "yes" ]]; then
    ufw allow 80/tcp comment 'HTTP'
    ufw allow 443/tcp comment 'HTTPS'
fi

# Клиентские порты
IFS=',' read -ra PORTS <<< "$CLIENT_PORTS"
for entry in "${PORTS[@]}"; do
    entry=$(echo $entry | xargs)
    port=$(echo $entry | cut -d: -f1)
    proto=$(echo $entry | cut -d: -f2 | tr '[:upper:]' '[:lower:]')
    case $proto in
        tcp)  ufw allow $port/tcp comment "Client TCP $port" ;;
        udp)  ufw allow $port/udp comment "Client UDP $port" ;;
        both) ufw allow $port/tcp comment "Client $port"; ufw allow $port/udp comment "Client $port" ;;
    esac
done

# Shadowsocks порты (только порты, пароли не нужны)
for port in $SHADOWSOCK_PORTS; do
    ufw allow $port/tcp comment "Shadowsocks TCP $port"
    ufw allow $port/udp comment "Shadowsocks UDP $port"
    
    # Ограничение доступа по IP (если указаны)
    for ip in $SHADOWSOCK_ALLOWED_IPS; do
        ufw allow from $ip to any port $port proto tcp
        ufw allow from $ip to any port $port proto udp
    done
    echo -e "${GREEN}Opened Shadowsocks port $port${NC}"
done

# Доступ для панелей
for ip in $PANEL_IPS; do
    ufw allow from $ip to any port $NODE_API_PORT proto tcp comment "Panel API $ip"
    echo -e "${GREEN}Allowed panel API from $ip on port $NODE_API_PORT${NC}"
done

# Включение UFW
echo "y" | ufw enable

# BBR
if [[ "$ENABLE_BBR" = "yes" ]] && ! grep -q "bbr" /etc/sysctl.conf; then
    cat >> /etc/sysctl.conf << EOF
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
EOF
    sysctl -p
    echo -e "${GREEN}BBR enabled${NC}"
fi

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Setup complete!${NC}"
ufw status verbose
)
