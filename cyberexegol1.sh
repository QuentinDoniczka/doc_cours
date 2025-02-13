#!/bin/bash

# installation de Recon-ng
echo "installation de Recon-ng"
git clone https://github.com/lanmaster53/recon-ng.git
cd recon-ng
pip3 install -r REQUIREMENTS
cd ..

# Installation de TheHarvester
echo "installation de TheHarvester"
git clone https://github.com/laramies/theHarvester
cd theHarvester
sudo apt install python3-pip -y
python3 -m pip install -r requirements/dev.txt
Python3 -m pip install -r requirements.txt

# installation de Reconftw
echo "installation de Reconftw"
git clone https://github.com/six2dez/reconftw
cd reconftw/
./install.sh
cd ..
