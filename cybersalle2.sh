#!/bin/bash

cd ~/

# Définir le mot de passe root
echo "Activation du mot de passe root"
sudo passwd root
echo " "

# Modifier les utilisateurs visudo
echo "Suppression de la demande de saisie du mot de passe sudo"
sudo sed -E -i "s/^\s*(%sudo\s+[A-Za-z0-9]+\s*=\s*\(\s*[A-Za-z0-9]+\s*:\s*[A-Za-z0-9]+\s*\)\s+)([A-Za-z0-9]+\s*)$/\1NOPASSWD: \2/g"  /etc/sudoers
echo " "

# installation de docker et docker compose
echo "Installation de docker et docker compose"

# Add Docker's official GPG key:
sudo apt-get update -y
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
newgrp docker > /dev/null

# installations des logiciels cyber
echo "installation de sublime-text"
sudo snap install sublime-text --classic -y
echo "installation de nmap"
sudo apt-get install nmap -y
echo "installation de wireshark"
sudo apt-get install wireshark -y
echo "installation de hydra"
sudo apt-get install hydra -y
echo "installation de sqlmap"
sudo apt-get install sqlmap -y
echo "installation de mysql"
sudo apt-get install mysql-server -y

# installation de logiciels Footprinting

echo "installation de logiciel de Footrprinting"
sudo apt install geoip-bin -y
sudo apt install sublist3r -y
sudo apt install nikto -y

# installation de logiciels spoofing
echo "installation de logiciel de spoofing"
sudo apt install dsniff -y
sudo apt install hping3 -y
sudo apt install macchanger -y

# installation Spiderfoot
echo "installation de spiderfoot"
git clone https://github.com/smicallef/spiderfoot.git
cd spiderfoot
docker compose up -d
cd ..

# installation de DVWA
echo "installation de DVWA"
git clone https://github.com/digininja/DVWA.git
cd dvwa
docker compose up -d
cd ..

# installation de Sysreptor
echo "installation de Sysreptor"
sudo apt update -y
sudo apt install -y sed curl openssl uuid-runtime coreutils
curl -fsSL https://get.docker.com | sudo bash
bash <(curl -s https://docs.sysreptor.com/install.sh)

# installation de exegol
echo "installation de Exegol"
# install pipx if not already installed, from system package:
sudo apt update -y && sudo apt install pipx -y
# You can now install Exegol package from PyPI
pipx install exegol --force
pipx ensurepath
source ~/.bashrc
echo "alias exegol='sudo -E $(which exegol)'" >> ~/.bash_aliases
source ~/.bashrc

# Using the system package manager
sudo apt install python3-argcomplete
register-python-argcomplete --no-defaults exegol | sudo tee /etc/bash_completion.d/exegol > /dev/null