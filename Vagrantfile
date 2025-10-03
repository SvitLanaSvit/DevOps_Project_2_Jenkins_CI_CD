# Vagrantfile
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64" # Ubuntu 22.04

  # Загальні ресурси
  config.vm.provider "virtualbox" do |vb|
    vb.cpus = 2
    vb.memory = 2048
  end

  CONTROLLER_IP = "192.168.56.10"
  WORKER_IP     = "192.168.56.11"

  # ----- VM1: Jenkins controller (Jenkins у Docker) -----
  config.vm.define "jenkins" do |vm|
    vm.vm.hostname = "jenkins"
    vm.vm.network "private_network", ip: CONTROLLER_IP
    vm.vm.provision "shell", path: "provision/jenkins-controller.sh"
  end

  # ----- VM2: Jenkins worker (агент без Docker-контейнера) -----
  config.vm.define "worker" do |vm|
    vm.vm.hostname = "worker"
    vm.vm.network "private_network", ip: WORKER_IP
    # Запускаємо worker після jenkins для отримання SSH ключа
    vm.vm.provision "shell", path: "provision/jenkins-worker.sh"
  end
end
