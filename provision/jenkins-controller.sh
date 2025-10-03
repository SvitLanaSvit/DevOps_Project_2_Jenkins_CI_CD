#!/usr/bin/env bash
set -euo pipefail

# ---- Docker Engine (офіційний репозиторій) ----
sudo apt-get update -y
sudo apt-get install -y ca-certificates curl gnupg lsb-release

sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release; echo $UBUNTU_CODENAME) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Додати vagrant у групу docker
sudo usermod -aG docker vagrant
sudo systemctl enable --now docker

# ---- Запуск Jenkins у Docker ----
# Volume для Jenkins Home
sudo mkdir -p /srv/jenkins_home
sudo chown 1000:1000 /srv/jenkins_home

# Якщо контейнер уже є — зупини/видали (ідемпотентність)
sudo docker rm -f jenkins || true

# Запускаємо LTS (JDK17), мапимо порти 8080 та 50000
sudo docker run -d --name jenkins \
  --restart unless-stopped \
  -p 8080:8080 -p 50000:50000 \
  -v /srv/jenkins_home:/var/jenkins_home \
  jenkins/jenkins:lts-jdk17

# Чекаємо поки Jenkins запуститься
echo "Чекаємо запуск Jenkins..."
sleep 30

# Створюємо SSH ключі для підключення до worker
sudo docker exec jenkins mkdir -p /var/jenkins_home/.ssh
sudo docker exec jenkins ssh-keygen -t rsa -b 2048 -f /var/jenkins_home/.ssh/id_rsa -N ""
sudo docker exec jenkins chown -R jenkins:jenkins /var/jenkins_home/.ssh

# Отримуємо публічний ключ для передачі на worker
sudo docker exec jenkins cat /var/jenkins_home/.ssh/id_rsa.pub > /vagrant/jenkins_public_key

echo "-----------------------------------------------------------"
echo "Jenkins стартує в Docker: http://192.168.56.10:8080"
echo "Початковий пароль (з'явиться після 20-60 сек.):"
echo "  vagrant ssh jenkins -c \"sudo docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword\""
echo "SSH ключ створено та збережено в /vagrant/jenkins_public_key"
echo "-----------------------------------------------------------"
