echo "PLEASE READ: Run this scripts only after having checked to see if SSH is actually broken and/or systemctl shows SSH is not found!"
echo "Updating and cleaning things up!"
sudo apt update && sudo apt upgrade && sudo apt autoremove

echo ""
echo "Reinstalling OpenSSH Server..."
sudo apt-get remove --purge openssh-server
sudo apt-get update
sudo apt-get install openssh-server

echo ""
echo "Checking systemctl status..."
sudo systemctl status ssh

echo "If SSH is shown to be a dead service. You can run 'sudo systemctl start ssh' to begin running SSH."
