#!/bin/bash
set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  UFW + BBR Setup for Remnawave Node${NC}"
echo -e "${GREEN}========================================${NC}"

# Запрос IP панели
read -p "$(echo -e ${YELLOW}Enter your Remnawave Panel IP address: ${NC})" PANEL_IP

# Валидация IP (простая)
if [[ ! $PANEL_IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    echo -e "${RED}Invalid IP address format. Exiting.${NC}"
    exit 1
fi

# Запрос порта SSH (по умолчанию 22)
echo -e "${YELLOW}Enter SSH port (press Enter for default 22):${NC}"
read SSH_PORT
if [[ -z "$SSH_PORT" ]]; then
    SSH_PORT=22
    echo -e "${BLUE}Using default SSH port: 22${NC}"
fi

# Валидация порта SSH
if ! [[ "$SSH_PORT" =~ ^[0-9]+$ ]] || [ "$SSH_PORT" -lt 1 ] || [ "$SSH_PORT" -gt 65535 ]; then
    echo -e "${RED}Invalid port number. Using default 22.${NC}"
    SSH_PORT=22
fi

# Запрос порта ноды (по умолчанию 2222)
echo -e "${YELLOW}Enter Node API port (press Enter for default 2222):${NC}"
read NODE_PORT
if [[ -z "$NODE_PORT" ]]; then
    NODE_PORT=2222
    echo -e "${BLUE}Using default Node port: 2222${NC}"
fi

# Валидация порта ноды
if ! [[ "$NODE_PORT" =~ ^[0-9]+$ ]] || [ "$NODE_PORT" -lt 1 ] || [ "$NODE_PORT" -gt 65535 ]; then
    echo -e "${RED}Invalid port number. Using default 2222.${NC}"
    NODE_PORT=2222
fi

echo -e "\n${GREEN}Configuring UFW...${NC}"

# Установка UFW если не установлен
apt update -qq && apt install ufw -y -qq

# Базовые правила
ufw default deny incoming
ufw default allow outgoing

# Разрешаем SSH на указанном порту
ufw allow $SSH_PORT/tcp comment 'SSH'

# Разрешаем HTTP/HTTPS
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'

# Разрешаем доступ к ноде ТОЛЬКО с IP панели на указанном порту
ufw allow from $PANEL_IP to any port $NODE_PORT proto tcp comment 'Remnawave API'

echo -e "${GREEN}Enabling UFW...${NC}"
echo "y" | ufw enable

echo -e "\n${GREEN}Enabling BBR...${NC}"

# Включение BBR
cat >> /etc/sysctl.conf << EOF

# BBR optimizations
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
EOF

sysctl -p

# Проверка BBR
if sysctl net.ipv4.tcp_congestion_control | grep -q "bbr"; then
    echo -e "${GREEN}BBR is active!${NC}"
else
    echo -e "${RED}BBR activation failed.${NC}"
fi

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}Setup complete!${NC}"
echo -e "${GREEN}UFW Status:${NC}"
ufw status verbose
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}SSH port: $SSH_PORT${NC}"
echo -e "${GREEN}Node API port: $NODE_PORT${NC}"
echo -e "${GREEN}Panel IP allowed: $PANEL_IP${NC}"
echo -e "${GREEN}========================================${NC}"