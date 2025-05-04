#!/bin/bash
# super shrimple script to install virtualbox 7.1 :)
echo "This script will install Virtualbox 7.1 for UBUNTU 24.04 systems. See https://www.virtualbox.org/wiki/Linux_Downloads for details on installation! Feel free to DM me as well on Discord if any issues arise!"
echo "Your PC will need to restart once this script is finished!"
read -p "Please read the above before continuing, then hit Enter to continue!"

deb [arch=amd64 signed-by=/usr/share/keyrings/oracle-virtualbox-2016.gpg] https://download.virtualbox.org/virtualbox/debian jammy contrib
wget -O- https://www.virtualbox.org/download/oracle_vbox_2016.asc | sudo gpg --yes --output /usr/share/keyrings/oracle-virtualbox-2016.gpg --dearmor

sudo apt-get update
sudo apt-get install virtualbox-7.1
sudo usermod -a -G vboxusers $(whoami)
sudo shutdown -r
echo "Once your system is restarted, you will be able to totally use VirtbualBox!!"
