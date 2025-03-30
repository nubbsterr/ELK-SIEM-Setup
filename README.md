# ELK-SIEM-Setup
A guide for building your own SIEM using the ELK stack, and how to simulate, analyze and triage attacks. Courtesy of the internet and other sources.

# Preface
<strong>Big</strong> thank you to all of the lovely sources on the internet. I am not one to shy away from reading documentation but this kind of project is virutally impossible for me given my limited knowledge of the ELK stack.

As stated above, there are many sources I consulted, all of which will be linked below for your own reading. Past that, the following will be a step-by-step guide of me <strong>creating my own SIEM</strong> using said sources as a guide. 

# SIEM Features
<strong>Basic features</strong> should include:
- Log ingestion (mainly network-related logs and OS log data for initial testing. Beats and/or Logstash can be used for ingest.)
- Log parsing/querying (KQL can easily query for us + Beats for basic parsing.)
- Dashboards (Kibana duh)
- Alerts (Achieved inside the actual SIEM UI)

You may notice that I did not include retention, and that is because I do not plan to retain data for this solution. This is made for a homelab setp; not a production environment where retention is necessary to trash malicious behaviour.

# The Setup Begins
This is our first step into our SIEM-building journey. 

First things first, we will get a VM set up using VirtualBox. Because I am such a nice kiddo, <strong>I have a bash script made to install VirtualBox 7.1 for Ubuntu linked on this repo :)</strong> Sources are linked below specifically for this setup.

Once VirtualBox is set up, we can install an ISO for our VM; preferably Linux. I am running an [Ubuntu Server VM](https://releases.ubuntu.com/bionic/). 

To set up the VM:
1. Open VirtualBox and Select `Machine` then `New`.
2. Give your VM a cool name and select the previously installed ISO image as your chosen OS.
3. Check the box to skip the unattented install. This is so we can tinker everything ourselves.
4. Adjust virtual hardware settings. I have my VM running 4GB of RAM, 2 CPU cores and ~50GB of SSD storage.
5. Start up your VM once everything is ready!

To set up the OS on our VM:
1. Select your language accordingly. ![Select a Language](https://github.com/nubbsterr/ELK-SIEM-Setup/blob/main/select-language.png)
2. If you get an "installer update" notice, you can skip it as you wish.
3. <strong>Record the IP shown next to DMCPv4, we will need this!</strong>
4. We don't need a proxy, so we can skip configuring one. We also don't need an alternative mirror for Ubuntu.
5. Continue setting up the storage config for the OS, there is no need to tinker with anything unless <strong>you</strong> want to :) ![Storage Conig](https://github.com/nubbsterr/ELK-SIEM-Setup/blob/main/storage-config.png)
6. Confirm your user credentials and SSH setup. We don't need any featured software on our VM, so continue with the installation. ![Inputting user credentials, you can change yours to your liking!](https://github.com/nubbsterr/ELK-SIEM-Setup/blob/main/profile-setup.png)
7. Wait for the OS install to complete :) ![](https://github.com/nubbsterr/ELK-SIEM-Setup/blob/main/waiting-for-install.png)

Congrats! You're one step closer to a lovely homelab setup. Let's continue to our next step of our journey; installing and Configuring Elasticsearch.

# Installing and Configuring Elasticsearch
Once you reboot your system, continue to logging in as your user. When you're in, your screen should look something like this:
![Voila](https://github.com/nubbsterr/ELK-SIEM-Setup/blob/main/login-complete.png)

The last thing we need to do before getting to real SIEM setup fun is to update our system with the following commands:
```
sudo apt update && sudo apt upgrade -y
sudo apt dist-upgrade -y
sudo apt install zip unzip -y
sudo apt install jq -y
```
If you're done for the day like me, you can shutdown your VM by going to `Machine` --> `ACPI Shutdown` and return later :) otherwise, run `sudo reboot` to continue.

From here on out, we will be using SSH on our host machine instead of using VirtualBox.
*Next steps are under construciton, stay tuned :)

# Sources
- [Massive installation and setup guide which I consulted throughout my journey](https://www.leveleffect.com/blog/how-to-set-up-your-own-home-lab-with-elk?utm_source=chatgpt.com)
- [Consult this for VirtualBox downloads. Go straight to the wget command if you're on Ubuntu/Debian-based repos like me, or use my script to install VirtualBox lol](https://www.virtualbox.org/wiki/Linux_Downloads)
- [Consulted for a bug with VirtualBox download; USB enumerate.](https://www.youtube.com/watch?v=7Bdm_-JNiSc&t=146s)

