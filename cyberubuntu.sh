#!/bin/bash

clear

#color
colorRED="\033[0;31m"
colorGREEN="\033[0;32m"
colorORANGE='\e[0;33m'
noCOLOR="\033[0m"
backCOLORYELLOW="\033[1;43m"

is_root() {
    if [ "$EUID" -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

update_packages() {
    if command -v apt-get &> /dev/null; then
        sudo DEBIAN_FRONTEND=noninteractive apt-get update &> /dev/null && sudo DEBIAN_FRONTEND=noninteractive apt-get -yq full-upgrade &> /dev/null
    elif command -v dnf &> /dev/null; then
        sudo dnf makecache --quiet &> /dev/null && sudo dnf -y upgrade &> /dev/null
    elif command -v yum &> /dev/null; then
        sudo yum makecache fast --quiet &> /dev/null && sudo yum -y update &> /dev/null
    elif command -v zypper &> /dev/null; then
        sudo zypper --non-interactive refresh &> /dev/null && sudo zypper --non-interactive update &> /dev/null
    elif command -v pacman &> /dev/null; then
        sudo pacman -Syu --noconfirm &> /dev/null
    elif command -v microdnf &> /dev/null; then
        sudo microdnf update -y &> /dev/null
    else
        echo "Gestionnaire de paquets inconnu ou non trouvÃ©" >&2
        exit 1
    fi
}

install_command() {
    if command -v apt-get &> /dev/null; then
        sudo DEBIAN_FRONTEND=noninteractive apt-get install -yq $1 &> /dev/null
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y $1 &> /dev/null
    elif command -v yum &> /dev/null; then
        sudo yum install -y $1 &> /dev/null
    elif command -v zypper &> /dev/null; then
        sudo zypper --non-interactive install $1 &> /dev/null
    elif command -v pacman &> /dev/null; then
        sudo pacman -S $1 --noconfirm &> /dev/null
    elif command -v microdnf &> /dev/null; then
        sudo microdnf install $1 -y &> /dev/null
    else
        echo "Gestionnaire de paquets inconnu ou non trouvÃ©" >&2
        exit 2
    fi
}

is_package_installed() {
    if command -v dpkg &>/dev/null; then
        dpkg -l | grep -qw $1
    elif command -v rpm &>/dev/null; then
        rpm -q $1 &>/dev/null
    elif command -v apk &>/dev/null; then
        apk info $1 &>/dev/null
    else
        echo "SystÃ¨me non reconnu"
        return 2
    fi
}

require_command() {
    if ! command_exists $1; then
        install_command $1
    fi
}

docker_container_exists() {
    docker ps -a --format "{{.Names}}" | grep -wq "^$1$"
}

if is_root; then
    echo -e "${colorRED}############################################################${noCOLOR}"
    echo -e "${colorRED}##                                                        ##${noCOLOR}"
    echo -e "${colorRED}##          The script must not be run as root !          ##${noCOLOR}"
    echo -e "${colorRED}##                                                        ##${noCOLOR}"
    echo -e "${colorRED}############################################################${noCOLOR}"
    exit -1
fi

if ! command_exists sudo; then
    echo -e "${colorRED}############################################################${noCOLOR}"
    echo -e "${colorRED}##                                                        ##${noCOLOR}"
    echo -e "${colorRED}##                Missing dependency: sudo                ##${noCOLOR}"
    echo -e "${colorRED}##                                                        ##${noCOLOR}"
    echo -e "${colorRED}############################################################${noCOLOR}"
    exit -1
fi

if ! command_exists tee; then
    echo -e "${colorRED}############################################################${noCOLOR}"
    echo -e "${colorRED}##                                                        ##${noCOLOR}"
    echo -e "${colorRED}##                Missing dependency: tee                 ##${noCOLOR}"
    echo -e "${colorRED}##                                                        ##${noCOLOR}"
    echo -e "${colorRED}############################################################${noCOLOR}"
    exit -1
fi

echo -e -n "\r[ .. ] Login into sudo !"
sudo -v &> /dev/null;
if [ $? -ne 0 ]; then
    echo -e "\r[ ${colorRED}NOK${noCOLOR} ] ${colorRED}Failed to login into sudo !${noCOLOR}"
    exit -1
fi
clear
echo -e "\r[ ${colorGREEN}OK${noCOLOR} ] Update all packages from repo !"

echo -e -n "\r[ .. ] Update all packages from repo !"
update_packages;
if [ $? -ne 0 ]; then
    echo -e "\r[ ${colorRED}NOK${noCOLOR} ] ${colorRED}Failed to update all packages from repo !${noCOLOR}"
    exit 3
fi
echo -e "\r[ ${colorGREEN}OK${noCOLOR} ] Update all packages from repo !"

echo -e -n "\r[ .. ] Install command ${colorORANGE}sed${noCOLOR} !"
require_command sed
if ! command_exists sed; then
    echo -e "\r[ ${colorRED}NOK${noCOLOR} ] ${colorRED}Failed to install ${colorORANGE}sed${colorRED} !${noCOLOR}"
    exit 4
fi
echo -e "\r[ ${colorGREEN}OK${noCOLOR} ] Install command ${colorORANGE}sed${noCOLOR} !"

echo -e -n "\r[ .. ] Configure ${colorORANGE}sudo${noCOLOR} authorisations !"
sudo sed -E -i "s/^\s*(%sudo\s+[A-Za-z0-9]+\s*=\s*\(\s*[A-Za-z0-9]+\s*:\s*[A-Za-z0-9]+\s*\)\s+)([A-Za-z0-9]+\s*)$/\1NOPASSWD: \2/g"  /etc/sudoers
if [ $? -ne 0 ]; then
    echo -e "\r[ ${colorRED}NOK${noCOLOR} ] ${colorRED}Failed to edit sudower file !${noCOLOR}"
fi
echo -e "\r[ ${colorGREEN}OK${noCOLOR} ] Configure ${colorORANGE}sudo${noCOLOR} authorisations !"

cd ~/

echo -e -n "\r[ .. ] Install package ${colorORANGE}ca-certificates${noCOLOR} !"
install_command ca-certificates
if [ $? -ne 0 ]; then
    echo -e "\r[ ${colorRED}NOK${noCOLOR} ] ${colorRED}Failed to install ${colorORANGE}ca-certificates${colorRED} package !${noCOLOR}"
    exit 5
fi
echo -e "\r[ ${colorGREEN}OK${noCOLOR} ] Install package ${colorORANGE}ca-certificates${noCOLOR} !"

echo -e -n "\r[ .. ] Install command ${colorORANGE}curl${noCOLOR} !"
require_command curl
if ! command_exists curl; then
    echo -e "\r[ ${colorRED}NOK${noCOLOR} ] ${colorRED}Failed to install ${colorORANGE}curl${colorRED} !${noCOLOR}"
    exit 6
fi
echo -e "\r[ ${colorGREEN}OK${noCOLOR} ] Install command ${colorORANGE}curl${noCOLOR} !"

echo -e -n "\r[ .. ] Install package ${colorORANGE}uidmap${noCOLOR} !"
if ! command_exists newuidmap; then
    echo -e -n "\r[ .. ] Install uidmap !"
    install_command uidmap
    if [ $? -ne 0 ]; then
        echo -e "\r[ ${colorRED}NOK${noCOLOR} ] ${colorRED}Failed to install ${colorORANGE}uidmap${colorRED} package !${noCOLOR}"
        exit 7
    fi
fi
echo -e "\r[ ${colorGREEN}OK${noCOLOR} ] Install package ${colorORANGE}uidmap${noCOLOR} !"

echo -e -n "\r[ .. ] Install Docker !"
if ! command_exists docker; then
    curl -fsSL https://get.docker.com -o get-docker.sh &> /dev/null
    if [ $? -ne 0 ]; then
        echo -e "\r[ ${colorRED}NOK${noCOLOR} ] ${colorRED}Failed to download Docker install script !${noCOLOR}"
        exit 8
    fi
    sudo sh get-docker.sh &> /dev/null
    if [ $? -ne 0 ]; then
        echo -e "\r[ ${colorRED}NOK${noCOLOR} ] ${colorRED}Failed to install Docker !${noCOLOR}"
        exit 9
    fi
fi
echo -e "\r[ ${colorGREEN}OK${noCOLOR} ] Install Docker !"

echo -e -n "\r[ .. ] Configure Docker Authorisation !"
sudo usermod -aG docker $(id -u -n)
if [ $? -ne 0 ]; then
    echo -e "\r[ ${colorRED}NOK${noCOLOR} ] ${colorRED} Failed to assigne autorisation on group docker !${noCOLOR}"
    exit 10
fi
newgrp docker <<EONG
EONG
if [ $? -ne 0 ]; then
    echo -e "\r[ ${colorRED}NOK${noCOLOR} ] ${colorRED} Failed to assigne autorisation on group docker !${noCOLOR}"
    exit 11
fi
if [ -f /usr/bin/dockerd-rootless-setuptool.sh ]; then
    /usr/bin/dockerd-rootless-setuptool.sh install --force &> /dev/null
    if [ $? -ne 0 ]; then
        echo -e "\r[ ${colorRED}NOK${noCOLOR} ] ${colorRED} Failed to assigne autorisation on group docker !${noCOLOR}"
        exit 12
    fi
fi
echo -e "\r[ ${colorGREEN}OK${noCOLOR} ] Configure Docker Authorisation !"

# installations des logiciels cyber
echo -e -n "\r[ .. ] Install command ${colorORANGE}nmap${noCOLOR} !"
if ! command_exists nmap; then
    install_command nmap
    if [ $? -ne 0 ]; then
        echo -e "\r[ ${colorRED}NOK${noCOLOR} ] ${colorRED}Failed to install ${colorORANGE}nmap${colorRED} !${noCOLOR}"
        exit 13
    fi
fi
echo -e "\r[ ${colorGREEN}OK${noCOLOR} ] Install command ${colorORANGE}nmap${noCOLOR} !"

echo -e -n "\r[ .. ] Install command ${colorORANGE}wireshark${noCOLOR} !"
if ! command_exists wireshark; then
    install_command wireshark
    if [ $? -ne 0 ]; then
        echo -e "\r[ ${colorRED}NOK${noCOLOR} ] ${colorRED}Failed to install ${colorORANGE}wireshark${colorRED} !${noCOLOR}"
        exit 14
    fi
fi
echo -e "\r[ ${colorGREEN}OK${noCOLOR} ] Install command ${colorORANGE}nmap${noCOLOR} !"

echo -e -n "\r[ .. ] Install command ${colorORANGE}hydra${noCOLOR} !"
if ! command_exists hydra; then
    install_command hydra
    if [ $? -ne 0 ]; then
        echo -e "\r[ ${colorRED}NOK${noCOLOR} ] ${colorRED}Failed to install ${colorORANGE}hydra${colorRED} !${noCOLOR}"
        exit 15
    fi
fi
echo -e "\r[ ${colorGREEN}OK${noCOLOR} ] Install command ${colorORANGE}hydra${noCOLOR} !"

echo -e -n "\r[ .. ] Install command ${colorORANGE}sqlmap${noCOLOR} !"
if ! command_exists sqlmap; then
    install_command sqlmap
    if [ $? -ne 0 ]; then
        echo -e "\r[ ${colorRED}NOK${noCOLOR} ] ${colorRED}Failed to install ${colorORANGE}sqlmap${colorRED} !${noCOLOR}"
        exit 16
    fi
fi
echo -e "\r[ ${colorGREEN}OK${noCOLOR} ] Install command ${colorORANGE}sqlmap${noCOLOR} !"

echo -e -n "\r[ .. ] Install command ${colorORANGE}mysql${noCOLOR} !"
if ! command_exists mysql; then
    install_command mysql-server
    if [ $? -ne 0 ]; then
        install_command mariadb-server
        if [ $? -ne 0 ]; then
            echo -e "\r[ ${colorRED}NOK${noCOLOR} ] ${colorRED}Failed to install ${colorORANGE}mysql${colorRED} !${noCOLOR}"
            exit 17
        fi
    fi
fi
echo -e "\r[ ${colorGREEN}OK${noCOLOR} ] Install command ${colorORANGE}mysql${noCOLOR} !"

echo -e -n "\r[ .. ] Install command ${colorORANGE}snap${noCOLOR} !"
if ! command_exists snap; then
    install_command snapd
    if [ $? -ne 0 ]; then
        echo -e "\r[ ${colorRED}NOK${noCOLOR} ] ${colorRED}Faill to install ${colorORANGE}snap${noCOLOR} !"
        exit 18
    fi
fi
echo -e "\r[ ${colorGREEN}OK${noCOLOR} ] Install command ${colorORANGE}snap${noCOLOR} !"

echo -e -n "\r[ .. ] Install ${colorORANGE}sublime-text${noCOLOR} !"
if ! [ -d /snap/sublime-text/ ]; then
    sudo snap install sublime-text --classic &> /dev/null
    if [ $? -ne 0 ]; then
        echo -e "\r[ ${colorRED}NOK${noCOLOR} ] ${colorRED}Failed to install ${colorORANGE}sublime-text${noCOLOR} !"
        exit 19
    fi
fi
echo -e "\r[ ${colorGREEN}OK${noCOLOR} ] Install ${colorORANGE}sublime-text${noCOLOR} !"

# installation de logiciels Footprinting

echo -e -n "\r[ .. ] Install package ${colorORANGE}geoip-bin${noCOLOR} !"
if ! command_exists geoiplookup; then
    install_command geoip-bin
    if [ $? -ne 0 ]; then
        echo -e "\r[ ${colorRED}NOK${noCOLOR} ] ${colorRED}Failed to install ${colorORANGE}geoip-bin${noCOLOR} !"
        exit 20
    fi
fi
echo -e "\r[ ${colorGREEN}OK${noCOLOR} ] Install package ${colorORANGE}geoip-bin${noCOLOR} !"

echo -e -n "\r[ .. ] Install package ${colorORANGE}sublist3r${noCOLOR} !"
if ! command_exists sublist3r; then
    install_command sublist3r
    if [ $? -ne 0 ]; then
        echo -e "\r[ ${colorRED}NOK${noCOLOR} ] ${colorRED}Failed to install ${colorORANGE}sublist3r${noCOLOR} !"
        exit 21
    fi
fi
echo -e "\r[ ${colorGREEN}OK${noCOLOR} ] Install package ${colorORANGE}sublist3r${noCOLOR} !"

echo -e -n "\r[ .. ] Install package ${colorORANGE}nikto${noCOLOR} !"
if ! command_exists nikto; then
    install_command nikto
    if [ $? -ne 0 ]; then
        echo -e "\r[ ${colorRED}NOK${noCOLOR} ] ${colorRED}Failed to install ${colorORANGE}nikto${noCOLOR} !"
        exit 22
    fi
fi
echo -e "\r[ ${colorGREEN}OK${noCOLOR} ] Install package ${colorORANGE}nikto${noCOLOR} !"

# installation de logiciels spoofing

echo -e -n "\r[ .. ] Install package ${colorORANGE}dsniff${noCOLOR} !"
if ! command_exists dsniff; then
    install_command dsniff
    if [ $? -ne 0 ]; then
        echo -e "\r[ ${colorRED}NOK${noCOLOR} ] ${colorRED}Failed to install ${colorORANGE}dsniff${noCOLOR} !"
        exit 23
    fi
fi
echo -e "\r[ ${colorGREEN}OK${noCOLOR} ] Install package ${colorORANGE}dsniff${noCOLOR} !"

echo -e -n "\r[ .. ] Install package ${colorORANGE}hping3${noCOLOR} !"
if ! command_exists hping3; then
    install_command hping3
    if [ $? -ne 0 ]; then
        echo -e "\r[ ${colorRED}NOK${noCOLOR} ] ${colorRED}Failed to install ${colorORANGE}hping3${noCOLOR} !"
        exit 24
    fi
fi
echo -e "\r[ ${colorGREEN}OK${noCOLOR} ] Install package ${colorORANGE}hping3${noCOLOR} !"

echo -e -n "\r[ .. ] Install package ${colorORANGE}macchanger${noCOLOR} !"
if ! command_exists macchanger; then
    install_command macchanger
    if [ $? -ne 0 ]; then
        echo -e "\r[ ${colorRED}NOK${noCOLOR} ] ${colorRED}Failed to install ${colorORANGE}macchanger${noCOLOR} !"
        exit 25
    fi
fi
echo -e "\r[ ${colorGREEN}OK${noCOLOR} ] Install package ${colorORANGE}macchanger${noCOLOR} !"

# installation Spiderfoot

echo -e -n "\r[ .. ] Install package ${colorORANGE}git${noCOLOR} !"
if ! command_exists git; then
    install_command git
    if [ $? -ne 0 ]; then
        echo -e "\r[ ${colorRED}NOK${noCOLOR} ] ${colorRED}Failed to install ${colorORANGE}git${noCOLOR} !"
        exit 26
    fi
fi
echo -e "\r[ ${colorGREEN}OK${noCOLOR} ] Install package ${colorORANGE}git${noCOLOR} !"

echo -e -n "\r[ .. ] Install Spiderfoot !"
if ! [ -d spiderfoot ]; then
    git clone https://github.com/smicallef/spiderfoot.git &> /dev/null
    if [ $? -ne 0 ]; then
        echo -e "\r[ ${colorRED}NOK${noCOLOR} ] ${colorRED}Failed to clone Spiderfoot !${noCOLOR}"
        exit 27
    fi
fi
echo -e -n "\r[ ${colorGREEN}*${noCOLOR}. ] Install Spiderfoot !"
if ! docker_container_exists "spiderfoot" ; then
    cd spiderfoot
    docker compose up -d &> /dev/null
    if [ $? -ne 0 ]; then
        echo -e "\r[ ${colorRED}NOK${noCOLOR} ] ${colorRED}Failed to start Spiderfoot !${noCOLOR}"
        exit 28
    fi
    cd ..
fi
echo -e "\r[ ${colorGREEN}OK${noCOLOR} ] Install Spiderfoot !"

# installation de DVWA
echo -e -n "\r[ .. ] Install DVWA !"
if ! [ -d DVWA ]; then
    git clone https://github.com/digininja/DVWA.git &> /dev/null
    if [ $? -ne 0 ]; then
        echo -e "\r[ ${colorRED}NOK${noCOLOR} ] ${colorRED}Failed to clone DVWA !${noCOLOR}"
        exit 29
    fi
fi
echo -e -n "\r[ ${colorGREEN}*${noCOLOR}. ] Install DVWA !"
if ! docker_container_exists "dvwa-dvwa-1" ; then
    cd DVWA
    docker compose up -d &> /dev/null
    if [ $? -ne 0 ]; then
        echo -e "\r[ ${colorRED}NOK${noCOLOR} ] ${colorRED}Failed to start DVWA !${noCOLOR}"
        exit 30
    fi
    cd ..
fi
echo -e "\r[ ${colorGREEN}OK${noCOLOR} ] Install DVWA !"

# installation de Sysreptor

echo -e -n "\r[ .. ] Install command ${colorORANGE}openssl${noCOLOR} !"
if ! command_exists openssl; then
    install_command openssl
    if [ $? -ne 0 ]; then
        echo -e "\r[ ${colorRED}NOK${noCOLOR} ] ${colorRED}Failed to install ${colorORANGE}openssl${noCOLOR} !"
        exit 31
    fi
fi
echo -e "\r[ ${colorGREEN}OK${noCOLOR} ] Install command ${colorORANGE}openssl${noCOLOR} !"

echo -e -n "\r[ .. ] Install package ${colorORANGE}uuid-runtime${noCOLOR} !"
if ! command_exists uuidd; then
    install_command uuid-runtime
    if [ $? -ne 0 ]; then
        echo -e "\r[ ${colorRED}NOK${noCOLOR} ] ${colorRED}Failed to install ${colorORANGE}uuid-runtime${noCOLOR} !"
        exit 32
    fi
fi
echo -e "\r[ ${colorGREEN}OK${noCOLOR} ] Install package ${colorORANGE}uuid-runtime${noCOLOR} !"

echo -e -n "\r[ .. ] Install package ${colorORANGE}tar${noCOLOR} !"
if ! command_exists tar; then
    install_command tar
    if [ $? -ne 0 ]; then
        echo -e "\r[ ${colorRED}NOK${noCOLOR} ] ${colorRED}Failed to install ${colorORANGE}tar${noCOLOR} !"
        exit 33
    fi
fi
echo -e "\r[ ${colorGREEN}OK${noCOLOR} ] Install package ${colorORANGE}tar${noCOLOR} !"

echo -e -n "\r[ .. ] Install package ${colorORANGE}coreutils${noCOLOR} !"
if ! is_package_installed coreutils; then
    install_command coreutils
    if [ $? -ne 0 ]; then
        echo -e "\r[ ${colorRED}NOK${noCOLOR} ] ${colorRED}Failed to install ${colorORANGE}coreutils${noCOLOR} !"
        exit 34
    fi
fi
echo -e "\r[ ${colorGREEN}OK${noCOLOR} ] Install package ${colorORANGE}coreutils${noCOLOR} !"

echo -e -n "\r[ .. ] Install Sysreptor !"
if ! docker_container_exists "sysreptor-app" ; then
    curl -fsSL https://docs.sysreptor.com/install.sh -o get-sysreptor.sh &> /dev/null
    if [ $? -ne 0 ]; then
        echo -e "\r[ ${colorRED}NOK${noCOLOR} ] ${colorRED}Failed to download Sysreptor install script !${noCOLOR}"
        exit 35
    fi
    echo -e "\n\nif [ -z \"\$SYSREPTOR_CADDY_FQDN\" ]\nthen\n    echo \"URL: http://127.0.0.1:\$SYSREPTOR_CADDY_PORT\" > ~/sysreptor-credential.txt\nelse\n    echo \"URL: http://\$SYSREPTOR_CADDY_FQDN:\$SYSREPTOR_CADDY_PORT\" > ~/sysreptor-credential.txt\nfi\necho \"Username: reptor\" >> ~/sysreptor-credential.txt\necho \"Password: \$password\" >> ~/sysreptor-credential.txt" >> get-sysreptor.sh
    bash get-sysreptor.sh
    if [ $? -ne 0 ]; then
        echo -e "\r[ ${colorRED}NOK${noCOLOR} ] ${colorRED}Failed to install Sysreptor !${noCOLOR}"
        exit 36
    fi
fi
echo -e "\r[ ${colorGREEN}OK${noCOLOR} ] Install Sysreptor !"

# installation de SetoolKit

echo -e -n "\r[ .. ] Install SetoolKit!"
if ! [ -d social-engineer-toolkit ]; then
    git clone https://github.com/trustedsec/social-engineer-toolkit &> /dev/null
    if [ $? -ne 0 ]; then
        echo -e "\r[ ${colorRED}NOK${noCOLOR} ] ${colorRED}Failed to clone Setoolkit !${noCOLOR}"
        exit 47
    fi
fi
sudo apt install python3-pip -y
cd social-engineer-toolkit
pip3 install -r requirements.txt
sudo python3 setup.py

# installation de exegol

# install pipx if not already installed, from system package:
echo -e -n "\r[ .. ] Install command ${colorORANGE}pipx${noCOLOR} !"
if ! command_exists pipx; then
    install_command pipx
    if [ $? -ne 0 ]; then
        echo -e "\r[ ${colorRED}NOK${noCOLOR} ] ${colorRED}Failed to install ${colorORANGE}pipx${noCOLOR} !"
        exit 37
    fi
fi
echo -e "\r[ ${colorGREEN}OK${noCOLOR} ] Install command ${colorORANGE}pipx${noCOLOR} !"

# You can now install Exegol package from PyPI
echo -e -n "\r[ .. ] Install Exegol !"
pipx install exegol --force &> /dev/null
if [ $? -ne 0 ]; then
    echo -e "\r[ ${colorRED}NOK${noCOLOR} ] ${colorRED}Failed to install Exegol !${noCOLOR}"
    exit 38
fi
echo -e -n "\r[ ${colorGREEN}*${noCOLOR}. ] Install Exegol !"
pipx ensurepath &> /dev/null
if [ $? -ne 0 ]; then
    echo -e "\r[ ${colorRED}NOK${noCOLOR} ] ${colorRED}Failed to add pipx to PATH !${noCOLOR}"
    exit 39
fi
source ~/.bashrc
if [ $? -ne 0 ]; then
    echo -e "\r[ ${colorRED}NOK${noCOLOR} ] ${colorRED}Failed to reload bashrc !${noCOLOR}"
    exit 40
fi
echo "alias exegol='sudo -E $(which exegol)'" >> ~/.bash_aliases
if [ $? -ne 0 ]; then
    echo -e "\r[ ${colorRED}NOK${noCOLOR} ] ${colorRED}Failed to add alias to bash_aliases !${noCOLOR}"
    exit 41
fi
source ~/.bashrc
if [ $? -ne 0 ]; then
    echo -e "\r[ ${colorRED}NOK${noCOLOR} ] ${colorRED}Failed to reload bashrc !${noCOLOR}"
    exit 42
fi
echo -e "\r[ ${colorGREEN}OK${noCOLOR} ] Install Exegol !"

# Using the system package manager

echo -e -n "\r[ .. ] Install command ${colorORANGE}register-python-argcomplete${noCOLOR} !"
if ! command_exists register-python-argcomplete; then
    install_command python3-argcomplete
    if [ $? -ne 0 ]; then
        echo -e "\r[ ${colorRED}NOK${noCOLOR} ] ${colorRED}Failed to install ${colorORANGE}python3-argcomplete${noCOLOR} !"
        exit 43
    fi
fi
echo -e "\r[ ${colorGREEN}OK${noCOLOR} ] Install command ${colorORANGE}register-python-argcomplete${noCOLOR} !"

echo -e -n "\r[ .. ] Register Exegol completion !"
register-python-argcomplete --no-defaults exegol | sudo tee /etc/bash_completion.d/exegol > /dev/null
if [ $? -ne 0 ]; then
    echo -e "\r[ ${colorRED}NOK${noCOLOR} ] ${colorRED}Failed to register Exegol completion !${noCOLOR}"
    exit 44
fi
echo -e "\r[ ${colorGREEN}OK${noCOLOR} ] Register Exegol completion !"

# installation de Nessus
echo -e -n "\r[ .. ] Install Nessus !"
if ! docker_container_exists "nessus-managed" ; then
    docker pull tenable/nessus:latest
    if [ $? -ne 0 ]; then
        echo -e "\r[ ${colorRED}NOK${noCOLOR} ] ${colorRED}Failed to pull Nessus image !${noCOLOR}"
        exit 45
    fi
    echo -e -n "\r[ ${colorGREEN}*${noCOLOR}. ] Install Nessus !"
    docker run --name "nessus-managed" -d -p 127.0.0.1:8834:8834 -e USERNAME=admin -e PASSWORD=password -e MANAGER_HOST=127.0.0.1 -e MANAGER_PORT=443 tenable/nessus:latest 
    if [ $? -ne 0 ]; then
        echo -e "\r[ ${colorRED}NOK${noCOLOR} ] ${colorRED}Failed to start Nessus !${noCOLOR}"
        exit 46
    fi
fi
echo -e "\r[ ${colorGREEN}OK${noCOLOR} ] Install Nessus !"
