#!/bin/bash
# super shrimple script to install virtualbox 7.1 :)

echo "===== Getting Oracle Public Key for Signing... ====="
wget -O- https://www.virtualbox.org/download/oracle_vbox_2016.asc | sudo gpg --yes --output /usr/share/keyrings/oracle-virtualbox-2016.gpg --dearmor

echo ""
echo "===== Checking for Updates... ====="
sudo apt-get update

echo ""
echo "===== Installing VirtualBox v7.1... ====="
sudo apt-get install virtualbox-7.1

echo ""
echo "===== Adding to vboxusers group... ====="
sudo usermod -a -G vboxusers $(whoami)

echo ""
echo "===== Rebooting... ====="
sudo shutdown -r
echo "Once your system is restarted, you will be able to totally use VirtbualBox!!"
