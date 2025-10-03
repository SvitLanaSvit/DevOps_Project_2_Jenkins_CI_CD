#!/usr/bin/env bash
set -euo pipefail

# ---- Системні пакети ----
sudo apt-get update -y
sudo apt-get install -y ca-certificates curl gnupg lsb-release git openjdk-17-jdk

# ---- Docker Engine ----
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release; echo $UBUNTU_CODENAME) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker vagrant
sudo systemctl enable --now docker

# ---- Node.js 18 LTS ----
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs build-essential

# ---- SSH: дозволити пароль для простого підключення з Jenkins ----
sudo sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/KbdInteractiveAuthentication no/KbdInteractiveAuthentication yes/' /etc/ssh/sshd_config
sudo systemctl restart ssh
echo "vagrant:vagrant" | sudo chpasswd

# Створюємо SSH директорію для jenkins ключів
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Чекаємо на створення SSH ключа на master (файл буде створений jenkins VM)
echo "Чекаємо на SSH ключ від Jenkins master..."
for i in {1..30}; do
    if [ -f /vagrant/jenkins_public_key ]; then
        cat /vagrant/jenkins_public_key >> ~/.ssh/authorized_keys
        chmod 600 ~/.ssh/authorized_keys
        echo "SSH ключ Jenkins додано до authorized_keys"
        break
    fi
    echo "Спроба $i/30: чекаємо SSH ключ..."
    sleep 2
done

echo "Worker готовий: 192.168.56.11"
echo "Версії: node=$(node -v), npm=$(npm -v)"
