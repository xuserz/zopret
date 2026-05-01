# UFW + BBR Setup for Remnawave Node

Этот скрипт автоматически настраивает базовый файрвол (UFW) и включает алгоритм ускорения сети BBR на сервере, подготовленном для работы Remnawave Node.

Он разработан для серверов под управлением **Debian/Ubuntu** и автоматизирует процесс, описанный в документации Remnawave и сообщества.

### 🚀 Быстрая установка

Выполните эту команду на вашем сервере-ноде от имени **root**:

```bash
bash <(curl -s https://raw.githubusercontent.com/xuserz/zopret/refs/heads/main/ufw-bbr-setup.sh)