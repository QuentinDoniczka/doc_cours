#!/bin/bash

# Fonction pour vérifier si docker est installé
check_docker() {
    if command -v docker; then
        return 0  # Docker est installé
    else
        return 1  # Docker n'est pas installé
    fi
}

# Vérification de l'installation de Docker
if check_docker; then
    echo "Docker est déjà installé"
else
    echo "Installation de Docker..."
    # installation de docker et docker compose
    # Add Docker's official GPG key:
    sudo apt-get update
    sudo apt-get install ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    
    # Add the repository to Apt sources:
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    curl -fsSL "https://get.docker.com/" | sh
    sudo usermod -aG docker $(id -u -n)
    newgrp docker
    
    echo "Docker a été installé avec succès"
fi

# installations des logiciels cyber

sudo snap install sublime-text --classic -y
sudo apt-get install nmap -y
sudo apt-get install wireshark -y
sudo apt-get install hydra -y
sudo apt-get install sqlmap -y
sudo apt-get install mysql-server -y

# installation de logiciels Footprinting

sudo apt install geoip-bin -y
sudo apt install sublist3r -y
sudo apt install nikto -y


# installation de logiciels spoofing

sudo apt install dsniff -y
sudo apt install hping3 -y
sudo apt install macchanger -y

# installation Spiderfoot

git clone https://github.com/smicallef/spiderfoot.git
cd spiderfoot/
docker compose up -d
cd ..

# installation de DVWA

git clone https://github.com/digininja/DVWA.git
cd DVWA
docker compose up -d
cd ..

# installation de Sysreptor

sudo apt update
sudo apt install -y sed curl openssl uuid-runtime coreutils
curl -fsSL https://get.docker.com | sudo bash
bash <(curl -s https://docs.sysreptor.com/install.sh)


# installation de exegol

# install pipx if not already installed, from system package:
sudo apt update && sudo apt install pipx
# You can now install Exegol package from PyPI
pipx install exegol
pipx ensurepath
source ~/.bashrc
echo "alias exegol='sudo -E $(which exegol)'" >> ~/.bash_aliases
source ~/.bashrc

# Using the system package manager
sudo apt install python3-argcomplete
register-python-argcomplete --no-defaults exegol | sudo tee /etc/bash_completion.d/exegol > /dev/null