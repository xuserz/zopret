#!/bin/bash
set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

echo -e "\n${GREEN}Configuring UFW...${NC}"

# Установка UFW если не установлен
apt update -qq && apt install ufw -y -qq

# Базовые правила
ufw default deny incoming
ufw default allow outgoing

# Разрешаем SSH (порт 22)
ufw allow 22/tcp comment 'SSH'

# Разрешаем HTTP/HTTPS
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'

# Разрешаем доступ к ноде ТОЛЬКО с IP панели
ufw allow from $PANEL_IP to any port 2222 proto tcp comment 'Remnawave API'

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